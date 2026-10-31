import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user profile
  static Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return Profile.fromJson(response);
  }

  // Create or update profile
  static Future<void> upsertProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  // Get available profiles to swipe (prioritizing boosted profiles)
  static Future<List<Profile>> getAvailableProfiles() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    // Get profiles the user has already swiped on
    final swipedProfiles = await _client
        .from('swipes')
        .select('swiped_id')
        .eq('swiper_id', currentUserId)
        .then((value) => (value as List).map((e) => e['swiped_id'] as String).toList());

    // Fetch profiles to swipe on, ordering by active boost first
    final response = await _client
        .from('profiles')
        .select()
        .neq('id', currentUserId)
        .not('id', 'in', swipedProfiles.isEmpty ? [''] : swipedProfiles)
        .order('boost_until', ascending: false)
        .order('last_seen', ascending: false)
        .limit(20);

    return (response as List).map((e) => Profile.fromJson(e)).toList();
  }

  // Record a swipe
  static Future<void> recordSwipe(String swipedId, String swipeType) async {
    final swiperId = _client.auth.currentUser?.id;
    if (swiperId == null) throw Exception('User not logged in');

    await _client.from('swipes').insert({
      'swiper_id': swiperId,
      'swiped_id': swipedId,
      'swipe_type': swipeType,
    });
  }

  // Get matches for current user
  static Future<List<Match>> getMatches() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _client
        .from('matches')
        .select()
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Match.fromJson(json)).toList();
  }

  // Get match details for a specific match
  static Future<Match?> getMatchDetails(String matchId) async {
    final response = await _client
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();
    
    return Match.fromJson(response);
  }

  // Send a message
  static Future<void> sendMessage(String matchId, String content) async {
    await _client.from('messages').insert({
      'match_id': matchId,
      'sender_id': _client.auth.currentUser?.id,
      'content': content,
    });
  }

  // Get messages for a match
  static Future<List<Message>> getMessages(String matchId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }
}
