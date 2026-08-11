import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/models/professional_display.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/utils/app_colors.dart';
import 'package:telvo/utils/lookup_data.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/job_card.dart';
import 'package:telvo/widgets/professional_card.dart';
import 'package:telvo/widgets/searchable_option_picker.dart';
import 'package:telvo/utils/helpers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedCity = 'All';
  String _selectedAvailabilityStatus = 'All';
  String _selectedJobStatus = 'All';
  String _searchText = '';
  double _minRating = 0;
  bool _verifiedOnly = false;
  bool _availableOnly = false;

  // Connectivity is tracked continuously here, independent of any single
  // Firestore query error. Previously this screen ran a fresh async
  // connectivity check reactively, *inside* the error branch, and trusted
  // it as the sole signal for whether to show "No Internet Connection".
  // That meant any Firestore error (a missing index, a permission error, a
  // malformed document causing a parse exception) could get mislabeled as
  // "offline" if that one-off check was even slightly stale or flaky - and
  // conversely, genuinely-offline users sometimes still saw *some* result
  // because a fresh query occasionally slipped through before the interface
  // was marked down. Maintaining connectivity state via a live listener and
  // checking it on init avoids that race.
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    Helpers.checkInternetConnection().then((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = await Helpers.checkInternetConnection();
      if (mounted) setState(() => _isOffline = !online);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _connectivitySub?.cancel();
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

  List<JobModel> _applyJobTextFilter(List<JobModel> jobs) {
    if (_searchText.trim().isEmpty) return jobs;
    final query = _searchText.trim().toLowerCase();
    return jobs.where((job) {
      final category = (job.category ?? '').toLowerCase();
      final description = (job.description ?? '').toLowerCase();
      final address = (job.address ?? '').toLowerCase();
      return category.contains(query) ||
          description.contains(query) ||
          address.contains(query);
    }).toList();
  }

  List<JobModel> _applyJobFilters(List<JobModel> jobs) {
    final minPrice = _minPriceController.text.trim().isNotEmpty
        ? double.tryParse(_minPriceController.text.trim())
        : null;
    final maxPrice = _maxPriceController.text.trim().isNotEmpty
        ? double.tryParse(_maxPriceController.text.trim())
        : null;

    return jobs.where((job) {
      if (_selectedCategory != 'All' &&
          (job.category ?? '').toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_selectedCity != 'All' &&
          !_jobAddressMatchesCity(job.address, _selectedCity)) {
        return false;
      }
      if (minPrice != null && (job.budget ?? 0) < minPrice) {
        return false;
      }
      if (maxPrice != null && (job.budget ?? double.infinity) > maxPrice) {
        return false;
      }
      if (_selectedJobStatus != 'All' &&
          (job.status ?? '').toLowerCase() != _selectedJobStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _jobAddressMatchesCity(String? address, String city) {
    if (address == null || address.trim().isEmpty) return false;
    return address.toLowerCase().contains(city.toLowerCase());
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedCity = 'All';
      _selectedAvailabilityStatus = 'All';
      _selectedJobStatus = 'All';
      _minRating = 0;
      _verifiedOnly = false;
      _availableOnly = false;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  bool _filtersActive(bool isProfessionalSearch) {
    return _selectedCategory != 'All' ||
        _minPriceController.text.trim().isNotEmpty ||
        _maxPriceController.text.trim().isNotEmpty ||
        _selectedCity != 'All' ||
        (isProfessionalSearch
            ? _selectedJobStatus != 'All'
            : _verifiedOnly || _availableOnly || _minRating > 0 || _selectedAvailabilityStatus != 'All');
  }

  Future<void> _selectCategory() async {
    final selected = await showSearchableOptionPicker(
      context: context,
      title: 'Select Category',
      options: ['All', ...LookupData.jobCategories],
      initialValue: _selectedCategory != 'All' ? _selectedCategory : null,
    );
    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  Future<void> _selectCity() async {
    final selected = await showSearchableOptionPicker(
      context: context,
      title: 'Select City',
      options: ['All', ...LookupData.supportedCities],
      initialValue: _selectedCity != 'All' ? _selectedCity : null,
    );
    if (selected != null) {
      setState(() {
        _selectedCity = selected;
      });
    }
  }

  Future<void> _selectStatus(bool isProfessionalSearch) async {
    final options = isProfessionalSearch
        ? const ['All', 'posted', 'open', 'quotes_received', 'notified']
        : const ['All', 'Online', 'Offline'];
    final title = isProfessionalSearch ? 'Select Job Status' : 'Select Availability';
    final currentValue = isProfessionalSearch ? _selectedJobStatus : _selectedAvailabilityStatus;

    final selected = await showSearchableOptionPicker(
      context: context,
      title: title,
      options: options,
      initialValue: currentValue != 'All' ? currentValue : null,
    );
    if (selected != null) {
      setState(() {
        if (isProfessionalSearch) {
          _selectedJobStatus = selected;
        } else {
          _selectedAvailabilityStatus = selected;
        }
      });
    }
  }

  void _openFilterSheet(bool isProfessionalSearch) {
    final statusOptions = isProfessionalSearch
        ? const ['All', 'posted', 'open', 'quotes_received', 'notified']
        : const ['All', 'Online', 'Offline'];
    final tempMinPriceController = TextEditingController(text: _minPriceController.text);
    final tempMaxPriceController = TextEditingController(text: _maxPriceController.text);
    String tempCategory = _selectedCategory;
    String tempCity = _selectedCity;
    String tempStatus = isProfessionalSearch ? _selectedJobStatus : _selectedAvailabilityStatus;
    double tempMinRating = _minRating;
    bool tempVerified = _verifiedOnly;
    bool tempAvailable = _availableOnly;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = 'All';
                              tempCity = 'All';
                              tempStatus = 'All';
                              tempMinRating = 0;
                              tempVerified = false;
                              tempAvailable = false;
                              tempMinPriceController.text = '';
                              tempMaxPriceController.text = '';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isProfessionalSearch) ...[
                          const Text('Job Status'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: tempStatus,
                            items: statusOptions
                                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                .toList(),
                            onChanged: (v) => setModalState(() => tempStatus = v ?? 'All'),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Verified Only'),
                              Switch(
                                value: tempVerified,
                                onChanged: (v) => setModalState(() => tempVerified = v),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Available Today'),
                              Switch(
                                value: tempAvailable,
                                onChanged: (v) => setModalState(() => tempAvailable = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Minimum rating'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Any'),
                                selected: tempMinRating == 0,
                                onSelected: (_) => setModalState(() => tempMinRating = 0),
                              ),
                              ChoiceChip(
                                label: const Text('3+'),
                                selected: tempMinRating == 3,
                                onSelected: (_) => setModalState(() => tempMinRating = 3),
                              ),
                              ChoiceChip(
                                label: const Text('4+'),
                                selected: tempMinRating == 4,
                                onSelected: (_) => setModalState(() => tempMinRating = 4),
                              ),
                              ChoiceChip(
                                label: const Text('4.5+'),
                                selected: tempMinRating == 4.5,
                                onSelected: (_) => setModalState(() => tempMinRating = 4.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text('Category'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: tempCategory,
                          items: ['All', ...LookupData.jobCategories]
                              .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                              .toList(),
                          onChanged: (v) => setModalState(() => tempCategory = v ?? 'All'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Location'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: tempCity,
                          items: ['All', ...LookupData.supportedCities]
                              .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                              .toList(),
                          onChanged: (v) => setModalState(() => tempCity = v ?? 'All'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Budget range (XAF)'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: tempMinPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Min',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: tempMaxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Max',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = tempCategory;
                                _selectedCity = tempCity;
                                if (isProfessionalSearch) {
                                  _selectedJobStatus = tempStatus;
                                } else {
                                  _selectedAvailabilityStatus = tempStatus;
                                }
                                _minRating = tempMinRating;
                                _verifiedOnly = tempVerified;
                                _availableOnly = tempAvailable;
                                _minPriceController.text = tempMinPriceController.text;
                                _maxPriceController.text = tempMaxPriceController.text;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final userProvider = context.read<UserProvider>();
    final isProfessionalSearch = authProvider.isProfessionalMode;
    final category = _selectedCategory == 'All' ? null : _selectedCategory;
    final city = _selectedCity == 'All' ? null : _selectedCity;
    final minPrice = _minPriceController.text.trim().isNotEmpty
        ? double.tryParse(_minPriceController.text.trim())
        : null;
    final maxPrice = _maxPriceController.text.trim().isNotEmpty
        ? double.tryParse(_maxPriceController.text.trim())
        : null;
    final availabilityStatus = (!isProfessionalSearch && _selectedAvailabilityStatus != 'All')
        ? _selectedAvailabilityStatus
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top row: back + compact search field + filter button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchText = value),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isProfessionalSearch ? 'Search jobs...' : 'Search professionals...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: 'Filters',
                      onPressed: () => _openFilterSheet(isProfessionalSearch),
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _filtersActive(isProfessionalSearch) ? AppColors.primary : null,
                      ),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category chips row (single-line horizontal scroll, compact)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: LookupData.jobCategories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final name = isAll ? 'All' : LookupData.jobCategories[index - 1];
                  final selected = _selectedCategory == name || (_selectedCategory == 'All' && name == 'All');
                  return ChoiceChip(
                    label: Text(name),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = name;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Active filter pills
            if (_filtersActive(isProfessionalSearch))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedCategory != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_selectedCategory),
                            onDeleted: () => setState(() => _selectedCategory = 'All'),
                          ),
                        ),
                      if (_selectedCity != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_selectedCity),
                            onDeleted: () => setState(() => _selectedCity = 'All'),
                          ),
                        ),
                      if (isProfessionalSearch && _selectedJobStatus != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_selectedJobStatus),
                            onDeleted: () => setState(() => _selectedJobStatus = 'All'),
                          ),
                        ),
                      if (!isProfessionalSearch && _selectedAvailabilityStatus != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_selectedAvailabilityStatus),
                            onDeleted: () => setState(() => _selectedAvailabilityStatus = 'All'),
                          ),
                        ),
                      if (!isProfessionalSearch && _verifiedOnly)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: const Text('Verified'),
                            onDeleted: () => setState(() => _verifiedOnly = false),
                          ),
                        ),
                      if (!isProfessionalSearch && _availableOnly)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: const Text('Available Today'),
                            onDeleted: () => setState(() => _availableOnly = false),
                          ),
                        ),
                      if (!isProfessionalSearch && _minRating > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('${_minRating.toString()}+ Stars'),
                            onDeleted: () => setState(() => _minRating = 0),
                          ),
                        ),
                      if (_minPriceController.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Min: ${_minPriceController.text.trim()}'),
                            onDeleted: () => setState(() => _minPriceController.clear()),
                          ),
                        ),
                      if (_maxPriceController.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Max: ${_maxPriceController.text.trim()}'),
                            onDeleted: () => setState(() => _maxPriceController.clear()),
                          ),
                        ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Expanded(
              child: isProfessionalSearch
                  ? _buildWorkerSearchResults(jobProvider)
                  : StreamBuilder<List<UserModel>>(
                      // key forces the StreamBuilder to resubscribe to a fresh
                      // stream whenever the category filter changes.
                      key: ValueKey([
                        category,
                        city,
                        _verifiedOnly,
                        _availableOnly,
                        _minRating,
                        minPrice,
                        maxPrice,
                        availabilityStatus,
                      ]),
                      stream: userProvider.getProfessionals(
                        category: category,
                        city: city,
                        minRating: _minRating > 0 ? _minRating : null,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        availabilityStatus: availabilityStatus,
                        verifiedOnly: _verifiedOnly,
                        onlineOnly: _availableOnly,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 3),
                          );
                        }
                        if (snapshot.hasError) {
                          final error = snapshot.error;

                          if (_isOffline) {
                            return EmptyState(
                              title: 'No Internet Connection',
                              subtitle: 'Connect to the internet to refresh available professionals.',
                              imagePath: 'assets/images/no_connection.png',
                              onAction: () async {
                                final online = await Helpers.checkInternetConnection();
                                if (mounted) setState(() => _isOffline = !online);
                              },
                              actionText: 'Retry',
                            );
                          }

                          if (error is FirebaseException &&
                              (error.code == 'failed-precondition' ||
                                  (error.message?.toLowerCase().contains('requires an index') ?? false))) {
                            return _buildSearchErrorState(
                              'Search is temporarily limited by backend indexing. Try different filters or refresh.',
                            );
                          }
                          if (error is FirebaseException && error.code == 'permission-denied') {
                            return _buildSearchErrorState(
                              "You don't have permission to view this. Try signing out and back in.",
                            );
                          }

                          final message = error is FirebaseException
                              ? (error.message ?? 'Unable to load search results. Please try again.')
                              : 'Something went wrong loading professionals. Please try again.';
                          return _buildSearchErrorState(message);
                        }

                        final professionals = _applyTextFilter(snapshot.data ?? []);

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
                                verified: professional.verificationStatus.toLowerCase() == 'verified' || professional.isVerified,
                                isOnline: professional.isOnline,
                                photoUrl: professional.profilePhoto,
                                price: professional.startingPrice,
                                description: professional.description,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.professionalProfile,
                                  arguments: professional,
                                );
                              },
                              onHire: () {
                                if (professional.id != null) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.hireWorker,
                                    arguments: professional.id,
                                  );
                                }
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

  Widget _buildFilterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSearchErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildWorkerSearchResults(JobProvider jobProvider) {
    final jobs = _applyJobTextFilter(jobProvider.jobs);
    final filteredJobs = _applyJobFilters(jobs);

    if (jobProvider.isLoading && filteredJobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    if (_isOffline) {
      return EmptyState(
        title: 'No Internet Connection',
        subtitle: 'Connect to the internet to refresh available jobs.',
        imagePath: 'assets/images/no_connection.png',
        onAction: () async {
          final online = await Helpers.checkInternetConnection();
          if (mounted) setState(() => _isOffline = !online);
        },
        actionText: 'Retry',
      );
    }

    if (jobProvider.error != null) {
      return _buildSearchErrorState(jobProvider.error!);
    }

    if (filteredJobs.isEmpty) {
      return _buildJobEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        return JobCard(
          job: job,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.jobDetails,
              arguments: job,
            );
          },
          showAction: true,
          actionText: 'Submit Quote',
          onAction: () => _showQuoteDialog(job),
        );
      },
    );
  }

  void _showQuoteDialog(JobModel job) {
    final priceController = TextEditingController();
    final estimatedTimeController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Send Quote', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${job.category ?? 'Service'} • XAF ${job.budget?.toStringAsFixed(0) ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(dialogContext).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (XAF)', hintText: 'e.g. 25000'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: estimatedTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimated Time (hours)', hintText: 'e.g. 3'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message', hintText: 'Tell the customer about your offer'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUserId = context.read<AuthProvider>().currentUser?.id;
              if (currentUserId == null) {
                Navigator.pop(dialogContext);
                return;
              }

              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final estimatedTime = int.tryParse(estimatedTimeController.text.trim()) ?? 0;
              final message = messageController.text.trim();

              if (price <= 0 || estimatedTime <= 0 || message.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all quote fields.')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                await context.read<JobProvider>().sendQuote(
                      QuoteModel(
                        professionalId: currentUserId,
                        jobId: job.id,
                        price: price,
                        estimatedTime: estimatedTime,
                        message: message,
                        status: 'pending',
                        createdAt: DateTime.now(),
                      ),
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote sent successfully.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send quote: $e')),
                );
              }
            },
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobEmptyState() => const EmptyState(
        title: 'No jobs found',
        subtitle: 'Try adjusting your search or filters',
        imagePath: 'assets/images/empty_state.png',
      );

  Widget _buildEmptyState() => const EmptyState(
        title: 'No professionals found',
        subtitle: 'Try adjusting your search or filters',
        imagePath: 'assets/images/empty_state.png',
      );
}