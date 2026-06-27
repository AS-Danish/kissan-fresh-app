import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../model/product_card_model.dart';
import '../../controllers/theme_controller.dart';

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

class _ProductCardWidgetState extends State<ProductCardWidget> {
  bool _isPressed = false;

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildImage() {
    return _isNetworkImage(widget.product.image)
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
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(),
          );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;
    final isChristmas = Get.find<ThemeController>().isChristmas.value;
    final isEid = Get.find<ThemeController>().isEid.value;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.product.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: (isChristmas || isEid) ? 8.0 : 0.0,
                right: (isChristmas || isEid) ? 8.0 : 0.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Expanded(
                      flex: 11,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: widget.product.inStock
                                  ? _buildImage()
                                  : ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.grey,
                                        BlendMode.saturation,
                                      ),
                                      child: _buildImage(),
                                    ),
                            ),
                          ),

                          // Subtle Glassy Gradient Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Product Tags (Top Left)
                          if (widget.product.tags != null &&
                              widget.product.tags!.isNotEmpty)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Wrap(
                                spacing: 4,
                                children: widget.product.tags!
                                    .take(1)
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          tag.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),

                          // Sold Out Ribbon
                          if (!widget.product.inStock ||
                              widget.product.stockCount <= 0)
                            Positioned(
                              top: 15,
                              left: -25,
                              child: Transform.rotate(
                                angle: -0.785,
                                child: Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                  ),
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
                      flex: 13,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text Content (Title & Description) - Wrapped in Expanded to prevent pushing others out
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: widget.product.title,
                                          style: GoogleFonts.outfit(
                                            fontSize:
                                                12, // Slightly larger for better readability
                                            fontWeight: FontWeight.w700,
                                            color: widget.product.inStock
                                                ? colorScheme.onSurface
                                                : Colors.grey.shade600,
                                            height: 1.1,
                                          ),
                                        ),
                                        if (widget.product.unit.isNotEmpty)
                                          TextSpan(
                                            text: ' - ${widget.product.unit}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade500,
                                              height: 1.1,
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.product.description,
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade500,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (widget.product.inStock &&
                                                widget.product.stockCount > 0)
                                            ? primaryColor.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              (widget.product.inStock &&
                                                  widget.product.stockCount > 0)
                                              ? primaryColor.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (widget.product.mrp != null &&
                                              widget.product.mrp! >
                                                  widget.product.price) ...[
                                            Text(
                                              '₹${widget.product.mrp!.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade500,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ), // More space
                                          ],
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '₹',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      (widget.product.inStock &&
                                                          widget
                                                                  .product
                                                                  .stockCount >
                                                              0)
                                                      ? primaryColor
                                                      : Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                widget.product.price
                                                    .toStringAsFixed(0),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      (widget.product.inStock &&
                                                          widget
                                                                  .product
                                                                  .stockCount >
                                                              0)
                                                      ? primaryColor
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
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
                                    onTap:
                                        (widget.product.inStock &&
                                            widget.product.stockCount > 0)
                                        ? widget.product.onAddToCart
                                        : null,

                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color:
                                            (widget.product.inStock &&
                                                widget.product.stockCount > 0)
                                            ? primaryColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: widget.product.inStock
                                            ? [
                                                BoxShadow(
                                                  color: primaryColor
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        widget.product.stockCount > 0
                                            ? Icons.add_rounded
                                            : Icons.block_rounded,
                                        color: widget.product.stockCount > 0
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                        size: 16,
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
            ), // Close Padding widget
            // Floating Action Icon (Theme Accent)
            if (isChristmas || isEid)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.1,
                      child: CachedNetworkImage(
                        imageUrl: isEid
                            ? [
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f319.png', // Crescent Moon
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/2b50.png', // Star
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f54c.png', // Mosque
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f381.png', // Gift
                              ][widget.product.title.hashCode.abs() % 4]
                            : [
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f385.png', // Santa
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f384.png', // Tree
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/26c4.png', // Snowman
                                'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f381.png', // Gift
                              ][widget.product.title.hashCode.abs() % 4],
                        width: 22,
                        height: 22,
                        placeholder: (context, url) => const SizedBox(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.card_giftcard,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade300,
          size: 36,
        ),
      ),
    );
  }
}
