import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Match {
  final String id;
  final String user1Id;
  final String user2Id;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
    };
  }
}
