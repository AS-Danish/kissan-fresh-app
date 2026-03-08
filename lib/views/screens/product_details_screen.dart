import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../model/product_card_model.dart';
import '../../controllers/product_details_controller.dart';
import '../../controllers/wishlist_controller.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductCardModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller and product
    final controller = Get.put(
      ProductDetailsController(),
      tag: product.id ?? product.title,
    );
    controller.initializeProduct(product);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF0d9488),
                  size: 20,
                ),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              Obx(() => IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Get.find<WishlistController>().isInWishlist(product)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: const Color(0xFF0d9488),
                    size: 20,
                  ),
                ),
                onPressed: controller.toggleFavorite,
              )),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey.shade100,
                child: (product.images != null && product.images!.isNotEmpty)
                    ? Stack(
                        children: [
                          PageView.builder(
                            itemCount: product.images!.length,
                            onPageChanged: controller.onImageChanged,
                            itemBuilder: (context, index) {
                              return _buildNetworkImage(product.images![index]);
                            },
                          ),
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Obx(() => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    product.images!.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: controller.currentImageIndex.value == index ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: controller.currentImageIndex.value == index
                                            ? const Color(0xFF0d9488)
                                            : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                )),
                          ),
                        ],
                      )
                    : _buildNetworkImage(product.image),
              ),
            ),
          ),

          // Product Details Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5FFFE),
                borderRadius: BorderRadius.only(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0d9488),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              ' /${product.unit}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Product',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock Status',
                            value: product.inStock ? 'In Stock' : 'Out of Stock',
                            valueColor: product.inStock ? const Color(0xFF10B981) : Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.local_offer_outlined,
                            label: 'Category',
                            value: product.category ?? 'Fresh Vegetables',
                            valueColor: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tags Section (Dynamic as Info Cards)
                  if (product.tags != null && product.tags!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Highlights',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 135,
                            child: ListView.separated(
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              itemCount: product.tags!.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 140, // Fixed width for each card
                                  child: _buildInfoCard(
                                    icon: Icons.verified_outlined,
                                    title: 'Feature',
                                    subtitle: product.tags![index],
                                    color: const Color(0xFF10B981),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 120), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add to Cart Bar
      bottomNavigationBar: _buildBottomBar(controller),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
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

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0d9488),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductDetailsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() => Row(
          children: [
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF14b8a6).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onPressed: (product.inStock && controller.quantity.value > 1)
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
                        color: const Color(0xFF0d9488),
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onPressed: product.inStock ? controller.increaseQuantity : null,
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
                    colors: product.inStock 
                        ? [const Color(0xFF0d9488), const Color(0xFF14b8a6)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: product.inStock ? [
                    BoxShadow(
                      color: const Color(0xFF0d9488).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: product.inStock ? controller.addToCart : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Add to Cart',
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
                          const SizedBox(width: 6),
                          if (product.inStock)
                            Flexible(
                              child: Text(
                                '₹${controller.totalPrice.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                'Out of Stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
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
        )),
      ),
    );
  }

  Widget _buildQuantityButton({
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
              ? const Color(0xFF0d9488)
              : const Color(0xFF0d9488).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
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
            color: const Color(0xFF0d9488),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
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