enum GroupType { friends, business, custom }

class Group {
  final String id;
  final String name;
  final GroupType type;

  const Group({required this.id, required this.name, required this.type});

  Group copyWith({String? id, String? name, GroupType? type}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}


