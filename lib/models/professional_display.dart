// lib/models/professional_display.dart
//
// A lightweight display-only model used for professional cards across the
// app (home screen, search, favorites). This is intentionally separate from
// UserModel: screens build one of these from a UserModel to show a compact
// summary card without passing the entire user object around.
class Professional {
  const Professional({
    required this.name,
    required this.title,
    required this.rating,
    required this.jobs,
    required this.verified,
    this.photoUrl,
    this.price,
    this.description,
  });

  final String name;
  final String title;
  final double rating;
  final int jobs;
  final bool verified;
  final String? photoUrl;
  final double? price;
  final String? description;
}
