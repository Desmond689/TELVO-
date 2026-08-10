import 'package:flutter/material.dart';

/// Drop-in safe replacement for the common (and crash-prone) pattern:
///
/// ```dart
/// CircleAvatar(
///   backgroundImage: user.profilePhoto != null
///       ? NetworkImage(user.profilePhoto!)
///       : null,
///   child: user.profilePhoto == null ? const Icon(Icons.person) : null,
/// )
/// ```
///
/// That pattern crashes or shows a red error box in three real situations:
/// 1. `profilePhoto` is an empty string `""` (not null) — passes the null
///    check, then `NetworkImage('')` throws "Invalid image data".
/// 2. The URL is set but the image fails to load (deleted from Cloudinary,
///    no network, corrupt bytes, 404) — nothing catches the error.
/// 3. The `child` check uses `== null` while the `backgroundImage` check
///    uses `!= null`, so an empty string produces a blank circle with
///    neither the photo nor the fallback icon.
///
/// [SafeAvatar] treats null AND empty/whitespace-only strings as "no photo",
/// and falls back to [fallback] (or a person icon) if the network image
/// ever fails to load — it never lets the error reach the framework's
/// default red error widget.
class SafeAvatar extends StatefulWidget {
  const SafeAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.fallback,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize,
    this.fallbackIconColor,
  });

  /// The photo URL to display. Null, empty, or whitespace-only is treated
  /// as "no photo" and shows the fallback instead.
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;

  /// Custom fallback widget shown when there's no photo or it fails to
  /// load. If omitted, a [fallbackIcon] is shown instead.
  final Widget? fallback;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final Color? fallbackIconColor;

  @override
  State<SafeAvatar> createState() => _SafeAvatarState();
}

class _SafeAvatarState extends State<SafeAvatar> {
  bool _loadFailed = false;

  String? get _cleanUrl {
    final url = widget.imageUrl?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  @override
  void didUpdateWidget(covariant SafeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      // New URL deserves a fresh chance to load.
      _loadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _cleanUrl;
    final showImage = url != null && !_loadFailed;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Colors.grey.shade200,
      backgroundImage: showImage ? NetworkImage(url) : null,
      onBackgroundImageError: showImage
          ? (_, __) {
              // Never setState synchronously from an image error callback —
              // it can fire mid-build/mid-paint. Defer to the next frame.
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loadFailed) {
                  setState(() => _loadFailed = true);
                }
              });
            }
          : null,
      child: !showImage
          ? (widget.fallback ??
              Icon(
                widget.fallbackIcon,
                size: widget.fallbackIconSize ?? widget.radius,
                color: widget.fallbackIconColor ?? Colors.grey,
              ))
          : null,
    );
  }
}
