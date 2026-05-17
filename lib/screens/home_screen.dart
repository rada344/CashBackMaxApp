import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/recommendation_service.dart';
import '../services/smart_notification_service.dart';
import '../services/store_service.dart';
import '../utils/app_colors.dart';
import 'wallet_screen.dart';
import 'map_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final auth = AuthService();
  final db = DatabaseService();
  final recommender = RecommendationService();
  final locationService = LocationService();
  final storeService = StoreService();
  final smartNotificationService = SmartNotificationService();

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

  if (cards.isEmpty) {
    cards = db.getDefaultCards();
  }

  loadUserName();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    detectAndRecommend(showMessage: false);
  });
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

      if (showMessage && smartNotificationService.shouldNotifyForStore(store.name) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.bg3,
            content: Text('Best card at ${store.name}: ${recommendation.card.name}'),
            action: SnackBarAction(label: 'View', textColor: AppColors.accent2, onPressed: () {}),
          ),
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
      WalletScreen(cards: cards, onChanged: () => setState(() {})),
      MapScreen(onManualStoreSelected: useManualStore),
      const NotificationScreen(),
      ProfileScreen(user: user, cardCount: cards.length, onUserChanged: () => setState(() {})),
    ];
    return Scaffold(
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.bg.withValues(alpha: .96), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .06)))),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.accent.withValues(alpha: .16),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.credit_card_rounded), label: 'Wallet'),
            NavigationDestination(icon: Icon(Icons.location_on_rounded), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good morning, ${user.firstName} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const Text('Your smart wallet is ready', style: TextStyle(color: AppColors.text2)),
        ]),
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
          Text('Points \$${result.pointsValue.toStringAsFixed(2)} + Cashback \$${result.cashbackValue.toStringAsFixed(2)} + Bonus \$${result.bonusValue.toStringAsFixed(2)} - Fees \$${result.fees.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.text3, fontSize: 12)),
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
          )
        ]),
      ),
      const SizedBox(height: 22),
      _SectionTitle(title: 'Nearby Stores', action: 'View map', onTap: onMap),
      _StoreRow(icon: '🛒', title: 'Woolworths Canberra Centre', subtitle: 'Groceries · geofence enabled', badge: detectedStore?.name.contains('Woolworths') == true ? 'Active' : 'Nearby', color: AppColors.green),
      _StoreRow(icon: '🏪', title: 'Coles Canberra Centre', subtitle: 'Groceries · Flybuys compatible', badge: detectedStore?.name.contains('Coles') == true ? 'Active' : 'Nearby', color: AppColors.accent2),
      _StoreRow(icon: '⛽', title: 'Caltex Braddon', subtitle: 'Fuel · discount card compatible', badge: detectedStore?.name.contains('Caltex') == true ? 'Active' : 'Nearby', color: AppColors.amber),
      const SizedBox(height: 18),
      _SectionTitle(title: 'Recent Activity', action: 'See all', onTap: onAlerts),
      const _ActivityCard(),
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
class _ActivityCard extends StatelessWidget { const _ActivityCard(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(18)), child: const Row(children: [Text('🏪', style: TextStyle(fontSize: 28)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Coles — Card switched', style: TextStyle(fontWeight: FontWeight.w800)), Text('Flybuys Mastercard used · 3.5x pts', style: TextStyle(color: AppColors.text2, fontSize: 12)), Text('Yesterday 2:14 PM', style: TextStyle(color: AppColors.text3, fontSize: 11))]))])); }

