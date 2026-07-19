import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class WatermarkedProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const WatermarkedProductImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: placeholder ??
              (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          errorWidget: errorWidget ??
              (context, url, error) => const Center(
                    child: Icon(Icons.broken_image),
                  ),
        ),
        const WatermarkOverlay(),
      ],
    );
  }
}

class WatermarkOverlay extends StatelessWidget {
  const WatermarkOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Opacity(
        opacity: 0.26,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.70,
            heightFactor: 0.70,
            child: Image(
              image: AssetImage('assets/watermark.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
