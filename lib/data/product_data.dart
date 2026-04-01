import '../model/product.dart';

class ProductData {
  static const List<Product> products = [
    Product(
      id: '1',
      image:
          'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
      images: [
        'https://images.unsplash.com/photo-1546470427-227e333b90d3?w=500&q=80',
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500&q=80',
        'https://images.unsplash.com/photo-1558818498-28c1e002b655?w=500&q=80',
      ],
      title: 'Fresh Tomatoes',
      description:
          'Farm fresh red tomatoes, rich in vitamins and perfect for salads. These tomatoes are sourced directly from local organic farms, ensuring the highest quality and freshness. Perfect for cooking, salads, or juices.',
      price: 45.00,
      unit: 'kg',
      category: 'Vegetables',
    ),
    Product(
      id: '2',
      image:
          'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
      images: [
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80',
        'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80',
      ],
      title: 'Amul Milk',
      description:
          'Pure and fresh full cream milk, homogenized for quality. Amul milk is known for its richness and purity, perfect for your daily nutrition needs. Delivered fresh every morning.',
      price: 28.00,
      unit: 'liter',
      category: 'Dairy',
    ),
    Product(
      id: '3',
      image:
          'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
      title: 'Lays Classic Chips',
      description:
          'Crispy and delicious potato chips with perfect salt. Made from the finest potatoes and cooked to perfection. A perfect snack for any time of the day.',
      price: 20.00,
      unit: 'pack',
      category: 'Snacks',
    ),
    Product(
      id: '4',
      image:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
      title: 'Brown Bread',
      description:
          'Freshly baked whole wheat brown bread, high in fiber. Made with 100% whole wheat flour, perfect for a healthy breakfast or sandwich. Baked fresh daily.',
      price: 35.00,
      unit: 'pack',
      category: 'Bakery',
    ),
    Product(
      id: '5',
      image:
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80',
      title: 'Green Apples',
      description:
          'Crisp and juicy imported green apples, packed with nutrients. These premium quality apples are perfect for eating fresh or making healthy juices. Rich in fiber and vitamins.',
      price: 120.00,
      unit: 'kg',
      category: 'Fruits',
    ),
    Product(
      id: '6',
      image:
          'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=500&q=80',
      title: 'Coca Cola',
      description:
          'Refreshing carbonated soft drink, perfect for any occasion. The iconic taste of Coca-Cola that everyone loves. Best served chilled.',
      price: 40.00,
      unit: 'bottle',
      category: 'Beverages',
    ),
    Product(
      id: '7',
      image:
          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
      title: 'Fresh Paneer',
      description:
          'Soft and fresh cottage cheese, perfect for curries. Made from pure milk with no preservatives. Ideal for making delicious Indian dishes like paneer tikka, palak paneer, and more.',
      price: 80.00,
      unit: 'pack',
      category: 'Dairy',
    ),
    Product(
      id: '8',
      image:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&q=80',
      title: 'Basmati Rice',
      description:
          'Premium quality aged basmati rice with aromatic flavor. Long grain rice that is perfect for biryani, pulao, and other rice dishes. Aged for enhanced taste and aroma.',
      price: 150.00,
      unit: 'kg',
      category: 'Grains',
    ),
    Product(
      id: '9',
      image:
          'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=500&q=80',
      title: 'Organic Carrots',
      description:
          'Fresh organic carrots, rich in vitamin A. Perfect for salads and cooking.',
      price: 50.00,
      unit: 'kg',
      category: 'Vegetables',
    ),
    Product(
      id: '10',
      image:
          'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=500&q=80',
      title: 'Green Beans',
      description:
          'Fresh green beans, perfect for stir-fry and curries. Crisp and healthy.',
      price: 60.00,
      unit: 'kg',
      category: 'Vegetables',
    ),
    Product(
      id: '11',
      image:
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80',
      title: 'Fresh Bananas',
      description:
          'Sweet and ripe bananas, rich in potassium. Perfect for energy boost.',
      price: 40.00,
      unit: 'dozen',
      category: 'Fruits',
    ),
    Product(
      id: '12',
      image:
          'https://images.unsplash.com/photo-1587049352846-4a222e784l67?w=500&q=80',
      title: 'Orange Juice',
      description:
          'Fresh squeezed orange juice, 100% natural with no added sugar.',
      price: 50.00,
      unit: 'liter',
      category: 'Beverages',
    ),
  ];

  static const List<Product> homeFoodProducts = [
    Product(
      id: '101',
      image:
          'https://images.unsplash.com/photo-1546833999-b9f5816029bd?w=500&q=80',
      title: 'Dal Makhani',
      description:
          'Rich and creamy Dal Makhani, slow-cooked to perfection with black lentils and kidney beans. Served with a dollop of butter and fresh cream.',
      price: 180.00,
      unit: 'plate',
      category: 'North Indian',
    ),
    Product(
      id: '102',
      image:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
      title: 'Paneer Butter Masala',
      description:
          'Soft cottage cheese cubes cooked in a rich and creamy tomato-based gravy. A classic North Indian dish that pairs perfectly with naan or rice.',
      price: 220.00,
      unit: 'plate',
      category: 'North Indian',
    ),
    Product(
      id: '103',
      image:
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500&q=80',
      title: 'Chicken Biryani',
      description:
          'Aromatic basmati rice cooked with tender chicken pieces and a blend of exotic spices. Served with raita and salan for a complete meal.',
      price: 250.00,
      unit: 'plate',
      category: 'Biryani',
    ),
    Product(
      id: '104',
      image:
          'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=500&q=80',
      title: 'Masala Dosa',
      description:
          'Crispy fermented crepe made from rice batter and black lentils, stuffed with a spiced potato filling. Served with coconut chutney and sambar.',
      price: 90.00,
      unit: 'piece',
      category: 'South Indian',
    ),
    Product(
      id: '105',
      image:
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500&q=80',
      title: 'Samosa',
      description:
          'Deep-fried pastry filled with a savory filling of spiced potatoes, onions, and peas. A popular Indian snack best enjoyed with mint chutney.',
      price: 20.00,
      unit: 'piece',
      category: 'Snacks',
    ),
    Product(
      id: '106',
      image:
          'https://images.unsplash.com/photo-1567188040754-583522d069e5?w=500&q=80',
      title: 'Aloo Paratha',
      description:
          'Whole wheat flatbread stuffed with a spiced potato filling. Cooked on a griddle with ghee and served with curd and pickle.',
      price: 60.00,
      unit: 'piece',
      category: 'Breakfast',
    ),
    Product(
      id: '107',
      image:
          'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500&q=80',
      title: 'Gulab Jamun',
      description:
          'Soft and spongy milk-solid balls soaked in rose-flavored sugar syrup. A classic Indian dessert that melts in your mouth.',
      price: 40.00,
      unit: '2 pcs',
      category: 'Dessert',
    ),
    Product(
      id: '108',
      image:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&q=80',
      title: 'Veg Thali',
      description:
          'A complete meal consisting of roti, rice, dal, two vegetable dishes, raita, salad, and a sweet. A wholesome and balanced diet.',
      price: 150.00,
      unit: 'plate',
      category: 'Meals',
    ),
  ];
}
