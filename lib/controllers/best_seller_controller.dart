import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/bestseller_card_model.dart';
import 'homepage_controller.dart';

class BestsellersController extends GetxController {
  final HomepageController homepageController = Get.find<HomepageController>();
  final RxList<BestsellerCardModel> bestsellers = <BestsellerCardModel>[].obs;

  final groceryBestsellers = [
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1600952841320-db92ec4047ca?w=400',
      image2: 'https://images.unsplash.com/photo-1613919113640-c1ba54d7b185?w=400',
      image3: 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
      image4: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
      moreCount: '+345',
      title: 'Chips & Namkeen',
      onTap: () {
        debugPrint('Navigating to Chips & Namkeen');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
      image2: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400',
      image3: 'https://images.unsplash.com/photo-1519897831810-a9a01aceccd1?w=400',
      image4: 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?w=400',
      moreCount: '+89',
      title: 'Vegetables & Fruits',
      onTap: () {
        debugPrint('Navigating to Vegetables & Fruits');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400',
      image2: 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400',
      image3: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400',
      image4: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      moreCount: '+156',
      title: 'Dairy & Bakery',
      onTap: () {
        debugPrint('Navigating to Dairy & Bakery');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1437418747212-8d9709afab22?w=400',
      image2: 'https://images.unsplash.com/photo-1605379399642-870262d3d051?w=400',
      image3: 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400',
      image4: 'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=400',
      moreCount: '+234',
      title: 'Beverages',
      onTap: () {
        debugPrint('Navigating to Beverages');
      },
    ),
  ];

  final homeFoodBestsellers = [
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1546833999-b9f5816029bd?w=400',
      image2: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      image3: 'https://images.unsplash.com/photo-1585937421612-70a008356f36?w=400',
      image4: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
      moreCount: '+45',
      title: 'North Indian',
      onTap: () {
        debugPrint('Navigating to North Indian');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400',
      image2: 'https://images.unsplash.com/photo-1589301760576-416cc9f8d1e3?w=400',
      image3: 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e0?w=400',
      image4: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      moreCount: '+32',
      title: 'South Indian',
      onTap: () {
        debugPrint('Navigating to South Indian');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
      image2: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400',
      image3: 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=400',
      image4: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400',
      moreCount: '+28',
      title: 'Biryani & Rice',
      onTap: () {
        debugPrint('Navigating to Biryani & Rice');
      },
    ),
    BestsellerCardModel(
      image1: 'https://images.unsplash.com/photo-1551024601-564d6d674f33?w=400',
      image2: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400',
      image3: 'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=400',
      image4: 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=400',
      moreCount: '+18',
      title: 'Desserts & Sweets',
      onTap: () {
        debugPrint('Navigating to Desserts & Sweets');
      },
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _updateBestsellers();
    ever(homepageController.currentTab, (_) => _updateBestsellers());
  }

  void _updateBestsellers() {
    bestsellers.value = homepageController.currentTab.value == 'Grocery'
        ? groceryBestsellers
        : homeFoodBestsellers;
  }
}