import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cardSwiperController = CardSwiperController();
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await SupabaseService.getAvailableProfiles();
      setState(() => _profiles = profiles);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfiles: \$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _swipeLeft(Profile profile) {
    _cardSwiperController.swipeLeft();
    SupabaseService.recordSwipe(profile.id, 'dislike').then((_) {
      _profiles.removeWhere((p) => p.id == profile.id);
      setState(() {});
    });
  }

  void _swipeRight(Profile profile) {
    _cardSwiperController.swipeRight();
    SupabaseService.recordSwipe(profile.id, 'like').then((_) {
      _profiles.removeWhere((p) => p.id == profile.id);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No hay más perfiles disponibles'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfiles,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/TinderLogo-2017.svg/1024px-TinderLogo-2017.svg.png',
          height: 30,
          errorBuilder: (context, error, stackTrace) => const Text('Tinder Cuba'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/vip'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/matches'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              // Navegar a perfil
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: _cardSwiperController,
              cards: _profiles,
              onSwipeLeft: (index) => _swipeLeft(_profiles[index]),
              onSwipeRight: (index) => _swipeRight(_profiles[index]),
              cardBuilder: (context, index, _) => ProfileCard(profile: _profiles[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circularButton(Icons.close, Colors.red, () => _cardSwiperController.swipeLeft()),
                _circularButton(Icons.star, Colors.blue, () {}),
                _circularButton(Icons.favorite, Colors.green, () => _cardSwiperController.swipeRight()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onTap,
      ),
    );
  }

  // Add this missing method for the CardSwiperController
  @override
  void dispose() {
    _cardSwiperController.dispose();
    super.dispose();
  }
}
}
