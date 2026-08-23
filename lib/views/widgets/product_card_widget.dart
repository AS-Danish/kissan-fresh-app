import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../model/product_card_model.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/cart_controller.dart';
import 'dart:async';

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
  bool _isExpanded = false;
  Timer? _collapseTimer;
  late final CartController _cartController;
  late final ThemeController _themeController;
  int _imageCandidateIndex = 0;
  bool _imageAdvanceScheduled = false;
  bool _automaticImageRetryUsed = false;

  @override
  void initState() {
    super.initState();
    _cartController = Get.find<CartController>();
    _themeController = Get.find<ThemeController>();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.image != widget.product.image ||
        oldWidget.product.images != widget.product.images) {
      _imageCandidateIndex = 0;
      _imageAdvanceScheduled = false;
      _automaticImageRetryUsed = false;
    }
  }

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  List<String> get _imageCandidates {
    final candidates = <String>[
      widget.product.image,
      ...?widget.product.images,
      ...?widget.product.variations?.map((variation) => variation.image ?? ''),
    ];
    final normalized = <String>[];
    for (final candidate in candidates) {
      final value = _normalizeImagePath(candidate);
      if (value.isNotEmpty && !normalized.contains(value)) {
        normalized.add(value);
      }
    }
    return normalized;
  }

  String _normalizeImagePath(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('//')) return 'https:$trimmed';
    if (trimmed.startsWith('http://')) {
      return Uri.parse(trimmed).replace(scheme: 'https').toString();
    }
    if (trimmed.startsWith('https://')) return Uri.parse(trimmed).toString();
    return trimmed;
  }

  void _showNextImage(List<String> candidates) {
    if (_imageAdvanceScheduled ||
        _imageCandidateIndex >= candidates.length - 1) {
      return;
    }
    _imageAdvanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _imageCandidateIndex++;
        _imageAdvanceScheduled = false;
      });
    });
  }

  void _handleImageFailure(List<String> candidates) {
    if (_imageCandidateIndex < candidates.length - 1) {
      _showNextImage(candidates);
      return;
    }
    if (_automaticImageRetryUsed || _imageAdvanceScheduled) return;
    _automaticImageRetryUsed = true;
    _imageAdvanceScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 600), () async {
      for (final candidate in candidates.where(_isNetworkImage)) {
        await CachedNetworkImage.evictFromCache(candidate);
      }
      if (!mounted) return;
      setState(() {
        _imageCandidateIndex = 0;
        _imageAdvanceScheduled = false;
      });
    });
  }

  Widget _buildImage() {
    final candidates = _imageCandidates;
    if (candidates.isEmpty) return _buildErrorPlaceholder();
    if (_imageCandidateIndex >= candidates.length) _imageCandidateIndex = 0;
    final imagePath = candidates[_imageCandidateIndex];

    return _isNetworkImage(imagePath)
        ? CachedNetworkImage(
            key: ValueKey(imagePath),
            imageUrl: imagePath,
            fit: BoxFit.cover,
            memCacheWidth: 300,
            memCacheHeight: 300,
            maxWidthDiskCache: 600,
            maxHeightDiskCache: 600,
            fadeInDuration: const Duration(milliseconds: 100),
            fadeOutDuration: const Duration(milliseconds: 60),
            useOldImageOnUrlChange: true,
            filterQuality: FilterQuality.low,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) {
              _handleImageFailure(candidates);
              return _imageAdvanceScheduled ||
                      _imageCandidateIndex < candidates.length - 1
                  ? _buildPlaceholder()
                  : _buildErrorPlaceholder();
            },
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.cover,
            cacheWidth: 300,
            cacheHeight: 300,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stackTrace) {
              _handleImageFailure(candidates);
              return _imageAdvanceScheduled ||
                      _imageCandidateIndex < candidates.length - 1
                  ? _buildPlaceholder()
                  : _buildErrorPlaceholder();
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;
    final isChristmas = _themeController.isChristmas.value;
    final isEid = _themeController.isEid.value;

    return RepaintBoundary(
      child: GestureDetector(
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
                                            style: TextStyle(
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
                                              style: TextStyle(
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
                                      style: TextStyle(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                (widget.product.inStock &&
                                                    widget.product.stockCount >
                                                        0)
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
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade500,
                                                  decoration: TextDecoration
                                                      .lineThrough,
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
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        (widget
                                                                .product
                                                                .inStock &&
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
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        (widget
                                                                .product
                                                                .inStock &&
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

                                  // Modern Add Button / Quantity Selector
                                  if (widget.showAddButton)
                                    Obx(() {
                                      final cartController = _cartController;
                                      String productId =
                                          widget.product.id ??
                                          widget.product.title;

                                      if (widget.product.hasVariations &&
                                          widget.product.variations != null &&
                                          widget
                                              .product
                                              .variations!
                                              .isNotEmpty) {
                                        if (!productId.contains('_')) {
                                          final v =
                                              widget.product.variations!.first;
                                          final vId =
                                              v.id ?? "${v.unitValue}${v.unit}";
                                          productId = '${productId}_$vId';
                                        }
                                      }

                                      int quantity = cartController
                                          .getProductQuantity(productId);

                                      if (quantity > 0) {
                                        if (_isExpanded) {
                                          return Container(
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryColor
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    cartController
                                                        .decrementItem(
                                                          productId,
                                                        );
                                                    _startCollapseTimer();
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.0,
                                                        ),
                                                    child: Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '$quantity',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    cartController
                                                        .incrementItem(
                                                          productId,
                                                        );
                                                    _startCollapseTimer();
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.0,
                                                        ),
                                                    child: Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return GestureDetector(
                                            onTap: _startCollapseTimer,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: primaryColor
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.add_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      return GestureDetector(
                                        onTap:
                                            (widget.product.inStock &&
                                                widget.product.stockCount > 0)
                                            ? () {
                                                widget.product.onAddToCart();
                                                _startCollapseTimer();
                                              }
                                            : null,

                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color:
                                                (widget.product.inStock &&
                                                    widget.product.stockCount >
                                                        0)
                                                ? primaryColor
                                                : Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: widget.product.inStock
                                                ? [
                                                    BoxShadow(
                                                      color: primaryColor
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
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
                                      );
                                    }),
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (isEid
                            ? const ['🌙', '⭐', '🕌', '🎁']
                            : const [
                                '🎅',
                                '🎄',
                                '☃️',
                                '🎁',
                              ])[widget.product.title.hashCode.abs() % 4],
                        style: const TextStyle(fontSize: 18),
                      ),
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
      child: Icon(
        Icons.shopping_basket_outlined,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        size: 28,
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
