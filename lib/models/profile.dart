import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String username;
  final String? bio;
  final String? gender;
  final String? lookingFor;
  final DateTime? birthDate;
  final String? province;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime? boostUntil;

  Profile({
    required this.id,
    required this.username,
    this.bio,
    this.gender,
    this.lookingFor,
    this.birthDate,
    this.province,
    this.avatarUrl,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.boostUntil,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      bio: json['bio'],
      gender: json['gender'],
      lookingFor: json['looking_for'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      province: json['province'],
      avatarUrl: json['avatar_url'],
      isPremium: json['is_premium'] ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null ? DateTime.parse(json['premium_expires_at']) : null,
      boostUntil: json['boost_until'] != null ? DateTime.parse(json['boost_until']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'gender': gender,
      'looking_for': lookingFor,
      'birth_date': birthDate?.toIso8601String(),
      'province': province,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'boost_until': boostUntil?.toIso8601String(),
    };
  }
}
