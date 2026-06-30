// Built-in templates used as fallback when the database table is empty.
// Mirrors supabase/migrations/20251204_seed_trip_templates.sql.

import '../domain/entities/trip_template.dart';
import '../presentation/providers/template_providers.dart';

class HardcodedTemplates {
  static final List<TripTemplate> all = [
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440001',
      name: 'Goa Beach Getaway',
      description:
          'Experience the perfect beach vacation in Goa with stunning beaches, vibrant nightlife, and delicious seafood. Visit iconic churches, enjoy water sports, and relax by the Arabian Sea.',
      destination: 'Goa',
      destinationState: 'Goa',
      durationDays: 3,
      budgetMin: 15000,
      budgetMax: 35000,
      currency: 'INR',
      category: TemplateCategory.beach,
      tags: ['beach', 'party', 'seafood', 'water-sports', 'nightlife'],
      bestSeason: ['October', 'November', 'December', 'January', 'February', 'March'],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: true,
      useCount: 250,
      rating: 4.8,
      ratingCount: 120,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440002',
      name: 'Royal Rajasthan Heritage Tour',
      description:
          'Explore the magnificent forts, palaces, and rich culture of Rajasthan. From the Pink City of Jaipur to the Blue City of Jodhpur, experience royal India.',
      destination: 'Jaipur - Jodhpur - Udaipur',
      destinationState: 'Rajasthan',
      durationDays: 5,
      budgetMin: 25000,
      budgetMax: 60000,
      currency: 'INR',
      category: TemplateCategory.heritage,
      tags: ['forts', 'palaces', 'culture', 'history', 'photography'],
      bestSeason: ['October', 'November', 'December', 'January', 'February', 'March'],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: true,
      useCount: 380,
      rating: 4.9,
      ratingCount: 200,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440003',
      name: 'Kerala Backwaters & Hills',
      description:
          "Experience God's Own Country with serene backwaters, lush tea gardens, and pristine beaches. A perfect blend of relaxation and natural beauty.",
      destination: 'Kochi - Alleppey - Munnar',
      destinationState: 'Kerala',
      durationDays: 4,
      budgetMin: 20000,
      budgetMax: 45000,
      currency: 'INR',
      category: TemplateCategory.family,
      tags: ['backwaters', 'houseboat', 'tea-gardens', 'nature', 'ayurveda'],
      bestSeason: [
        'September',
        'October',
        'November',
        'December',
        'January',
        'February',
        'March'
      ],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: true,
      useCount: 310,
      rating: 4.7,
      ratingCount: 165,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440004',
      name: 'Himachal Mountains Adventure',
      description:
          "From Shimla's colonial charm to Manali's adventure sports, experience the majestic Himalayas. Perfect for adventure seekers and nature lovers.",
      destination: 'Shimla - Manali',
      destinationState: 'Himachal Pradesh',
      durationDays: 5,
      budgetMin: 20000,
      budgetMax: 50000,
      currency: 'INR',
      category: TemplateCategory.adventure,
      tags: ['mountains', 'trekking', 'snow', 'adventure', 'paragliding'],
      bestSeason: ['March', 'April', 'May', 'June', 'September', 'October'],
      difficultyLevel: DifficultyLevel.moderate,
      isActive: true,
      isFeatured: true,
      useCount: 290,
      rating: 4.6,
      ratingCount: 145,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440005',
      name: 'Varanasi Spiritual Journey',
      description:
          "Experience the spiritual heart of India. Witness the mesmerizing Ganga Aarti, explore ancient temples, and discover the city's timeless traditions.",
      destination: 'Varanasi',
      destinationState: 'Uttar Pradesh',
      durationDays: 3,
      budgetMin: 10000,
      budgetMax: 25000,
      currency: 'INR',
      category: TemplateCategory.pilgrimage,
      tags: ['spiritual', 'temples', 'ganga', 'culture', 'photography'],
      bestSeason: ['October', 'November', 'December', 'January', 'February', 'March'],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: false,
      useCount: 180,
      rating: 4.5,
      ratingCount: 90,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440006',
      name: 'Andaman Island Paradise',
      description:
          'Discover pristine beaches, crystal-clear waters, and vibrant coral reefs. Perfect for beach lovers, snorkeling enthusiasts, and history buffs.',
      destination: 'Port Blair - Havelock - Neil Island',
      destinationState: 'Andaman & Nicobar',
      durationDays: 5,
      budgetMin: 35000,
      budgetMax: 80000,
      currency: 'INR',
      category: TemplateCategory.beach,
      tags: ['island', 'snorkeling', 'scuba', 'beaches', 'coral-reefs'],
      bestSeason: [
        'October',
        'November',
        'December',
        'January',
        'February',
        'March',
        'April',
        'May'
      ],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: true,
      useCount: 220,
      rating: 4.8,
      ratingCount: 110,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440007',
      name: 'Ladakh - The Ultimate Road Trip',
      description:
          "Conquer the world's highest motorable passes, witness stunning landscapes, and experience the unique Ladakhi culture. An adventure of a lifetime.",
      destination: 'Leh - Nubra - Pangong',
      destinationState: 'Ladakh',
      durationDays: 7,
      budgetMin: 40000,
      budgetMax: 100000,
      currency: 'INR',
      category: TemplateCategory.roadTrip,
      tags: ['road-trip', 'high-altitude', 'monasteries', 'lakes', 'adventure'],
      bestSeason: ['June', 'July', 'August', 'September'],
      difficultyLevel: DifficultyLevel.difficult,
      isActive: true,
      isFeatured: true,
      useCount: 340,
      rating: 4.9,
      ratingCount: 190,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440008',
      name: 'Darjeeling & Sikkim Hills',
      description:
          'From world-famous tea gardens to views of Kanchenjunga, explore the enchanting hill stations of the Eastern Himalayas.',
      destination: 'Darjeeling - Gangtok',
      destinationState: 'West Bengal & Sikkim',
      durationDays: 5,
      budgetMin: 25000,
      budgetMax: 55000,
      currency: 'INR',
      category: TemplateCategory.hillStation,
      tags: ['tea-gardens', 'mountains', 'toy-train', 'monasteries', 'nature'],
      bestSeason: ['March', 'April', 'May', 'September', 'October', 'November'],
      difficultyLevel: DifficultyLevel.moderate,
      isActive: true,
      isFeatured: false,
      useCount: 150,
      rating: 4.6,
      ratingCount: 75,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440009',
      name: 'Karnataka Wildlife Safari',
      description:
          "Experience India's rich wildlife at Bandipur and Nagarhole. Spot tigers, elephants, leopards, and diverse bird species in their natural habitat.",
      destination: 'Mysore - Bandipur - Nagarhole',
      destinationState: 'Karnataka',
      durationDays: 4,
      budgetMin: 30000,
      budgetMax: 70000,
      currency: 'INR',
      category: TemplateCategory.wildlife,
      tags: ['safari', 'tigers', 'elephants', 'birds', 'nature'],
      bestSeason: [
        'October',
        'November',
        'December',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June'
      ],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: false,
      useCount: 130,
      rating: 4.5,
      ratingCount: 65,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440010',
      name: 'Pondicherry French Escape',
      description:
          "A perfect weekend getaway to India's French Quarter. Explore colorful streets, pristine beaches, spiritual ashrams, and delightful cafes.",
      destination: 'Pondicherry',
      destinationState: 'Puducherry',
      durationDays: 2,
      budgetMin: 8000,
      budgetMax: 20000,
      currency: 'INR',
      category: TemplateCategory.weekend,
      tags: ['french-quarter', 'beaches', 'cafes', 'ashram', 'cycling'],
      bestSeason: ['October', 'November', 'December', 'January', 'February', 'March'],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: false,
      useCount: 200,
      rating: 4.4,
      ratingCount: 100,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440011',
      name: 'Maldives Honeymoon Escape',
      description:
          'The ultimate romantic getaway with overwater villas, pristine turquoise lagoons, and breathtaking sunsets. Perfect for newlyweds.',
      destination: 'Malé - Maafushi',
      destinationState: null,
      durationDays: 5,
      budgetMin: 100000,
      budgetMax: 300000,
      currency: 'INR',
      category: TemplateCategory.honeymoon,
      tags: ['romantic', 'overwater-villa', 'snorkeling', 'luxury', 'sunset'],
      bestSeason: [
        'November',
        'December',
        'January',
        'February',
        'March',
        'April'
      ],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: true,
      useCount: 175,
      rating: 4.9,
      ratingCount: 85,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
    TripTemplate(
      id: '550e8400-e29b-41d4-a716-446655440012',
      name: 'Coorg Coffee Estate Retreat',
      description:
          'Escape to the Scotland of India — rolling coffee plantations, misty hills, and cascading waterfalls. Ideal for a relaxed family weekend.',
      destination: 'Coorg',
      destinationState: 'Karnataka',
      durationDays: 3,
      budgetMin: 15000,
      budgetMax: 40000,
      currency: 'INR',
      category: TemplateCategory.family,
      tags: ['coffee', 'plantation', 'waterfall', 'trekking', 'nature'],
      bestSeason: [
        'October',
        'November',
        'December',
        'January',
        'February',
        'March',
        'April'
      ],
      difficultyLevel: DifficultyLevel.easy,
      isActive: true,
      isFeatured: false,
      useCount: 140,
      rating: 4.6,
      ratingCount: 70,
      createdAt: DateTime(2025, 12, 4),
      updatedAt: DateTime(2025, 12, 4),
    ),
  ];

  /// Return hardcoded templates filtered to match [filters], sorted featured-first.
  static List<TripTemplate> filtered(TemplateFilters? filters) {
    if (filters == null) {
      return List.of(all)
        ..sort((a, b) {
          if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
          return b.useCount.compareTo(a.useCount);
        });
    }

    return all.where((t) {
      if (filters.category != null && t.category != filters.category) { return false; }
      if (filters.featuredOnly == true && !t.isFeatured) { return false; }
      if (filters.minDays != null && t.durationDays < filters.minDays!) { return false; }
      if (filters.maxDays != null && t.durationDays > filters.maxDays!) { return false; }
      if (filters.maxBudget != null &&
          t.budgetMin != null &&
          t.budgetMin! > filters.maxBudget!) { return false; }
      if (filters.search != null && filters.search!.isNotEmpty) {
        final q = filters.search!.toLowerCase();
        if (!t.name.toLowerCase().contains(q) &&
            !t.destination.toLowerCase().contains(q) &&
            !(t.description?.toLowerCase().contains(q) ?? false)) { return false; }
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return b.useCount.compareTo(a.useCount);
      });
  }
}
