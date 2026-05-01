class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profilePicture;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profile_image']?.toString(),
    );
  }

  UserModel copyWith({String? id, String? username, String? email, String? profilePicture}) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
