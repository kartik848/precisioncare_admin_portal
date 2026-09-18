import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/promo_banner.dart';
import '../../../providers/catalog_provider.dart';
import '../../../widgets/app_image_view.dart';

class BannerCarousel extends StatefulWidget {
  final Function(String category) onBannerTap;

  const BannerCarousel({super.key, required this.onBannerTap});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  final List<List<Color>> _gradients = [
    [const Color(0xFF0E8388), const Color(0xFF2E4F4F)],
    [const Color(0xFF144272), const Color(0xFF205295)],
    [const Color(0xFF2C74B3), const Color(0xFF0A4D68)],
    [const Color(0xFF4A0E4E), const Color(0xFF810CA8)],
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final banners = catalog.banners.isNotEmpty
        ? catalog.banners
        : [
            const PromoBanner(
              id: 'd1',
              title: 'Home Sample Collection',
              subtitle: 'Certified Phlebotomist at your doorstep in 60 Mins',
              badge: 'FREE HOME VISIT',
              actionText: 'Book Blood Test',
            ),
          ];

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.0, // Exact 2:1 ratio (matches 1200x600 px banner perfectly)
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              final gradient = _gradients[index % _gradients.length];
              final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
              final hasOverlayText = !hasImage || banner.title.isNotEmpty;

              return GestureDetector(
                onTap: () => widget.onBannerTap(banner.categoryTarget),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: !hasImage
                        ? LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: hasImage
                        ? DecorationImage(
                            image: getAppImageProvider(banner.imageUrl)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: (hasImage ? Colors.black : gradient[0]).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Subtle dark gradient protection only when text overlay is shown on top of image
                      if (hasImage && hasOverlayText)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 1.0],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),

                      if (!hasImage)
                        Positioned(
                          right: -10,
                          bottom: -15,
                          child: Icon(
                            Icons.medical_services_rounded,
                            size: 100,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),

                      // Text overlay
                      if (hasOverlayText)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (banner.badge.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: hasImage ? AppColors.accent : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    banner.badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (banner.title.isNotEmpty)
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (banner.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      banner.subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              if (banner.actionText.isNotEmpty)
                                Row(
                                  children: [
                                    Text(
                                      banner.actionText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                  ],
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
