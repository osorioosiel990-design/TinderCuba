import 'package:flutter/material.dart';
import '../models/match.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Match> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await Supabase.instance.client
          .from('matches')
          .select('''
            id,
            user1_id,
            user2_id
          ''')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

      setState(() => _matches = (response as List).map((json) => Match.fromJson(json)).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar matches: \$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No tienes matches todavía'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatches,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final otherUserId = (currentUserId == match.user1Id) ? match.user2Id : match.user1Id;
          // Note: To fetch other user's profile we would need a separate service call or denormalized data

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person),
            ),
            title: Text('Match #${match.id.substring(0, 8)}'),
            subtitle: const Text('Chat disponible aquí'),
            trailing: const Icon(Icons.chat),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: match.id,
              );
            },
          );
        },
      ),
    );
  }
}
