import 'package:get/get.dart';
import '../model/category_item_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomepageController extends GetxController {
  RxInt selectedIndex = 0.obs;

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
  ];

  void selectCategory(int index) {
    selectedIndex.value = index;
  }
}