import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/models/professional_display.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/utils/app_colors.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/professional_card.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchText = '';

  final List<String> _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Mechanic',
    'Gardener',
    'Tutor',
    'Photographer',
    'Chef',
    'Babysitter',
  ];

  final List<String> _filters = [
    'Nearest',
    'Highest Rated',
    'Cheapest',
    'Fastest Response',
    'Verified Only',
    'Available Today',
  ];

  // Distance and pricing aren't tracked on the user profile yet (no geo
  // coordinates, no rate field), so those two filters can't actually do
  // anything real right now - better to say so than to silently no-op.
  static const Set<String> _unavailableFilters = {'Nearest', 'Cheapest'};

  String? _selectedFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _applyTextFilter(List<UserModel> professionals) {
    if (_searchText.trim().isEmpty) return professionals;
    final query = _searchText.trim().toLowerCase();
    return professionals.where((p) {
      final id = (p.id ?? '').toLowerCase();
      final name = (p.fullName ?? '').toLowerCase();
      final username = (p.username ?? '').toLowerCase();
      final category = (p.category ?? '').toLowerCase();
      final city = (p.city ?? '').toLowerCase();
      final neighborhood = (p.neighborhood ?? '').toLowerCase();
      return id.contains(query) ||
          name.contains(query) ||
          username.contains(query) ||
          category.contains(query) ||
          city.contains(query) ||
          neighborhood.contains(query);
    }).toList();
  }

  List<UserModel> _applySort(List<UserModel> professionals) {
    final result = List<UserModel>.from(professionals);
    switch (_selectedFilter) {
      case 'Highest Rated':
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'Fastest Response':
        result.sort(
          (a, b) =>
              (a.responseTime ?? 1 << 30).compareTo(b.responseTime ?? 1 << 30),
        );
        break;
      case 'Verified Only':
        result.retainWhere((p) => p.isVerified);
        break;
      case 'Available Today':
        final today = const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][DateTime.now().weekday - 1];
        result.retainWhere((p) {
          final slots = p.availabilitySchedule?[today];
          if (slots is Map) {
            return slots.values.any((available) => available == true);
          }
          return false;
        });
        break;
      default:
        break;
    }
    return result;
  }

  void _onFilterTap(String filter) {
    if (_unavailableFilters.contains(filter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$filter isn\'t available yet - it needs location/pricing '
            'data we don\'t collect from professionals yet.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final category = _selectedCategory == 'All' ? null : _selectedCategory;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: CustomTextField(
                          controller: _searchController,
                          hintText: 'Search professionals...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          onChanged: (value) =>
                              setState(() => _searchText = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final categoryOption = _categories[index];
                        final isSelected = _selectedCategory == categoryOption;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(categoryOption),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected
                                    ? categoryOption
                                    : 'All';
                              });
                            },
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isUnavailable = _unavailableFilters.contains(filter);
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => _onFilterTap(filter),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: isSelected ? AppColors.primary : null,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: isUnavailable
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                            : (isSelected ? Colors.white : AppColors.textSecondary),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                // key forces the StreamBuilder to resubscribe to a fresh
                // stream whenever the category filter changes.
                key: ValueKey(category),
                stream: userProvider.getProfessionals(category: category),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    );
                  }
                  if (snapshot.hasError) {
                    return const EmptyState(
                      title: 'Unable to load professionals',
                      subtitle: 'Please check your network and try again.',
                      imagePath: 'assets/images/no_connection.png',
                    );
                  }

                  final professionals = _applySort(
                    _applyTextFilter(snapshot.data ?? []),
                  );

                  if (professionals.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: professionals.length,
                    itemBuilder: (context, index) {
                      final professional = professionals[index];
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const EmptyState(
    title: 'No professionals found',
    subtitle: 'Try adjusting your search or filters',
    imagePath: 'assets/images/empty_state.png',
  );
}