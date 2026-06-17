import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class UserProfile {
  final String name;
  final String role;
  final String location;
  final String bio;
  final String email;
  final String website;
  final String profilePic;
  final String status;

  UserProfile({
    required this.name,
    required this.role,
    required this.location,
    required this.bio,
    required this.email,
    required this.website,
    required this.profilePic,
    required this.status,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? location,
    String? bio,
    String? email,
    String? website,
    String? profilePic,
    String? status,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      website: website ?? this.website,
      profilePic: profilePic ?? this.profilePic,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'location': location,
    'bio': bio,
    'email': email,
    'website': website,
    'profilePic': profilePic,
    'status': status,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    location: json['location'] ?? '',
    bio: json['bio'] ?? '',
    email: json['email'] ?? '',
    website: json['website'] ?? '',
    profilePic: json['profilePic'] ?? '',
    status: json['status'] ?? '',
  );
}

class UserNotifier extends Notifier<UserProfile> {
  static const _storageKey = 'kaizen_user_profile';

  @override
  UserProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null) {
      try {
        return UserProfile.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        return _defaultProfile;
      }
    }
    return _defaultProfile;
  }

  UserProfile get _defaultProfile => UserProfile(
    name: 'Username...',
    role: '',
    location: '',
    bio: '',
    email: '',
    website: '',
    profilePic: '',
    status: '',
  );

  void _saveProfile() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  void updateProfile(UserProfile newProfile) {
    state = newProfile;
    _saveProfile();
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
    _saveProfile();
  }

  void updateRole(String role) {
    state = state.copyWith(role: role);
    _saveProfile();
  }

  void updateBio(String bio) {
    state = state.copyWith(bio: bio);
    _saveProfile();
  }

  void updateProfilePic(String url) {
    state = state.copyWith(profilePic: url);
    _saveProfile();
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
    _saveProfile();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserProfile>(() {
  return UserNotifier();
});
