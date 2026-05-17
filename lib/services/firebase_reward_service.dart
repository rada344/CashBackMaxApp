import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRewardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getRewardCards() async {
    final snapshot = await _db.collection('reward_cards').get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<void> saveTransaction({
    required String userId,
    required String storeName,
    required double amount,
    required String bestCard,
    required double rewardValue,
  }) async {
    await _db.collection('transactions').add({
      'userId': userId,
      'storeName': storeName,
      'amount': amount,
      'bestCard': bestCard,
      'rewardValue': rewardValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
