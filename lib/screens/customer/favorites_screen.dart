import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/models/professional_display.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/professional_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    if (authProvider.currentUser != null) {
      await userProvider.getFavorites(authProvider.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites'), elevation: 0),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProvider.favorites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userProvider.favorites.length,
              itemBuilder: (context, index) {
                final professional = userProvider.favorites[index];
                return ProfessionalCard(
                  professional: Professional(
                    name: professional.fullName ?? 'Unknown',
                    title: professional.category ?? 'Professional',
                    rating: professional.rating ?? 0,
                    jobs: professional.jobsCompleted ?? 0,
                    verified: professional.verificationStatus.toLowerCase() == 'verified' || professional.isVerified,
                    isOnline: professional.isOnline,
                    photoUrl: professional.profilePhoto,
                    price: professional.startingPrice,
                    description: professional.description,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/professional-profile',
                      arguments: professional,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() => EmptyState(
    title: 'No Favorites Yet',
    subtitle: 'Start saving professionals you trust',
    imagePath: 'assets/images/empty_state.png',
    actionText: 'Find Professionals',
    onAction: () {
      Navigator.pushNamed(context, AppRoutes.search);
    },
  );
}
