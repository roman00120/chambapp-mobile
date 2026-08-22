import 'package:chambapp_mobile/core/network/json_helpers.dart';

final class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });
  final int id;
  final String name;
  final String slug;
  final String? icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: jsonInt(json['id']),
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    icon: json['icon']?.toString(),
  );
}

final class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.rating,
    required this.clientName,
    this.comment,
    this.createdAt,
  });
  final int id;
  final int rating;
  final String clientName;
  final String? comment;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: jsonInt(json['id']),
    rating: jsonInt(json['rating']),
    clientName: json['client_name']?.toString() ?? 'Cliente',
    comment: json['comment']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

final class ProfessionalModel {
  const ProfessionalModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    required this.verified,
    this.avatarUrl,
    this.bio,
    this.experienceYears,
    this.city,
    this.state,
    this.services = const [],
    this.recentReviews = const [],
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final int? experienceYears;
  final String? city;
  final String? state;
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final bool verified;
  final List<ServiceModel> services;
  final List<ReviewModel> recentReviews;

  String get generalLocation =>
      [city, state].where((value) => value?.isNotEmpty == true).join(', ');

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalModel(
        id: jsonInt(json['id']),
        name: json['name']?.toString() ?? 'Profesional',
        avatarUrl: json['avatar']?.toString(),
        bio: json['bio']?.toString(),
        experienceYears: json['experience_years'] == null
            ? null
            : jsonInt(json['experience_years']),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        rating: jsonDouble(json['rating']),
        totalReviews: jsonInt(json['total_reviews']),
        completedJobs: jsonInt(json['completed_jobs']),
        verified: json['verified'] == true,
        services: jsonList(json['services'])
            .map(ServiceModel.fromJson)
            .toList(),
        recentReviews: jsonList(json['recent_reviews'])
            .map(ReviewModel.fromJson)
            .toList(),
      );
}

final class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priceType,
    required this.currency,
    this.slug,
    this.price,
    this.coverImageUrl,
    this.category,
    this.professional,
    this.images = const [],
  });

  final int id;
  final String? slug;
  final String title;
  final String description;
  final String priceType;
  final String? price;
  final String currency;
  final String? coverImageUrl;
  final CategoryModel? category;
  final ProfessionalModel? professional;
  final List<String> images;

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: jsonInt(json['id']),
    slug: json['slug']?.toString(),
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    priceType: json['price_type']?.toString() ?? 'quote',
    price: json['price']?.toString(),
    currency: json['currency']?.toString() ?? 'MXN',
    coverImageUrl: json['cover_image_url']?.toString(),
    category: json['category'] is Map
        ? CategoryModel.fromJson(jsonMap(json['category']))
        : null,
    professional: json['professional'] is Map
        ? ProfessionalModel.fromJson(jsonMap(json['professional']))
        : null,
    images: jsonList(json['images'])
        .map((item) => item['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(),
  );
}
