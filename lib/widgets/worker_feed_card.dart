import 'package:flutter/material.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/utils/app_colors.dart';

/// Marketplace-style service card (Bollo-inspired):
/// left image, title, price, description, tags, provider, Book button.
class WorkerFeedCard extends StatelessWidget {
  final UserModel professional;
  final VoidCallback onPhotoTap;
  final VoidCallback onHireNow;

  const WorkerFeedCard({
    super.key,
    required this.professional,
    required this.onPhotoTap,
    required this.onHireNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = professional.fullName?.trim().isNotEmpty == true
        ? professional.fullName!
        : 'Professional';
    final category = professional.category?.trim() ?? 'Service';
    final bio = (professional.description ?? '').trim();
    final price = professional.startingPrice;
    final priceLabel = price != null
        ? 'CFA ${price.toStringAsFixed(0)}'
        : 'Ask quote';
    final tags = <String>[
      if (category.isNotEmpty) category,
      if (professional.city != null && professional.city!.isNotEmpty)
        professional.city!,
    ];

    final cardColor = isDark ? const Color(0xFF1C1F26) : theme.colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPhotoTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: professional.profilePhoto != null &&
                          professional.profilePhoto!.isNotEmpty
                      ? Image.network(
                          professional.profilePhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(theme),
                        )
                      : _placeholder(theme),
                ),
              ),
              const SizedBox(width: 12),
              // Right content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.62),
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Tags
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2F3A)
                                  : AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.primaryDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),
                    // Provider + Book
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundImage: professional.profilePhoto != null &&
                                  professional.profilePhoto!.isNotEmpty
                              ? NetworkImage(professional.profilePhoto!)
                              : null,
                          child: professional.profilePhoto == null
                              ? const Icon(Icons.person, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (professional.isVerified == true) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: onHireNow,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.white : AppColors.primary,
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            child: const Text('Book'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.handyman_outlined, size: 32),
    );
  }
}
