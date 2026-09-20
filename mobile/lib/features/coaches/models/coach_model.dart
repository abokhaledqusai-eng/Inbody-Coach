class CoachModel {
  final int id;
  final String name;
  final String? profileImageUrl;
  final int? age;
  final String? gender;
  final int? experienceDuration;
  final String? bio;
  final List<String>? certificates;

  CoachModel({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.age,
    this.gender,
    this.experienceDuration,
    this.bio,
    this.certificates,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<String>? certs;
    if (json['certificates'] != null) {
      if (json['certificates'] is List) {
        certs = List<String>.from(json['certificates']);
      } else if (json['certificates'] is String) {
        certs = [json['certificates']];
      }
    }

    return CoachModel(
      id: parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      profileImageUrl: json['profile_image_url'],
      age: parseInt(json['age']),
      gender: json['gender'],
      experienceDuration: parseInt(json['experience_duration']),
      bio: json['bio'],
      certificates: certs,
    );
  }
}
