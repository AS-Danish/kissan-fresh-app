class CouponModel {
  final String code;
  final String discountType; // "percentage" or "flat" (or "fixed")
  final double discountValue;
  final double? minOrderValue;
  final bool isActive;
  final String? applicableCategory; // null = all products
  final String? applicableProduct;
  final int? maxUsesPerUser;
  final int? totalUsageLimit;
  final int currentUsageCount;
  final String applyTo; // "all", "specific"
  final String productType; // "kissan-fresh", "home-food", etc.

  CouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    required this.isActive,
    this.applicableCategory,
    this.applicableProduct,
    this.maxUsesPerUser,
    this.totalUsageLimit,
    this.currentUsageCount = 0,
    required this.applyTo,
    required this.productType,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderValue: json['minOrderValue'] != null ? (json['minOrderValue']).toDouble() : null,
      isActive: json['isActive'] ?? false,
      applicableCategory: json['applicableCategory'],
      applicableProduct: json['applicableProduct'],
      maxUsesPerUser: json['maxUsesPerUser'] != null ? (json['maxUsesPerUser']).toInt() : null,
      totalUsageLimit: json['totalUsageLimit'] != null ? (json['totalUsageLimit']).toInt() : null,
      currentUsageCount: (json['currentUsageCount'] ?? 0).toInt(),
      applyTo: json['applyTo'] ?? 'all',
      productType: json['productType'] ?? 'kissan-fresh',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'applicableCategory': applicableCategory,
      'applicableProduct': applicableProduct,
      'maxUsesPerUser': maxUsesPerUser,
      'totalUsageLimit': totalUsageLimit,
      'currentUsageCount': currentUsageCount,
      'applyTo': applyTo,
      'productType': productType,
    };
  }
}
