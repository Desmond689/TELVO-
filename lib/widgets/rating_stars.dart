import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double>? onRatingUpdate;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    final totalStars = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalStars, (index) {
        if (index < fullStars) {
          return _buildStar(Icons.star, true);
        } else if (index == fullStars && hasHalfStar) {
          return _buildStar(Icons.star_half, true);
        } else {
          return _buildStar(Icons.star_border, false);
        }
      }),
    );
  }

  Widget _buildStar(IconData icon, bool filled) {
    return GestureDetector(
      onTap: onRatingUpdate != null
          ? () {
              final index = _getStarIndex(icon);
              onRatingUpdate?.call(index + 1.0);
            }
          : null,
      child: Icon(
        icon,
        color: filled ? Colors.amber : Colors.grey.shade300,
        size: size,
      ),
    );
  }

  int _getStarIndex(IconData icon) {
    if (icon == Icons.star) return 0;
    if (icon == Icons.star_half) return 0;
    return 0;
  }
}
