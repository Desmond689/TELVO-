// lib/screens/customer/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/models/professional_display.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/widgets/category_card.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/professional_card.dart';
import 'package:telvo/widgets/search_bar.dart';
import 'package:telvo/widgets/need_help_fast_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Category> categories = [
    Category('Plumber', Icons.plumbing, const Color(0xFF00C853)),
    Category('Electrician', Icons.electrical_services, const Color(0xFFFFA726)),
    Category('Cleaner', Icons.cleaning_services, const Color(0xFF42A5F5)),
    Category('Painter', Icons.format_paint, const Color(0xFFAB47BC)),
    Category('More', Icons.more_horiz, const Color(0xFF78909C)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().refreshProfessionals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            const CustomSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCategories(),
                    const SizedBox(height: 24),
                    _buildNeedHelpFast(),
                    const SizedBox(height: 24),
                    _buildTopProfessionals(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.jobPost);
        },
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(UserModel? user) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: user?.profilePhoto != null
              ? NetworkImage(user!.profilePhoto!)
              : null,
          child: user?.profilePhoto == null
              ? const Icon(Icons.person, size: 28)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              user?.fullName ?? 'Guest',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 28),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildCategories() => SizedBox(
    height: 100,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(
          category: categories[index],
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.search);
          },
        );
      },
    ),
  );

  Widget _buildNeedHelpFast() => const NeedHelpFastButton();

  Widget _buildTopProfessionals() {
    final userProvider = context.watch<UserProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Professionals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.search);
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<UserModel>>(
          stream: userProvider.getProfessionals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  title: 'Unable to load professionals',
                  subtitle: 'Please check your connection and refresh.',
                  imagePath: 'assets/images/no_connection.png',
                ),
              );
            }

            final topProfessionals = (snapshot.data ?? []).take(6).toList();

            if (topProfessionals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  title: 'No verified professionals yet',
                  subtitle: 'Check back later or search for services now.',
                  imagePath: 'assets/images/empty_state.png',
                ),
              );
            }

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: topProfessionals.length,
                itemBuilder: (context, index) {
                  final professional = topProfessionals[index];
                  return ProfessionalCard(
                    professional: Professional(
                      name: professional.fullName ?? 'Unknown',
                      title: professional.category ?? 'Professional',
                      rating: professional.rating ?? 0,
                      jobs: professional.jobsCompleted ?? 0,
                      verified: professional.isVerified,
                      photoUrl: professional.profilePhoto,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.professionalProfile,
                        arguments: professional,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (index) async {
      if (_selectedIndex == index && index == 0) {
        final userProvider = context.read<UserProvider>();
        final jobProvider = context.read<JobProvider>();
        await Future.wait([
          userProvider.refreshProfessionals(),
          jobProvider.refreshJobs(),
        ]);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Home refreshed')));
        }
        return;
      }

      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.pushNamed(context, AppRoutes.search);
          break;
        case 2:
          Navigator.pushNamed(context, AppRoutes.history);
          break;
        case 3:
          Navigator.pushNamed(context, AppRoutes.profile);
          break;
      }
    },
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF00C853),
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}

class Category {
  Category(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}
