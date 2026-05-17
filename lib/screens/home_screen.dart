import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/native_notification_service.dart';
import '../services/notification_log_service.dart';
import '../services/notification_preferences.dart';
import '../services/privacy_preferences.dart';
import '../services/recommendation_service.dart';
import '../services/smart_notification_service.dart';
import '../services/store_service.dart';
import '../utils/app_colors.dart';
import 'wallet_screen.dart';
import 'map_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'card_comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final auth = AuthService();
  final db = DatabaseService.instance;
  final recommender = RecommendationService();
  final locationService = LocationService();
  final storeService = StoreService();
  final smartNotificationService = SmartNotificationService();
  final notifPrefs = NotificationPreferences.instance;
  final notifLog = NotificationLog.instance;
  final privacyPrefs = PrivacyPreferences.instance;
  final connectivity = ConnectivityService.instance;
  final nativeNotify = NativeNotificationService.instance;
  bool _wasOnline = true;
  late final VoidCallback _connectivityListener;

  late UserModel user;
  late List<RewardCardModel> cards;
  SupportedStore? detectedStore;
  RecommendationResult? liveRecommendation;
  String locationStatus = 'Tap detect location to find nearby supported stores';
  bool detecting = false;

  @override
void initState() {
  super.initState();

  final firebaseUser = auth.currentUser;

  user = UserModel(
    id: firebaseUser?.uid ?? 'u1',
    name: firebaseUser?.email?.split('@').first ?? 'User',
    email: firebaseUser?.email ?? '',
  );

  cards = db.getCards(user.id);

  _wasOnline = connectivity.isOnline.value;
  _connectivityListener = () {
    final isOnlineNow = connectivity.isOnline.value;
    if (!_wasOnline && isOnlineNow) {
      _flushPendingOnReconnect();
    }
    _wasOnline = isOnlineNow;
  };
  connectivity.isOnline.addListener(_connectivityListener);

  loadUserName();
  syncRemoteCards();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    detectAndRecommend(showMessage: false);
  });
}
@override
void dispose() {
  connectivity.isOnline.removeListener(_connectivityListener);
  super.dispose();
}

Future<void> _flushPendingOnReconnect() async {
  final uid = auth.currentUser?.uid;
  if (uid == null) return;
  await Future.wait([
    db.mergeRemoteCards(uid),
    notifLog.syncFromCloud(uid),
    notifPrefs.flushToCloud(),
    privacyPrefs.flushToCloud(),
  ]);
  if (!mounted) return;
  setState(() => cards = db.getCards(uid));
}

Future<void> syncRemoteCards() async {
  final uid = auth.currentUser?.uid;
  if (uid == null) return;

  // If the last signed-in UID differs (or this is the first sign-in on this
  // device), wipe local caches before pulling from cloud — otherwise stale
  // entries from a previous account leak into this one.
  final prefs = await SharedPreferences.getInstance();
  const lastUidKey = 'auth.lastUid';
  final lastUid = prefs.getString(lastUidKey);
  if (lastUid != null && lastUid != uid) {
    await Future.wait([
      notifLog.clearLocal(),
      notifPrefs.clearLocal(),
      privacyPrefs.clearLocal(),
      db.clearLocal(),
    ]);
  }
  await prefs.setString(lastUidKey, uid);

  await Future.wait([
    db.mergeRemoteCards(uid),
    notifPrefs.syncFromCloud(uid),
    notifLog.syncFromCloud(uid),
    privacyPrefs.syncFromCloud(uid),
  ]);
  if (!mounted) return;
  setState(() => cards = db.getCards(uid));
}

Future<void> loadUserName() async {
  final data = await auth.getUserData();

  if (data != null && mounted) {
    setState(() {
      user = UserModel(
        id: data['uid'] ?? user.id,
        name: data['name'] ?? user.name,
        email: data['email'] ?? user.email,
      );
    });
  }
}

  Future<void> detectAndRecommend({bool showMessage = true}) async {
    if (!privacyPrefs.locationBasedRecommendations) {
      setState(() {
        detectedStore = null;
        liveRecommendation = null;
        locationStatus =
            'Location-based recommendations are off. Turn them on in Privacy & Security.';
      });
      return;
    }
    setState(() => detecting = true);
    try {
      final position = await locationService.getCurrentLocation();
      final store = storeService.detectNearestStore(position);

      if (store == null) {
        setState(() {
          detectedStore = null;
          liveRecommendation = null;
          locationStatus = 'No supported store detected nearby. Use manual store selection as fallback.';
        });
        return;
      }

      final recommendation = recommender.recommend(
        cards,
        store: store.name,
        category: store.category,
        amount: 100,
      );

      setState(() {
        detectedStore = store;
        liveRecommendation = recommendation;
        locationStatus = '${store.name} detected · ${store.category} category';
      });

      if (showMessage && notifPrefs.shouldShowStoreAlert() && smartNotificationService.shouldNotifyForStore(store.name) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bg3,
            content: Text('Best card at ${store.name}: ${recommendation.card.name}'),
            action: SnackBarAction(label: 'View', textColor: AppColors.accent2, onPressed: () => setState(() => index = 3)),
          ),
        );
        notifLog.add(
          type: NotificationType.storeAlert,
          title: 'Store detected · ${store.name}',
          message: 'Use ${recommendation.card.name} for ${recommendation.card.benefit}.',
        );
        nativeNotify.show(
          title: 'Best card at ${store.name}',
          body: 'Use ${recommendation.card.name} — ${recommendation.card.benefit}',
        );
      }
    } catch (e) {
      setState(() {
        locationStatus = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => detecting = false);
    }
  }

  void useManualStore(SupportedStore store) {
    final recommendation = recommender.recommend(cards, store: store.name, category: store.category, amount: 100);
    setState(() {
      detectedStore = store;
      liveRecommendation = recommendation;
      locationStatus = 'Manual fallback selected: ${store.name}';
      index = 0;
    });
    if (notifPrefs.shouldShowStoreAlert()) {
      notifLog.add(
        type: NotificationType.storeAlert,
        title: 'Store selected · ${store.name}',
        message: 'Use ${recommendation.card.name} for ${recommendation.card.benefit}.',
      );
      nativeNotify.show(
        title: 'Best card at ${store.name}',
        body: 'Use ${recommendation.card.name} — ${recommendation.card.benefit}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bg3,
            content: Text('Best card at ${store.name}: ${recommendation.card.name}'),
            action: SnackBarAction(
              label: 'View',
              textColor: AppColors.accent2,
              onPressed: () => setState(() => index = 3),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _Dashboard(
        user: user,
        cards: cards,
        recommender: recommender,
        detectedStore: detectedStore,
        recommendation: liveRecommendation,
        locationStatus: locationStatus,
        detecting: detecting,
        onDetectLocation: () => detectAndRecommend(),
        onMap: () => setState(() => index = 2),
        onAlerts: () => setState(() => index = 3),
      ),
      WalletScreen(cards: cards, userId: user.id, onChanged: () => setState(() {})),
      MapScreen(onManualStoreSelected: useManualStore),
      const NotificationScreen(),
      ProfileScreen(user: user, cardCount: cards.length, onUserChanged: () => setState(() {})),
    ];
    return Scaffold(
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.bg.withValues(alpha: .96), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .06)))),
        child: ValueListenableBuilder<List<NotificationEntry>>(
          valueListenable: notifLog.entries,
          builder: (_, list, __) {
            final unread = list.where((e) => !e.read).length;
            return NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                setState(() => index = i);
                if (i == 3 && unread > 0) {
                  notifLog.markAllRead();
                }
              },
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.accent.withValues(alpha: .16),
              destinations: [
                const NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
                const NavigationDestination(icon: Icon(Icons.credit_card_rounded), label: 'Wallet'),
                const NavigationDestination(icon: Icon(Icons.location_on_rounded), label: 'Map'),
                NavigationDestination(
                  icon: unread > 0
                      ? Badge(label: Text('$unread'), child: const Icon(Icons.notifications_rounded))
                      : const Icon(Icons.notifications_rounded),
                  label: 'Alerts',
                ),
                const NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.user,
    required this.cards,
    required this.recommender,
    required this.detectedStore,
    required this.recommendation,
    required this.locationStatus,
    required this.detecting,
    required this.onDetectLocation,
    required this.onMap,
    required this.onAlerts,
  });
  final UserModel user;
  final List<RewardCardModel> cards;
  final RecommendationService recommender;
  final SupportedStore? detectedStore;
  final RecommendationResult? recommendation;
  final String locationStatus;
  final bool detecting;
  final VoidCallback onDetectLocation;
  final VoidCallback onMap;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
  return const Center(
    child: Text(
      'No reward cards available. Please add a card in Wallet.',
      style: TextStyle(color: Colors.white),
    ),
  );
}
    final storeName = detectedStore?.name ?? 'Woolworths Canberra Centre';
    final result = recommendation ?? recommender.recommend(cards, store: storeName, category: detectedStore?.category ?? 'Groceries', amount: 100);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Good morning, ${user.firstName} 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text('Your smart wallet is ready', style: TextStyle(color: AppColors.text2)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient), child: Center(child: Text(user.initials))),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.green.withValues(alpha: .22))),
        child: Row(children: [
          const Icon(Icons.location_on, color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(locationStatus, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Detect location',
            onPressed: detecting ? null : onDetectLocation,
            icon: detecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, color: AppColors.green),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.accent.withValues(alpha: .30)),
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .10), blurRadius: 32, offset: const Offset(0, 18))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .18), borderRadius: BorderRadius.circular(99)), child: const Text('⚡ LIVE RECOMMENDATION', style: TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w900, fontSize: 11))),
          const SizedBox(height: 14),
          Text('You are at $storeName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Estimated usable value: \$${result.score.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.text2)),
          const SizedBox(height: 8),
          Text(
            'Points \$${result.pointsValue.toStringAsFixed(2)} + Cashback \$${result.cashbackValue.toStringAsFixed(2)} + Discount \$${result.discountValue.toStringAsFixed(2)} + Bonus \$${result.bonusValue.toStringAsFixed(2)} - Fees \$${result.fees.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.text3, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Text(result.card.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(result.card.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(result.card.benefit, style: const TextStyle(color: AppColors.green, fontSize: 12))])),
              const Icon(Icons.chevron_right, color: AppColors.text3),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardComparisonScreen(
                      cards: cards,
                      store: storeName,
                      category: detectedStore?.category ?? 'Groceries',
                      amount: 100,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent2,
                side: BorderSide(color: AppColors.accent.withValues(alpha: .35)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text(
                'Compare all cards',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      _SectionTitle(title: 'Nearby Stores', action: 'View map', onTap: onMap),
      _StoreRow(icon: '🛒', title: 'Woolworths Canberra Centre', subtitle: 'Groceries · geofence enabled', badge: detectedStore?.name.contains('Woolworths') == true ? 'Active' : 'Nearby', color: AppColors.green),
      _StoreRow(icon: '🏪', title: 'Coles Canberra Centre', subtitle: 'Groceries · Flybuys compatible', badge: detectedStore?.name.contains('Coles') == true ? 'Active' : 'Nearby', color: AppColors.accent2),
      _StoreRow(icon: '⛽', title: 'Caltex Braddon', subtitle: 'Fuel · discount card compatible', badge: detectedStore?.name.contains('Caltex') == true ? 'Active' : 'Nearby', color: AppColors.amber),
      const SizedBox(height: 18),
      _SectionTitle(title: 'Recent Activity', action: 'See all', onTap: onAlerts),
      _RecentActivity(onSeeAll: onAlerts),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onTap});
  final String title; final String action; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), GestureDetector(onTap: onTap, child: Text(action, style: const TextStyle(color: AppColors.accent2)))]));
}
class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.icon, required this.title, required this.subtitle, required this.badge, required this.color});
  final String icon,title,subtitle,badge; final Color color;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(18)), child: Row(children: [Container(width: 44,height: 44,decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(icon, style: const TextStyle(fontSize: 22)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(subtitle, style: const TextStyle(color: AppColors.text2, fontSize: 12))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)), child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)))]));
}
class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NotificationEntry>>(
      valueListenable: NotificationLog.instance.entries,
      builder: (_, entries, __) {
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.text3, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No activity yet — add a card or detect a nearby store.',
                    style: TextStyle(color: AppColors.text2, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }
        final preview = entries.take(3).toList();
        return Column(
          children: [
            for (final e in preview) _ActivityRow(entry: e),
          ],
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.type) {
      NotificationType.storeAlert => AppColors.accent,
      NotificationType.recommendation => AppColors.green,
      NotificationType.reward => AppColors.amber,
      NotificationType.security => AppColors.red,
      NotificationType.system => AppColors.accent2,
    };
    final icon = switch (entry.type) {
      NotificationType.storeAlert => Icons.location_on,
      NotificationType.recommendation => Icons.credit_card,
      NotificationType.reward => Icons.local_offer,
      NotificationType.security => Icons.security,
      NotificationType.system => Icons.notifications,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  entry.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text2, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _relative(entry.createdAt),
                  style: const TextStyle(color: AppColors.text3, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

