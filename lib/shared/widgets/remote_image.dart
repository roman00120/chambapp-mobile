import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    super.key,
  });
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.navy.withValues(alpha: .08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.home_repair_service_outlined,
        color: AppColors.navyLight,
        size: 34,
      ),
    );
    final cleanUrl = url?.trim();
    final hasValidUrl =
        cleanUrl != null &&
        cleanUrl.isNotEmpty &&
        (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://'));

    final image = hasValidUrl
        ? Image.network(
            cleanUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: image,
    );
  }
}
