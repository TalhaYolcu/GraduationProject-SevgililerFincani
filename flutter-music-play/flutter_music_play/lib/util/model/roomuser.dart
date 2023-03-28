
class RoomUser {
  final String name;
  final DateTime joinedAt;

  RoomUser({required this.name, required this.joinedAt});

  factory RoomUser.fromMap(Map<Object?, Object?> map) {
    return RoomUser(
      name: map['name'] as String,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
    );
  }

  Map<Object?, Object?> toMap() {
    return {
      'name': name,
      'joinedAt': joinedAt.toUtc().toString(),
    };
  }
}