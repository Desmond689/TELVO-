import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:telvo/models/user_model.dart';

class ProfessionalPage {
  ProfessionalPage({
    required this.professionals,
    this.lastDocument,
    required this.hasMore,
  });

  final List<UserModel> professionals;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _professionals = [];
  List<UserModel> _favorites = [];
  UserModel? _selectedProfessional;
  bool _isLoading = false;
  String? _error;

  List<UserModel> get professionals => _professionals;
  List<UserModel> get favorites => _favorites;
  UserModel? get selectedProfessional => _selectedProfessional;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Query<Map<String, dynamic>> _buildProfessionalsQuery({
    String? category,
    String? area,
    String? city,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
    bool? onlineOnly,
    bool? verifiedOnly,
    bool includeOrdering = true,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('userType', whereIn: ['professional', 'both']);

    if (area != null) {
      query = query.where('serviceAreas', arrayContains: area);
    }
    if (city != null) {
      query = query.where('city', isEqualTo: city);
    }
    if (verifiedOnly ?? false) {
      query = query.where('isVerified', isEqualTo: true);
    }
    if (onlineOnly ?? false) {
      query = query.where('isOnline', isEqualTo: true);
    }
    if (availabilityStatus != null && availabilityStatus.isNotEmpty) {
      query = query.where('availabilityStatus', isEqualTo: availabilityStatus);
    }

    // Firestore supports range/inequality filters on only one field per
    // query. When callers supply both a price range and a minRating, keep
    // price as the server-side range filter and enforce minRating
    // client-side after fetching results to avoid `Invalid query` errors.
    final hasPriceFilter = minPrice != null || maxPrice != null;
    if (minRating != null && !hasPriceFilter) {
      query = query.where('rating', isGreaterThanOrEqualTo: minRating);
    }

    if (minPrice != null) {
      query = query.where('startingPrice', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('startingPrice', isLessThanOrEqualTo: maxPrice);
    }

    if (includeOrdering) {
      // If we're filtering by price server-side, avoid ordering by rating
      // on the server as that would conflict with the price inequality.
      // Instead, request a stable ordering and perform the UX sorting
      // client-side after applying the rating filter.
      if (hasPriceFilter) {
        query = query.orderBy('createdAt', descending: true);
      } else {
        query = query.orderBy('rating', descending: true).orderBy('createdAt', descending: true);
      }
    }
    return query;
  }

  List<UserModel> _applyProfessionalsFilters(
    List<UserModel> users,
    String? category,
    String? currentUserId,
  ) {
    final normalizedCategory = category?.trim().toLowerCase();
    final filtered = users.where((user) {
      if (currentUserId != null && user.id == currentUserId) {
        return false;
      }
      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        final userCategory = (user.category ?? '').trim().toLowerCase();
        return userCategory == normalizedCategory;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final aRating = a.rating ?? 0.0;
      final bRating = b.rating ?? 0.0;
      if (aRating != bRating) return bRating.compareTo(aRating);

      final aCompleted = a.jobsCompleted ?? 0;
      final bCompleted = b.jobsCompleted ?? 0;
      if (aCompleted != bCompleted) return bCompleted.compareTo(aCompleted);

      final aVerified = a.isVerified ? 1 : 0;
      final bVerified = b.isVerified ? 1 : 0;
      if (aVerified != bVerified) return bVerified.compareTo(aVerified);

      final aLastActive = a.lastActive ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bLastActive = b.lastActive ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bLastActive.compareTo(aLastActive);
    });

    return filtered;
  }

  Stream<List<UserModel>> getProfessionals({
    String? category,
    String? area,
    String? city,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
    bool? onlineOnly,
    bool? verifiedOnly,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final hasPriceFilter = minPrice != null || maxPrice != null;
    final applyMinRatingClientSide = minRating != null && hasPriceFilter;

    // If both a price range and minRating are requested we avoid adding the
    // rating inequality to the server query to prevent Firestore's "one
    // inequality field" restriction. Enforce minRating client-side instead.
    final primaryQuery = _buildProfessionalsQuery(
      category: category,
      area: area,
      city: city,
      minRating: applyMinRatingClientSide ? null : minRating,
      minPrice: minPrice,
      maxPrice: maxPrice,
      availabilityStatus: availabilityStatus,
      onlineOnly: onlineOnly,
      verifiedOnly: verifiedOnly,
      includeOrdering: true,
    );
    final fallbackQuery = _buildProfessionalsQuery(
      category: category,
      area: area,
      city: city,
      minRating: applyMinRatingClientSide ? null : minRating,
      minPrice: minPrice,
      maxPrice: maxPrice,
      availabilityStatus: availabilityStatus,
      onlineOnly: onlineOnly,
      verifiedOnly: verifiedOnly,
      includeOrdering: false,
    );

    Stream<List<UserModel>> buildStream(Query<Map<String, dynamic>> query) {
      return query.snapshots().map((snapshot) {
        var users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()).copyWith(id: doc.id))
            .toList();

        // If minRating was skipped server-side due to a price range, filter here.
        if (applyMinRatingClientSide && minRating != null) {
          users = users.where((u) => (u.rating ?? 0.0) >= minRating).toList();
        }

        final filtered = _applyProfessionalsFilters(users, category, currentUserId);
        _professionals = filtered;
        return filtered;
      });
    }

    return buildStream(primaryQuery).onErrorResume((error, stackTrace) {
      if (error is FirebaseException &&
          (error.code == 'failed-precondition' ||
              (error.message?.toLowerCase().contains('requires an index') ?? false))) {
        return buildStream(fallbackQuery);
      }
      return Stream.error(error, stackTrace);
    });
  }

  Future<void> refreshProfessionals({
    String? category,
    String? area,
    String? city,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
    bool? onlineOnly,
    bool? verifiedOnly,
  }) async {
    try {
      _setLoading(true);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('userType', whereIn: ['professional', 'both']);

      final normalizedCategory = category?.trim().toLowerCase();
      if (area != null) {
        query = query.where('serviceAreas', arrayContains: area);
      }
      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }
      if (verifiedOnly ?? false) {
        query = query.where('isVerified', isEqualTo: true);
      }
      if (onlineOnly ?? false) {
        query = query.where('isOnline', isEqualTo: true);
      }
      if (availabilityStatus != null && availabilityStatus.isNotEmpty) {
        query = query.where('availabilityStatus', isEqualTo: availabilityStatus);
      }

      final hasPriceFilter = minPrice != null || maxPrice != null;
      final applyMinRatingClientSide = minRating != null && hasPriceFilter;

      if (minRating != null && !hasPriceFilter) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      if (minPrice != null) {
        query = query.where('startingPrice', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('startingPrice', isLessThanOrEqualTo: maxPrice);
      }

      // Use server-side advanced ordering only when not filtering by price.
      if (!hasPriceFilter) {
        query = query
            .orderBy('rating', descending: true)
            .orderBy('jobsCompleted', descending: true)
            .orderBy('isVerified', descending: true)
            .orderBy('lastActive', descending: true)
            .orderBy('createdAt');
      } else {
        // Stable ordering for price-filtered queries; perform UX sorting client-side.
        query = query.orderBy('createdAt', descending: true);
      }

      try {
        final snapshot = await query.get();
        var users = snapshot.docs
            .map((doc) {
              final user = UserModel.fromMap(doc.data());
              return user.copyWith(id: doc.id);
            })
            .where((user) {
              if (currentUserId != null && user.id == currentUserId) {
                return false;
              }
              if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
                final userCategory = (user.category ?? '').trim().toLowerCase();
                return userCategory == normalizedCategory;
              }
              return true;
            })
            .toList();

        // If rating was skipped on the server because a price range was
        // applied, filter it client-side now.
        if (applyMinRatingClientSide && minRating != null) {
          users = users.where((u) => (u.rating ?? 0.0) >= minRating).toList();
        }

        // Ensure consistent client-side sorting (rating, completions, verified, lastActive).
        users = _applyProfessionalsFilters(users, category, currentUserId);

        _professionals = users;
        _setLoading(false);
        notifyListeners();
      } on FirebaseException catch (e) {
        final msg = e.message ?? e.toString();
        if (msg.toLowerCase().contains('requires an index') || e.code == 'failed-precondition') {
          // Fall back to a simpler query ordering only by rating to avoid composite index requirement.
          try {
            Query<Map<String, dynamic>> fallback = _firestore
                .collection('users')
                .where('userType', whereIn: ['professional', 'both']);
            if (area != null) fallback = fallback.where('serviceAreas', arrayContains: area);
            if (city != null) fallback = fallback.where('city', isEqualTo: city);
            if (verifiedOnly ?? false) fallback = fallback.where('isVerified', isEqualTo: true);
            if (onlineOnly ?? false) fallback = fallback.where('isOnline', isEqualTo: true);
            if (availabilityStatus != null && availabilityStatus.isNotEmpty) fallback = fallback.where('availabilityStatus', isEqualTo: availabilityStatus);

            if (minRating != null && !hasPriceFilter) fallback = fallback.where('rating', isGreaterThanOrEqualTo: minRating);
            if (minPrice != null) fallback = fallback.where('startingPrice', isGreaterThanOrEqualTo: minPrice);
            if (maxPrice != null) fallback = fallback.where('startingPrice', isLessThanOrEqualTo: maxPrice);

            final snap2 = await fallback.orderBy('rating', descending: true).get();
            var users2 = snap2.docs
                .map((doc) => UserModel.fromMap(doc.data()).copyWith(id: doc.id))
                .where((user) {
                  if (currentUserId != null && user.id == currentUserId) {
                    return false;
                  }
                  if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
                    final userCategory = (user.category ?? '').trim().toLowerCase();
                    return userCategory == normalizedCategory;
                  }
                  return true;
                })
                .toList();

            // Apply minRating client-side if needed.
            if (applyMinRatingClientSide && minRating != null) {
              users2 = users2.where((u) => (u.rating ?? 0.0) >= minRating).toList();
            }

            users2 = _applyProfessionalsFilters(users2, category, currentUserId);

            _professionals = users2;
            _setError('Some advanced sorting requires a Firestore composite index. Showing a simplified result sorted by rating.');
            _setLoading(false);
            notifyListeners();
            return;
          } catch (e2) {
            _setError(e2.toString());
            _setLoading(false);
            return;
          }
        }
        _setError(e.toString());
        _setLoading(false);
      } catch (e) {
        _setError(e.toString());
        _setLoading(false);
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<ProfessionalPage> fetchProfessionalsPage({
    String? category,
    String? area,
    String? city,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
    bool? onlineOnly,
    bool? verifiedOnly,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('userType', whereIn: ['professional', 'both']);

    final normalizedCategory = category?.trim().toLowerCase();
    if (area != null) {
      query = query.where('serviceAreas', arrayContains: area);
    }
    if (city != null) {
      query = query.where('city', isEqualTo: city);
    }
    if (verifiedOnly ?? false) {
      query = query.where('isVerified', isEqualTo: true);
    }
    if (onlineOnly ?? false) {
      query = query.where('isOnline', isEqualTo: true);
    }
    if (availabilityStatus != null && availabilityStatus.isNotEmpty) {
      query = query.where('availabilityStatus', isEqualTo: availabilityStatus);
    }
    if (minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: minRating);
    }
    if (minPrice != null) {
      query = query.where('startingPrice', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('startingPrice', isLessThanOrEqualTo: maxPrice);
    }

    query = query
        .orderBy('rating', descending: true)
        .orderBy('jobsCompleted', descending: true)
        .orderBy('isVerified', descending: true)
        .orderBy('lastActive', descending: true)
        .orderBy('createdAt')
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snapshot = await query.get();
      final workers = snapshot.docs
          .map((doc) {
            final user = UserModel.fromMap(doc.data());
            return user.copyWith(id: doc.id);
          })
          .where((user) {
            if (currentUserId != null && user.id == currentUserId) {
              return false;
            }
            if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
              final userCategory = (user.category ?? '').trim().toLowerCase();
              return userCategory == normalizedCategory;
            }
            return true;
          })
          .toList();

      final lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final deduped = <String, UserModel>{};
      for (var professional in workers) {
        if (professional.id != null) {
          deduped[professional.id!] = professional;
        }
      }

      return ProfessionalPage(
        professionals: deduped.values.toList(),
        lastDocument: lastDocument,
        hasMore: snapshot.docs.length == limit,
      );
    } on FirebaseException catch (e) {
      // Firestore often requires a composite index for complex orderBy combinations.
      final msg = e.message ?? e.toString();
      if (msg.toLowerCase().contains('requires an index') || e.code == 'failed-precondition') {
        // Fallback: run a simpler query ordering only by rating to avoid index requirements.
        try {
          Query<Map<String, dynamic>> fallback = _firestore
              .collection('users')
              .where('userType', whereIn: ['professional', 'both']);
          if (area != null) fallback = fallback.where('serviceAreas', arrayContains: area);
          if (city != null) fallback = fallback.where('city', isEqualTo: city);
          if (verifiedOnly ?? false) fallback = fallback.where('isVerified', isEqualTo: true);
          if (onlineOnly ?? false) fallback = fallback.where('isOnline', isEqualTo: true);
          if (availabilityStatus != null && availabilityStatus.isNotEmpty) fallback = fallback.where('availabilityStatus', isEqualTo: availabilityStatus);
          if (minRating != null) fallback = fallback.where('rating', isGreaterThanOrEqualTo: minRating);
          if (minPrice != null) fallback = fallback.where('startingPrice', isGreaterThanOrEqualTo: minPrice);
          if (maxPrice != null) fallback = fallback.where('startingPrice', isLessThanOrEqualTo: maxPrice);

          fallback = fallback.orderBy('rating', descending: true).limit(limit);
          if (startAfter != null) fallback = fallback.startAfterDocument(startAfter);

          final snap2 = await fallback.get();
          final workers2 = snap2.docs
              .map((doc) => UserModel.fromMap(doc.data()).copyWith(id: doc.id))
              .where((user) {
                if (currentUserId != null && user.id == currentUserId) {
                  return false;
                }
                if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
                  final userCategory = (user.category ?? '').trim().toLowerCase();
                  return userCategory == normalizedCategory;
                }
                return true;
              })
              .toList();

          final lastDoc2 = snap2.docs.isNotEmpty ? snap2.docs.last : null;
          final deduped2 = <String, UserModel>{};
          for (var p in workers2) {
            if (p.id != null) deduped2[p.id!] = p;
          }

          // Surface a helpful error so the UI can show a link to create the index if desired.
          _setError('A faster professional query is available but requires a Firestore composite index. Showing a simplified result sorted by rating. To remove this message, create the composite index shown in the Firebase console error logs.');

          return ProfessionalPage(
            professionals: deduped2.values.toList(),
            lastDocument: lastDoc2,
            hasMore: snap2.docs.length == limit,
          );
        } catch (e2) {
          rethrow;
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getProfessionalDetails(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _selectedProfessional = UserModel.fromMap(doc.data()!).copyWith(id: doc.id);
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> addToFavorites(String userId, String professionalId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([professionalId]),
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> removeFromFavorites(String userId, String professionalId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([professionalId]),
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!).copyWith(id: doc.id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<List<UserModel>> getFavorites(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        _favorites = [];
        _setLoading(false);
        notifyListeners();
        return [];
      }

      final favoriteIds = List<String>.from(doc.data()?['favorites'] ?? []);
      if (favoriteIds.isEmpty) {
        _favorites = [];
        _setLoading(false);
        notifyListeners();
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      _favorites = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()).copyWith(id: doc.id))
          .toList();
      _setLoading(false);
      notifyListeners();
      return _favorites;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  Future<void> reportUser(String userId, String reason) async {
    try {
      final reporterId = FirebaseAuth.instance.currentUser?.uid;
      if (reporterId == null) {
        throw Exception('You must be signed in to report a user.');
      }
      await _firestore.collection('reports').add({
        // firestore.rules requires reportedBy == request.auth.uid on create;
        // without it every report write was silently rejected as
        // permission-denied.
        'reportedBy': reporterId,
        'userId': userId,
        'reason': reason,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> blockUser(String userId, String blockedId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedId]),
      });
    } catch (e) {
      _setError(e.toString());
      // Callers rely on this throwing to know the block actually failed —
      // swallowing it here meant the UI always showed "User blocked" even
      // when the Firestore write was rejected.
      rethrow;
    }
  }

  Future<void> unblockUser(String userId, String blockedId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedId]),
      });
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  bool isBlocked(String userId, List<String> blockedUsers) {
    return blockedUsers.contains(userId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
