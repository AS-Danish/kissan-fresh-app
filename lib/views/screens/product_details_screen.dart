import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../model/product_card_model.dart';
import '../../controllers/product_details_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../widgets/floating_cart_snackbar.dart';
import '../widgets/product_card_widget.dart';
import '../../routes/app_routes.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductCardModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Initialize controller and product
    final controller = Get.put(
      ProductDetailsController(),
      tag: product.id ?? product.title,
    );
    controller.initializeProduct(product);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              Obx(
                () => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Get.find<WishlistController>().isInWishlist(product)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  onPressed: controller.toggleFavorite,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey.shade100,
                child: Obx(() {
                  final v = controller.selectedVariation.value;
                  if (v != null && v.image != null && v.image!.isNotEmpty) {
                    return _buildNetworkImage(context, v.image!);
                  }
                  return (product.images != null && product.images!.isNotEmpty)
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: product.images!.length,
                              onPageChanged: controller.onImageChanged,
                              itemBuilder: (context, index) {
                                return _buildNetworkImage(
                                  context,
                                  product.images![index],
                                );
                              },
                            ),
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  product.images!.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width:
                                        controller.currentImageIndex.value ==
                                            index
                                        ? 24
                                        : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          controller.currentImageIndex.value ==
                                              index
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).dividerColor
                                                .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildNetworkImage(context, product.image);
                }),
              ),
            ),
          ),

          // Product Details Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Product Title and Price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(() {
                      final p = controller.observableProduct.value ?? product;
                      final v = controller.selectedVariation.value;
                      final displayPrice = v?.price ?? p.price;
                      final displayMrp = v?.mrp ?? p.mrp;
                      final displayUnit = v != null ? '${v.unitValue} ${v.unit}' : p.unit;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (displayMrp != null && displayMrp > displayPrice)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    '₹${displayMrp.toStringAsFixed(0)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              Text(
                                '₹${displayPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                ' /$displayUnit',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Variations
                  Obx(() {
                    final p = controller.observableProduct.value ?? product;
                    final currentSelected = controller.selectedVariation.value;
                    
                    if (!p.hasVariations || p.variations == null || p.variations!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Available Options',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: p.variations!.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final v = p.variations![index];
                              final isSelected = currentSelected == v;
                              return GestureDetector(
                                onTap: () => controller.selectVariation(v),
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected ? [] : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${v.unitValue} ${v.unit}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${v.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (v.mrp != null && v.mrp! > v.price)
                                        Text(
                                          '₹${v.mrp!.toStringAsFixed(0)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade400,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Obx(() {
                      final p = controller.observableProduct.value ?? product;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Product',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.description,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Obx(() {
                            final p =
                                controller.observableProduct.value ?? product;
                            final v = controller.selectedVariation.value;
                            final stockCount = v != null ? v.stockCount : p.stockCount;
                            
                            return _buildDetailRow(
                              context: context,
                              icon: Icons.inventory_2_outlined,
                              label: 'Stock Status',
                              value: stockCount > 0
                                  ? (stockCount < 10
                                        ? 'Only ${stockCount} left!'
                                        : 'In Stock (${stockCount})')
                                  : 'Out of Stock',
                              valueColor: stockCount > 0
                                  ? const Color(0xFF14B8A6)
                                  : Colors.red,
                            );
                          }),

                          Obx(() {
                            final p = controller.observableProduct.value ?? product;
                            final v = controller.selectedVariation.value;
                            final displayQuantity = v != null ? v.unitValue : p.quantity;
                            final displayUnit = v != null ? v.unit : p.unit;

                            if (displayQuantity != null && displayQuantity.isNotEmpty) {
                              return Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey.shade200, height: 1),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    context: context,
                                    icon: Icons.scale_outlined,
                                    label: 'Quantity',
                                    value: '$displayQuantity ${displayUnit.replaceAll(displayQuantity, '')}'.trim(),
                                    valueColor: Colors.grey.shade700,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          }),

                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 12),
                          Obx(() {
                            final p =
                                controller.observableProduct.value ?? product;
                            return _buildDetailRow(
                              context: context,
                              icon: Icons.local_offer_outlined,
                              label: 'Category',
                              value: p.category ?? 'Fresh Vegetables',
                              valueColor: Colors.grey.shade700,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tags Section (Dynamic as Info Cards)
                  Obx(() {
                    final p = controller.observableProduct.value ?? product;
                    if (p.tags == null || p.tags!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Highlights',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150, // Increased height to prevent overflow
                            child: ListView.separated(
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              itemCount: p.tags!.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 140, // Fixed width for each card
                                  child: _buildInfoCard(
                                    context: context,
                                    icon: Icons.verified_outlined,
                                    title: 'Feature',
                                    subtitle: p.tags![index],
                                    color: const Color(0xFF14B8A6),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Similar Products Section
                  Obx(() {
                    if (controller.isLoadingSimilarProducts.value) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Similar Products',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                      );
                    }
                    
                    if (controller.similarProducts.isEmpty) {
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
                              Text(
                                'Similar Products',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.toNamed(AppRoutes.searchRoute);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'See More',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280, // Adjust based on ProductCardWidget's ideal height
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.similarProducts.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 160, // Fixed width for horizontal layout
                                child: ProductCardWidget(
                                  product: controller.similarProducts[index],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 120), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add to Cart Bar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FloatingCartSnackbar(bottomPadding: 16.0),
          _buildBottomBar(context, controller),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 13, // Slightly smaller font to fit better
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ProductDetailsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final p = controller.observableProduct.value ?? product;
          final v = controller.selectedVariation.value;
          final stockCount = v != null ? v.stockCount : p.stockCount;
          final inStock = v != null ? v.inStock : p.inStock;

          return Row(
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed:
                          (stockCount > 0 && controller.quantity.value > 1)
                          ? controller.decreaseQuantity
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${controller.quantity.value}',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.add,
                      onPressed:
                          (stockCount > 0 &&
                              controller.quantity.value < stockCount)
                          ? controller.increaseQuantity
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Add to Cart Button (Flexible to prevent overflow)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: inStock
                          ? [
                              Theme.of(context).primaryColor,
                              Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.5),
                            ]
                          : [
                              Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.5),
                              Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: inStock
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: inStock ? controller.addToCart : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              inStock
                                  ? Icons.shopping_cart_outlined
                                  : Icons.remove_shopping_cart_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                inStock ? 'Add to Cart' : 'Out of Stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(BuildContext context, String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2.5,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 80,
          ),
        );
      },
    );
  }
}

