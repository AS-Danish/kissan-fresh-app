import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/category_item_model.dart';
import '../model/product_card_model.dart';
import '../views/screens/product_details_screen.dart';
import 'cart_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomepageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  RxString currentTab = 'Grocery'.obs; // 'Grocery' or 'HomeFood'
  RxString currentAddress = 'Azam Colony, Roshan Gate'.obs;

  void switchTab(String tab) {
    currentTab.value = tab;
  }

  void updateAddress(String newAddress) {
    currentAddress.value = newAddress;
  }

  final categories = [
    CategoryItemModel(
      label: "All",
      icon: FontAwesomeIcons.tableCells,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Winter",
      icon: FontAwesomeIcons.snowflake,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Electronics",
      icon: FontAwesomeIcons.desktop,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Beauty",
      icon: FontAwesomeIcons.spa,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Groceries",
      icon: FontAwesomeIcons.basketShopping,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fashion",
      icon: FontAwesomeIcons.shirt,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Footwear",
      icon: FontAwesomeIcons.shoePrints,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Home",
      icon: FontAwesomeIcons.couch,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Kitchen",
      icon: FontAwesomeIcons.utensils,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Fitness",
      icon: FontAwesomeIcons.dumbbell,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Books",
      icon: FontAwesomeIcons.book,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Toys",
      icon: FontAwesomeIcons.puzzlePiece,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gaming",
      icon: FontAwesomeIcons.gamepad,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Music",
      icon: FontAwesomeIcons.music,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Travel",
      icon: FontAwesomeIcons.suitcaseRolling,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Pets",
      icon: FontAwesomeIcons.paw,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Pharmacy",
      icon: FontAwesomeIcons.pills,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gifts",
      icon: FontAwesomeIcons.gift,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Gifts",
      icon: FontAwesomeIcons.gift,
      onTap: () {},
    ),
  ];

  final homeFoodCategories = [
    CategoryItemModel(
      label: "All",
      icon: FontAwesomeIcons.utensils,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Tiffins",
      icon: FontAwesomeIcons.boxOpen,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Thali",
      icon: FontAwesomeIcons.plateWheat,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Snacks",
      icon: FontAwesomeIcons.cookieBite,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Sweets",
      icon: FontAwesomeIcons.candyCane,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Pickles",
      icon: FontAwesomeIcons.jar,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Spices",
      icon: FontAwesomeIcons.pepperHot,
      onTap: () {},
    ),
    CategoryItemModel(
      label: "Bakery",
      icon: FontAwesomeIcons.breadSlice,
      onTap: () {},
    ),
  ];

  RxInt selectedHomeFoodIndex = 0.obs;

  void selectHomeFoodCategory(int index) {
    selectedHomeFoodIndex.value = index;
  }

  void selectCategory(int index) {
    selectedIndex.value = index;
  }

  // Home Food Products
  final homeFoodProducts = [
    ProductCardModel(
      id: 'hf_1',
      title: "Spicy Paneer Thali",
      description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
      price: 150,
      unit: "plate",
      image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
      category: "Thali",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_1',
                title: "Spicy Paneer Thali",
                description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
                price: 150,
                unit: "plate",
                image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
                category: "Thali",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_1',
            title: "Spicy Paneer Thali",
            description: "Includes 3 rotis, paneer gravy, rice, dal & salad",
            price: 150,
            unit: "plate",
            image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        Get.snackbar("Added to Cart", "Spicy Paneer Thali added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500));
      },
    ),
    ProductCardModel(
      id: 'hf_2',
      title: "Chicken Biryani",
      description: "Aromatic basmati rice cooked with tender chicken and spices",
      price: 220,
      unit: "plate",
      image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Thali",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_2',
                title: "Chicken Biryani",
                description: "Aromatic basmati rice cooked with tender chicken and spices",
                price: 220,
                unit: "plate",
                image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Thali",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_2',
            title: "Chicken Biryani",
            description: "Aromatic basmati rice cooked with tender chicken and spices",
            price: 220,
            unit: "plate",
            image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Thali",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        Get.snackbar("Added to Cart", "Chicken Biryani added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500));
      },
    ),
    ProductCardModel(
      id: 'hf_3',
      title: "Methi Thepla",
      description: "Healthy and tasty flatbread made with fenugreek leaves",
      price: 40,
      unit: "pc",
      image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Snacks",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_3',
                title: "Methi Thepla",
                description: "Healthy and tasty flatbread made with fenugreek leaves",
                price: 40,
                unit: "pc",
                image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Snacks",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_3',
            title: "Methi Thepla",
            description: "Healthy and tasty flatbread made with fenugreek leaves",
            price: 40,
            unit: "pc",
            image: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Snacks",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        Get.snackbar("Added to Cart", "Methi Thepla added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500));
      },
    ),
    ProductCardModel(
      id: 'hf_4',
      title: "Gajar Ka Halwa",
      description: "Homemade carrot pudding made with ghee and milk",
      price: 300,
      unit: "500g",
      image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      category: "Sweets",
      onTap: () {
        Get.to(() =>
            ProductDetailsScreen(
              product: ProductCardModel(
                id: 'hf_4',
                title: "Gajar Ka Halwa",
                description: "Homemade carrot pudding made with ghee and milk",
                price: 300,
                unit: "500g",
                image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                category: "Sweets",
                onTap: () {},
                onAddToCart: () {},
              ),
            ));
      },
      onAddToCart: () {
        Get.find<CartController>().addToCart(
          ProductCardModel(
            id: 'hf_4',
            title: "Gajar Ka Halwa",
            description: "Homemade carrot pudding made with ghee and milk",
            price: 300,
            unit: "500g",
            image: "https://images.unsplash.com/photo-1624551121868-245749c66925?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            category: "Sweets",
            onTap: () {},
            onAddToCart: () {},
          ),
          1,
        );
        Get.snackbar("Added to Cart", "Gajar Ka Halwa added",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0d9488),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 16,
            duration: const Duration(milliseconds: 1500));
      },
    ),
  ];
}