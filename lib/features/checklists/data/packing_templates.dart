// Packing list templates for different trip types

/// Represents a packing list template with pre-defined items
class PackingTemplate {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<String> items;
  final String category;

  const PackingTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.items,
    required this.category,
  });
}

/// All available packing templates
class PackingTemplates {
  static const List<PackingTemplate> all = [
    // Essential Templates
    PackingTemplate(
      id: 'essentials',
      name: 'Travel Essentials',
      icon: '🎒',
      description: 'Must-have items for any trip',
      category: 'Essential',
      items: [
        'Passport / ID Card',
        'Wallet & Cards',
        'Phone & Charger',
        'Travel Documents',
        'Cash & Local Currency',
        'Travel Insurance Docs',
        'Medications',
        'Power Bank',
        'Headphones',
        'Water Bottle',
      ],
    ),

    // Beach Vacation
    PackingTemplate(
      id: 'beach',
      name: 'Beach Vacation',
      icon: '🏖️',
      description: 'Sun, sand, and sea essentials',
      category: 'Vacation',
      items: [
        'Swimsuit / Bikini',
        'Beach Towel',
        'Sunscreen SPF 50+',
        'Sunglasses',
        'Flip Flops / Sandals',
        'Beach Hat / Cap',
        'After-sun Lotion',
        'Waterproof Phone Pouch',
        'Beach Bag',
        'Snorkeling Gear',
        'Light Cover-up',
        'Insect Repellent',
      ],
    ),

    // Mountain / Trekking
    PackingTemplate(
      id: 'mountain',
      name: 'Mountain Trek',
      icon: '🏔️',
      description: 'Gear for hiking and trekking',
      category: 'Adventure',
      items: [
        'Hiking Boots',
        'Trekking Poles',
        'Backpack (40-60L)',
        'Rain Jacket',
        'Warm Fleece / Jacket',
        'Thermal Wear',
        'Hiking Socks',
        'First Aid Kit',
        'Headlamp / Torch',
        'Sunscreen & Lip Balm',
        'Water Purifier',
        'Energy Bars / Snacks',
        'Map & Compass',
        'Emergency Whistle',
      ],
    ),

    // Business Trip
    PackingTemplate(
      id: 'business',
      name: 'Business Trip',
      icon: '💼',
      description: 'Professional travel essentials',
      category: 'Work',
      items: [
        'Business Suits',
        'Formal Shirts',
        'Dress Shoes',
        'Laptop & Charger',
        'Business Cards',
        'Notebook & Pens',
        'Presentation Materials',
        'Tie / Accessories',
        'Iron / Steamer',
        'Toiletry Kit',
        'Portable WiFi',
        'Meeting Documents',
      ],
    ),

    // Winter / Cold Weather
    PackingTemplate(
      id: 'winter',
      name: 'Winter Trip',
      icon: '❄️',
      description: 'Stay warm in cold destinations',
      category: 'Seasonal',
      items: [
        'Heavy Winter Jacket',
        'Thermal Innerwear',
        'Warm Sweaters',
        'Woolen Socks',
        'Gloves',
        'Beanie / Winter Hat',
        'Scarf / Muffler',
        'Snow Boots',
        'Hand Warmers',
        'Lip Balm',
        'Moisturizer',
        'Hot Water Bottle',
      ],
    ),

    // City Explorer
    PackingTemplate(
      id: 'city',
      name: 'City Explorer',
      icon: '🏙️',
      description: 'Urban sightseeing essentials',
      category: 'Vacation',
      items: [
        'Comfortable Walking Shoes',
        'Day Backpack',
        'Camera',
        'City Map / Guidebook',
        'Light Jacket',
        'Umbrella',
        'Sunglasses',
        'Portable Charger',
        'Transit Card / Pass',
        'Snacks',
        'Reusable Water Bottle',
        'Hand Sanitizer',
      ],
    ),

    // Family with Kids
    PackingTemplate(
      id: 'family',
      name: 'Family Trip',
      icon: '👨‍👩‍👧‍👦',
      description: 'Everything for traveling with kids',
      category: 'Family',
      items: [
        'Kids\' Clothes (extra)',
        'Diapers / Wipes',
        'Baby Food / Snacks',
        'Toys & Games',
        'Kids\' Medications',
        'Stroller / Carrier',
        'Kids\' Sunscreen',
        'Favorite Stuffed Toy',
        'Coloring Books / Crayons',
        'Tablet with Kids\' Shows',
        'Child-proof Items',
        'First Aid for Kids',
      ],
    ),

    // Camping
    PackingTemplate(
      id: 'camping',
      name: 'Camping Trip',
      icon: '🏕️',
      description: 'Outdoor camping gear',
      category: 'Adventure',
      items: [
        'Tent',
        'Sleeping Bag',
        'Sleeping Mat / Pad',
        'Camping Stove',
        'Cookware & Utensils',
        'Cooler / Ice Box',
        'Lantern / Flashlight',
        'Fire Starter / Matches',
        'Camping Chair',
        'Knife / Multi-tool',
        'Rope / Paracord',
        'Trash Bags',
        'Insect Repellent',
        'Bear Spray (if needed)',
      ],
    ),

    // Toiletries
    PackingTemplate(
      id: 'toiletries',
      name: 'Toiletries',
      icon: '🧴',
      description: 'Personal care items',
      category: 'Essential',
      items: [
        'Toothbrush & Toothpaste',
        'Shampoo & Conditioner',
        'Body Wash / Soap',
        'Deodorant',
        'Face Wash',
        'Moisturizer',
        'Razor & Shaving Cream',
        'Comb / Brush',
        'Makeup (if needed)',
        'Contact Lens & Solution',
        'Cotton & Ear Buds',
        'Nail Clipper',
      ],
    ),

    // Electronics
    PackingTemplate(
      id: 'electronics',
      name: 'Tech & Gadgets',
      icon: '📱',
      description: 'Stay connected on the go',
      category: 'Essential',
      items: [
        'Phone & Charger',
        'Laptop & Charger',
        'Power Bank (20000mAh+)',
        'Universal Adapter',
        'Camera & Lenses',
        'Memory Cards',
        'Headphones',
        'Bluetooth Speaker',
        'E-Reader / Kindle',
        'Portable WiFi',
        'USB Cables',
        'Cable Organizer',
      ],
    ),

    // International Travel
    PackingTemplate(
      id: 'international',
      name: 'International Trip',
      icon: '✈️',
      description: 'Cross-border travel checklist',
      category: 'Essential',
      items: [
        'Valid Passport',
        'Visa Documents',
        'Flight Tickets',
        'Hotel Reservations',
        'Travel Insurance',
        'Vaccination Records',
        'International SIM / eSIM',
        'Currency Exchange',
        'Embassy Contact Info',
        'Copies of All Documents',
        'Universal Power Adapter',
        'Translation App Ready',
      ],
    ),

    // Weekend Getaway
    PackingTemplate(
      id: 'weekend',
      name: 'Weekend Getaway',
      icon: '🌴',
      description: 'Light packing for short trips',
      category: 'Vacation',
      items: [
        '2-3 Outfits',
        'Underwear & Socks',
        'Sleepwear',
        'Toiletry Bag',
        'Phone Charger',
        'Book / Kindle',
        'Snacks',
        'Sunglasses',
        'Light Jacket',
        'Medications',
      ],
    ),
  ];

  /// Get templates by category
  static List<PackingTemplate> byCategory(String category) {
    return all.where((t) => t.category == category).toList();
  }

  /// Get all unique categories
  static List<String> get categories {
    return all.map((t) => t.category).toSet().toList();
  }

  /// Get template by ID
  static PackingTemplate? byId(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
