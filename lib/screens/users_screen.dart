import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user['name'] ?? 'No name'),
                  subtitle: Text(user['email'] ?? 'No email'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
