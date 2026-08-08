import 'package:flutter/material.dart';
import 'package:telvo/widgets/rating_stars.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _filterRating = 'All';
  String _sortBy = 'newest';

  final List<String> _ratingOptions = [
    'All',
    '5 ⭐',
    '4 ⭐',
    '3 ⭐',
    '2 ⭐',
    '1 ⭐',
  ];

  // Sample reviews - In production, fetch from Firebase
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': '1',
      'reviewerName': 'John Doe',
      'professionalName': 'Emmanuel',
      'rating': 5.0,
      'comment': 'Excellent work! Very professional and timely.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'job': 'Plumbing Repair',
      'photos': [],
    },
    {
      'id': '2',
      'reviewerName': 'Jane Smith',
      'professionalName': 'Franck',
      'rating': 4.5,
      'comment': 'Good service, would hire again.',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'job': 'Electrical Installation',
      'photos': [],
    },
    {
      'id': '3',
      'reviewerName': 'Mike Johnson',
      'professionalName': 'Junior',
      'rating': 5.0,
      'comment': 'Amazing attention to detail. Highly recommended!',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'job': 'Painting Service',
      'photos': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _filteredReviews(_reviews);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: filteredReviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(filteredReviews[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search reviews...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // Search logic
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterRating,
            items: _ratingOptions.map((rating) {
              return DropdownMenuItem(value: rating, child: Text(rating));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterRating = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'rating', child: Text('Highest Rating')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredReviews(
    List<Map<String, dynamic>> reviews,
  ) {
    var filtered = reviews;

    if (_filterRating != 'All') {
      final rating = double.parse(_filterRating.split(' ')[0]);
      filtered = filtered
          .where((r) => r['rating'] >= rating && r['rating'] < rating + 1)
          .toList();
    }

    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case 'oldest':
        filtered.sort((a, b) => a['date'].compareTo(b['date']));
        break;
      case 'rating':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No reviews found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    (review['reviewerName'] as String)
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['reviewerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Reviewed ${review['professionalName']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                RatingStars(rating: review['rating'], size: 16),
                const SizedBox(width: 4),
                Text(
                  review['rating'].toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review['comment'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review['job'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(review['date']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _deleteReview(review),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  void _deleteReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
