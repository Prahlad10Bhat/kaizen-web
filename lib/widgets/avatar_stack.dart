import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarStack extends StatelessWidget {
  final List<String> imageUrls;
  final double size;

  const AvatarStack({
    super.key,
    required this.imageUrls,
    this.size = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: size + (imageUrls.length - 1) * (size * 0.7),
      height: size,
      child: Stack(
        children: List.generate(imageUrls.length, (index) {
          return Positioned(
            left: index * (size * 0.7),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  width: size - 3,
                  height: size - 3,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    width: size - 3,
                    height: size - 3,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    width: size - 3,
                    height: size - 3,
                    child: const Icon(Icons.person, size: 16, color: Colors.white54),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
