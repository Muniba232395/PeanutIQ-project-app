/// The signed-in user, as returned by /users/me and /auth/verify-otp.
class AppUser {
  const AppUser({
    required this.id,
    required this.identifier,
    required this.role,
    required this.languagePreference,
    required this.timezone,
    this.name,
    this.farmLocation,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: '${json['id']}',
        identifier: (json['identifier'] ?? json['email'] ?? '') as String,
        name: json['name'] as String?,
        role: '${json['role'] ?? 'farmer'}'.toLowerCase(),
        farmLocation: json['farm_location'] as String?,
        languagePreference: '${json['language_preference'] ?? 'english'}'.toLowerCase(),
        timezone: (json['timezone'] ?? 'UTC') as String,
      );

  final String id;
  final String identifier;
  final String? name;

  /// 'farmer' | 'admin' | 'researcher'
  final String role;
  final String? farmLocation;

  /// Server value: 'english' | 'urdu'
  final String languagePreference;
  final String timezone;

  bool get isFarmer => role == 'farmer';

  bool get hasFarmLocation => (farmLocation ?? '').trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'name': name,
        'role': role,
        'farm_location': farmLocation,
        'language_preference': languagePreference,
        'timezone': timezone,
      };
}
