import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../model/product_card_model.dart';

class ProductCardWidget extends StatefulWidget {
  final ProductCardModel product;
  final bool showAddButton;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.showAddButton = true,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  
  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.product.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.02),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 13,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: ColorFiltered(
                          colorFilter: widget.product.inStock
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          child: _isNetworkImage(widget.product.image)
                              ? CachedNetworkImage(
                                  imageUrl: widget.product.image,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  memCacheHeight: 400,
                                  placeholder: (context, url) => _buildPlaceholder(),
                                  errorWidget: (context, url, error) => _buildErrorPlaceholder(),
                                )
                              : Image.asset(
                                  widget.product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                                ),
                        ),
                      ),
                    ),
                    
                    // Subtle Glassy Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.black.withOpacity(0.03),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Product Tags (Top Left)
                    if (widget.product.tags != null && widget.product.tags!.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Wrap(
                          spacing: 4,
                          children: widget.product.tags!.take(1).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),

                    // Sold Out Ribbon
                    if (!widget.product.inStock)
                       Positioned(
                        top: 15,
                        left: -25,
                        child: Transform.rotate(
                          angle: -0.785,
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: const BoxDecoration(color: Colors.red),
                            child: const Center(
                              child: Text(
                                "SOLD OUT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Details Section
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Content (Title & Description) - Wrapped in Expanded to prevent pushing others out
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.product.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.product.inStock ? colorScheme.onSurface : Colors.grey.shade600,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.product.description,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade500,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),

                      // Premium Price & Add Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price Badge (The "Value Tag") - Wrapped in Flexible
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.product.inStock 
                                      ? primaryColor.withOpacity(0.1) 
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: widget.product.inStock ? primaryColor : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      widget.product.price.toStringAsFixed(0),
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: widget.product.inStock ? primaryColor : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 1),
                                    Text(
                                      '/${widget.product.unit}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: widget.product.inStock 
                                            ? primaryColor.withOpacity(0.7) 
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // Modern Add Button
                          if (widget.showAddButton)
                            GestureDetector(
                              onTap: widget.product.stockCount > 0 ? widget.product.onAddToCart : null,

                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: widget.product.inStock ? primaryColor : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: widget.product.inStock ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ] : [],
                                ),
                                child: Icon(
                                  widget.product.stockCount > 0 ? Icons.add_rounded : Icons.block_rounded,
                                  color: widget.product.stockCount > 0 ? Colors.white : Colors.grey.shade500,
                                  size: 20,
                                ),

                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade300, size: 36),
      ),
    );
  }
}