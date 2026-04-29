import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/best_seller_controller.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../model/bestseller_card_model.dart';

class BestsellersSection extends StatelessWidget {
  BestsellersSection({super.key});

  final BestsellersController controller = Get.find<BestsellersController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(
                () => Text(
                  Get.find<HomepageController>().currentTab.value == 'Grocery'
                      ? "Bestsellers"
                      : "Popular Dishes",
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  debugPrint('See all bestsellers');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "See all",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bestseller Cards - GridView (2x2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() {
            // Force rebuild on theme change
            Get.find<ThemeController>().isDarkMode.value;
            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: controller.bestsellers.length,
              itemBuilder: (context, index) {
                return _buildBestsellerCard(
                  context,
                  controller.bestsellers[index],
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBestsellerCard(BuildContext context, BestsellerCardModel item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Grid Section - 2x2 Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Left Column (2 images)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildImageContainer(context, item.image1),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: _buildImageContainer(context, item.image2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Right Column (2 images)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildImageContainer(context, item.image3),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: _buildMoreContainer(
                              context,
                              item.image4,
                              item.moreCount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Title Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 8,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(BuildContext context, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).dividerColor,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreContainer(
    BuildContext context,
    String imageUrl,
    String count,
  ) {
    return Stack(
      children: [
        // Background Image
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
        // Overlay with gradient
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.85),
                Theme.of(context).primaryColor.withOpacity(0.95),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'MORE',
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
