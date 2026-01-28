import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/bestseller_card_model.dart';

class BestsellersController extends GetxController {
  final bestsellers = [
    BestsellerCardModel(
      image1: 'assets/images/chips1.jpg',
      image2: 'assets/images/chips2.jpg',
      image3: 'assets/images/chips3.jpg',
      image4: 'assets/images/chips4.jpg',
      moreCount: '+345',
      title: 'Chips & Namkeen',
      onTap: () {
        debugPrint('Navigating to Chips & Namkeen');
      },
    ),
    BestsellerCardModel(
      image1: 'assets/images/veg1.jpg',
      image2: 'assets/images/veg2.jpg',
      image3: 'assets/images/veg3.jpg',
      image4: 'assets/images/veg4.jpg',
      moreCount: '+89',
      title: 'Vegetables & Fruits',
      onTap: () {
        debugPrint('Navigating to Vegetables & Fruits');
      },
    ),
    BestsellerCardModel(
      image1: 'assets/images/dairy1.jpg',
      image2: 'assets/images/dairy2.jpg',
      image3: 'assets/images/dairy3.jpg',
      image4: 'assets/images/dairy4.jpg',
      moreCount: '+156',
      title: 'Dairy & Bakery',
      onTap: () {
        debugPrint('Navigating to Dairy & Bakery');
      },
    ),
    BestsellerCardModel(
      image1: 'assets/images/beverage1.jpg',
      image2: 'assets/images/beverage2.jpg',
      image3: 'assets/images/beverage3.jpg',
      image4: 'assets/images/beverage4.jpg',
      moreCount: '+234',
      title: 'Beverages',
      onTap: () {
        debugPrint('Navigating to Beverages');
      },
    ),
  ];
}