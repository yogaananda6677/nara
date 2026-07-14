class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.preferredLanguage,
    required this.timezone,
    required this.assistantName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String preferredLanguage;
  final String timezone;
  final String assistantName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? name,
    String? preferredLanguage,
    String? timezone,
    String? assistantName,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      assistantName: assistantName ?? this.assistantName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
