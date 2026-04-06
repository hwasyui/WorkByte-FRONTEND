class TeamRole {
  final String id;
  final String roleName;
  final String budget;
  final String description;

  TeamRole({
    required this.id,
    required this.roleName,
    required this.budget,
    this.description = '',
  });

  TeamRole copyWith({
    String? id,
    String? roleName,
    String? budget,
    String? description,
  }) {
    return TeamRole(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      budget: budget ?? this.budget,
      description: description ?? this.description,
    );
  }
}
