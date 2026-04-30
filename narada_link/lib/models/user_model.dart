class UserModel {
  final String id;
  final String username;

  UserModel({required this.id, required this.username});

  factory UserModel.fromJson(Map json) {
    return UserModel(
      id: json['_id'],
      username: json['username'] ?? '',
    );
  }
}