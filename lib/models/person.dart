class Person {
  final String id;
  final String name;
  final String? avatarUrl;
  final Set<String> groupIds;
  final double distanceMeters; // Distance from user
  final double angleRadians; // Position on radar
  final bool isOnline;

  const Person({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.groupIds,
    required this.distanceMeters,
    required this.angleRadians,
    this.isOnline = true,
  });

  Person copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    Set<String>? groupIds,
    double? distanceMeters,
    double? angleRadians,
    bool? isOnline,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      groupIds: groupIds ?? this.groupIds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      angleRadians: angleRadians ?? this.angleRadians,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}


