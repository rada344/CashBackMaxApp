class UserModel {
  UserModel({required this.id, required this.name, required this.email});
  final String id;
  String name;
  String email;

  String get firstName => name.trim().split(' ').first;
  String get initials => name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
}

