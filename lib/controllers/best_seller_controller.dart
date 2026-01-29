import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/bestseller_card_model.dart';

class BestsellersController extends GetxController {
  final bestsellers = [
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
}