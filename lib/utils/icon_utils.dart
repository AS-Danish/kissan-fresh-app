import 'package:flutter/material.dart';

class IconUtils {
  static IconData getCategoryIcon(String name) {
    final n = name.toLowerCase();
    
    // Grocery mapping
    if (n.contains('vegetable')) return Icons.eco_rounded;
    if (n.contains('fruit')) return Icons.apple_rounded;
    if (n.contains('dairy')) return Icons.water_drop_rounded;
    if (n.contains('poultry') || n.contains('meat') || n.contains('chicken')) return Icons.set_meal_rounded;
    if (n.contains('pantry') || n.contains('spice')) return Icons.whatshot_rounded;
    if (n.contains('grain')) return Icons.grain_rounded;
    if (n.contains('beverage') || n.contains('juice')) return Icons.local_drink_rounded;
    if (n.contains('grocery')) return Icons.shopping_basket_rounded;
    if (n.contains('winter')) return Icons.ac_unit_rounded;
    if (n.contains('electric')) return Icons.devices_rounded;
    if (n.contains('beauty') || n.contains('spa')) return Icons.spa_rounded;
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom_rounded;
    if (n.contains('footwear') || n.contains('shoe')) return Icons.storefront_rounded;
    if (n.contains('home') || n.contains('chair')) return Icons.chair_rounded;
    if (n.contains('kitchen')) return Icons.kitchen_rounded;
    if (n.contains('fitness') || n.contains('gym')) return Icons.fitness_center_rounded;
    if (n.contains('book')) return Icons.menu_book_rounded;
    if (n.contains('toy') || n.contains('game')) return Icons.extension_rounded;
    if (n.contains('gaming')) return Icons.sports_esports_rounded;
    if (n.contains('music')) return Icons.music_note_rounded;
    if (n.contains('travel')) return Icons.card_travel_rounded;
    if (n.contains('pet')) return Icons.pets_rounded;
    if (n.contains('pharmacy') || n.contains('med')) return Icons.medical_services_rounded;
    if (n.contains('gift')) return Icons.card_giftcard_rounded;

    // Home Food mapping
    if (n.contains('thali')) return Icons.restaurant_rounded;
    if (n.contains('biryani') || n.contains('rice')) return Icons.dinner_dining_rounded;
    if (n.contains('curry') || n.contains('paneer')) return Icons.soup_kitchen_rounded;
    if (n.contains('south indian') || n.contains('dosa')) return Icons.breakfast_dining_rounded;
    if (n.contains('tandoor') || n.contains('starter')) return Icons.kebab_dining_rounded;
    if (n.contains('sweet') || n.contains('halwa') || n.contains('jamun')) return Icons.icecream_rounded;
    if (n.contains('snack') || n.contains('samosa') || n.contains('pickle')) return Icons.cookie_rounded;
    if (n.contains('bakery')) return Icons.bakery_dining_rounded;
    if (n.contains('tiffin')) return Icons.inventory_2_rounded;

    // Default
    return Icons.grid_view_rounded;
  }
}
