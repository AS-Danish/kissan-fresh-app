import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../model/section_model.dart';
import '../../model/product_card_model.dart';
import '../../routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DynamicSectionsWidget extends StatelessWidget {
  DynamicSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HomepageController controller = Get.find<HomepageController>();

    return Obx(() {
      // Force rebuild on theme change
      Get.find<ThemeController>().isDarkMode.value;
      
      // Filter sections based on current tab
      String activeTab = controller.currentTab.value == 'Grocery' ? 'kissan-fresh' : 'home-food';
      final activeSections = controller.sections.where((s) => s.type == activeTab).toList();

      if (controller.isLoadingSections.value && activeSections.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (activeSections.isEmpty) {
        debugPrint("No active sections for tab: $activeTab");
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Try Our Best",
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Freshly picked collections for you",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: activeSections.length,
              itemBuilder: (context, index) {
                final section = activeSections[index];
                final products = controller.sectionProducts[section.id] ?? [];
                return _buildSectionCard(context, section, products);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionCard(BuildContext context, SectionModel section, List<ProductCardModel> products) {
    // We need 4 images. If products length < 4, we use empty placeholders.
    String img1 = products.isNotEmpty ? products[0].image : '';
    String img2 = products.length > 1 ? products[1].image : '';
    String img3 = products.length > 2 ? products[2].image : '';
    String img4 = products.length > 3 ? products[3].image : '';
    
    // Show "View All" only if we have 5 products (meaning more exist in DB)
    int fetchedCount = products.length;
    String moreCount = fetchedCount > 4 ? 'VIEW' : ''; 
    bool showMoreOverlay = fetchedCount > 4;
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.sectionProductsRoute, arguments: section);
      },
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
                            child: _buildImageContainer(context, img1),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: _buildImageContainer(context, img2),
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
                            child: _buildImageContainer(context, img3),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: _buildMoreContainer(
                              context,
                              img4,
                              moreCount,
                              showOverlay: showMoreOverlay,
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
                      section.name,
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
    if (imageUrl.isEmpty) {
       return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
       );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).primaryColor,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).dividerColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreContainer(
    BuildContext context,
    String imageUrl,
    String count, {
    bool showOverlay = true,
  }) {
    if (imageUrl.isEmpty) {
       return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
       );
    }
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
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        // Overlay with gradient
        if (showOverlay)
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
                    'ALL',
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
