import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/achievements/domain/achievement_model.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';

enum ProfessionalVerification {
  unverified('unverified', 'Perfil sin revisar'),
  pending('pending', 'Revisión de perfil pendiente'),
  verified('verified', 'Perfil habilitado'),
  rejected('rejected', 'Perfil rechazado'),
  unknown('unknown', 'No disponible');

  const ProfessionalVerification(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ProfessionalVerification fromApi(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => unknown,
  );
}

enum IdentityVerificationStatus {
  notStarted('not_started', 'No iniciada'),
  pending('pending', 'En revisión'),
  verified('verified', 'Identidad verificada'),
  rejected('rejected', 'No aprobada'),
  needsReview('needs_review', 'Revisión necesaria'),
  expired('expired', 'Vencida'),
  unknown('unknown', 'No disponible');

  const IdentityVerificationStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static IdentityVerificationStatus fromApi(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => unknown,
  );
}

final class IdentityVerificationModel {
  const IdentityVerificationModel({
    required this.status,
    required this.isRequired,
    required this.identityVerified,
    required this.canAcceptJobs,
    required this.canStartVerification,
    required this.documentsStoredByChambapp,
    this.provider,
    this.submittedAt,
    this.verifiedAt,
    this.expiresAt,
    this.lastProviderSyncAt,
    this.message,
  });

  final IdentityVerificationStatus status;
  final bool isRequired;
  final bool identityVerified;
  final bool canAcceptJobs;
  final bool canStartVerification;
  final bool documentsStoredByChambapp;
  final String? provider;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final DateTime? lastProviderSyncAt;
  final String? message;

  factory IdentityVerificationModel.fromJson(Map<String, dynamic> json) =>
      IdentityVerificationModel(
        status: IdentityVerificationStatus.fromApi(json['status']),
        isRequired: json['is_required'] == true,
        identityVerified: json['identity_verified'] == true,
        canAcceptJobs: json['can_accept_jobs'] == true,
        canStartVerification: json['can_start_verification'] == true,
        documentsStoredByChambapp: json['documents_stored_by_chambapp'] == true,
        provider: json['provider']?.toString(),
        submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
        verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
        lastProviderSyncAt: DateTime.tryParse(
          json['last_provider_sync_at']?.toString() ?? '',
        ),
        message: json['message']?.toString(),
      );
}

final class IdentityVerificationStart {
  const IdentityVerificationStart({required this.url, required this.status});

  final Uri url;
  final IdentityVerificationStatus status;

  factory IdentityVerificationStart.fromJson(Map<String, dynamic> json) {
    final url = Uri.tryParse(json['verification_url']?.toString() ?? '');
    if (url == null || url.scheme != 'https') {
      throw const FormatException('La URL de verificación no es válida.');
    }

    return IdentityVerificationStart(
      url: url,
      status: IdentityVerificationStatus.fromApi(json['status']),
    );
  }
}

enum AvailabilityStatus {
  available('available', 'Disponible'),
  busy('busy', 'Ocupado'),
  unavailable('unavailable', 'No disponible');

  const AvailabilityStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

final class ProfessionalProfileModel {
  const ProfessionalProfileModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    required this.verification,
    required this.isAvailable,
    this.achievements = const [],
    this.avatarUrl,
    this.bio,
    this.experienceYears,
    this.city,
    this.state,
    this.postalCode,
    this.serviceRadiusKm,
    this.availabilityStatus,
    this.locationUpdatedAt,
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final int? experienceYears;
  final String? city;
  final String? state;
  final String? postalCode;
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final ProfessionalVerification verification;
  final bool isAvailable;
  final List<AchievementModel> achievements;
  final String? availabilityStatus;
  final int? serviceRadiusKm;
  final DateTime? locationUpdatedAt;

  String get generalLocation =>
      [city, state].where((value) => value?.isNotEmpty == true).join(', ');

  factory ProfessionalProfileModel.fromJson(
    Map<String, dynamic> json,
  ) => ProfessionalProfileModel(
    id: jsonInt(json['id']),
    name: json['name']?.toString() ?? 'Profesional',
    avatarUrl: (json['avatar'] ?? json['profile_photo_url'])?.toString(),
    bio: json['bio']?.toString(),
    experienceYears: json['experience_years'] == null
        ? null
        : jsonInt(json['experience_years']),
    city: json['city']?.toString(),
    state: json['state']?.toString(),
    postalCode: json['postal_code']?.toString(),
    rating: jsonDouble(json['rating']),
    totalReviews: jsonInt(json['total_reviews']),
    completedJobs: jsonInt(json['completed_jobs']),
    verification: ProfessionalVerification.fromApi(json['verification_status']),
    isAvailable: json['is_available'] == true,
    achievements:
        (json['achievements'] as List<dynamic>?)
            ?.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    availabilityStatus: json['availability_status']?.toString(),
    serviceRadiusKm: json['service_radius_km'] == null
        ? null
        : jsonInt(json['service_radius_km']),
    locationUpdatedAt: DateTime.tryParse(
      json['location_updated_at']?.toString() ?? '',
    ),
  );
}

final class AvailabilityModel {
  const AvailabilityModel({
    required this.isAvailable,
    required this.serviceRadiusKm,
    this.availabilityStatus,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
  });

  final bool isAvailable;
  final String? availabilityStatus;
  final int serviceRadiusKm;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;

  AvailabilityStatus get displayStatus {
    if (availabilityStatus == AvailabilityStatus.busy.apiValue) {
      return AvailabilityStatus.busy;
    }
    return isAvailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.unavailable;
  }

  factory AvailabilityModel.fromJson(
    Map<String, dynamic> json,
  ) => AvailabilityModel(
    isAvailable: json['is_available'] == true,
    availabilityStatus: json['availability_status']?.toString(),
    serviceRadiusKm: json['service_radius_km'] == null
        ? 10
        : jsonInt(json['service_radius_km']),
    latitude: json['latitude'] == null ? null : jsonDouble(json['latitude']),
    longitude: json['longitude'] == null ? null : jsonDouble(json['longitude']),
    locationUpdatedAt: DateTime.tryParse(
      json['location_updated_at']?.toString() ?? '',
    ),
  );
}

enum ProfessionalPriceType {
  fixed('fixed', 'Precio fijo'),
  startingAt('starting_at', 'Desde'),
  quote('quote', 'Cotización');

  const ProfessionalPriceType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ProfessionalPriceType fromApi(Object? value) =>
      values.firstWhere((item) => item.apiValue == value, orElse: () => quote);
}

final class ProfessionalServiceModel {
  const ProfessionalServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priceType,
    required this.currency,
    required this.isActive,
    this.price,
    this.coverImageUrl,
    this.category,
  });

  final int id;
  final String title;
  final String description;
  final ProfessionalPriceType priceType;
  final String? price;
  final String currency;
  final bool isActive;
  final String? coverImageUrl;
  final CategoryModel? category;

  String get formattedPrice => switch (priceType) {
    ProfessionalPriceType.quote => 'Cotización',
    ProfessionalPriceType.startingAt => 'Desde \$${price ?? '0'} $currency',
    ProfessionalPriceType.fixed => '\$${price ?? '0'} $currency',
  };

  factory ProfessionalServiceModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalServiceModel(
        id: jsonInt(json['id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        priceType: ProfessionalPriceType.fromApi(json['price_type']),
        price: json['price']?.toString(),
        currency: json['currency']?.toString() ?? 'MXN',
        isActive: json['is_active'] != false,
        coverImageUrl: json['cover_image_url']?.toString(),
        category: json['category'] is Map
            ? CategoryModel.fromJson(jsonMap(json['category']))
            : null,
      );
}

final class JobInvitationModel {
  const JobInvitationModel({
    required this.id,
    required this.status,
    required this.distanceKm,
    required this.jobId,
    required this.title,
    required this.description,
    this.category,
    this.city,
    this.state,
    this.serviceMode,
    this.scheduledFor,
    this.invitedAt,
    this.expiresAt,
  });

  final int id;
  final String status;
  final double distanceKm;
  final int jobId;
  final String title;
  final String description;
  final CategoryModel? category;
  final String? city;
  final String? state;
  final String? serviceMode;
  final DateTime? scheduledFor;
  final DateTime? invitedAt;
  final DateTime? expiresAt;

  bool get expired => expiresAt?.isBefore(DateTime.now()) == true;
  bool get actionable =>
      !expired && const {'pending', 'viewed'}.contains(status);

  factory JobInvitationModel.fromJson(Map<String, dynamic> json) {
    final job = jsonMap(json['job']);
    return JobInvitationModel(
      id: jsonInt(json['id']),
      status: json['status']?.toString() ?? '',
      distanceKm: jsonDouble(json['distance_km']),
      jobId: jsonInt(job['id']),
      title: job['title']?.toString() ?? 'Oportunidad',
      description: job['description']?.toString() ?? '',
      category: job['category'] is Map
          ? CategoryModel.fromJson(jsonMap(job['category']))
          : null,
      city: job['city']?.toString(),
      state: job['state']?.toString(),
      serviceMode: job['service_mode']?.toString(),
      scheduledFor: DateTime.tryParse(job['scheduled_for']?.toString() ?? ''),
      invitedAt: DateTime.tryParse(json['invited_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}

enum InvitationActionOutcome {
  accepted,
  declined,
  alreadyTaken,
  busy,
  expired,
  locationStale,
  networkUnconfirmed,
  failed,
}

final class InvitationActionResult {
  const InvitationActionResult({
    required this.outcome,
    required this.message,
    this.job,
  });
  final InvitationActionOutcome outcome;
  final String message;
  final JobModel? job;
  bool get succeeded => outcome == InvitationActionOutcome.accepted;
}

final class InvitationFeedState {
  const InvitationFeedState({
    this.items = const [],
    this.processingIds = const {},
    this.consecutiveErrors = 0,
    this.message,
  });
  final List<JobInvitationModel> items;
  final Set<int> processingIds;
  final int consecutiveErrors;
  final String? message;

  InvitationFeedState copyWith({
    List<JobInvitationModel>? items,
    Set<int>? processingIds,
    int? consecutiveErrors,
    String? message,
    bool clearMessage = false,
  }) => InvitationFeedState(
    items: items ?? this.items,
    processingIds: processingIds ?? this.processingIds,
    consecutiveErrors: consecutiveErrors ?? this.consecutiveErrors,
    message: clearMessage ? null : message ?? this.message,
  );
}

final class EarningsSummaryModel {
  const EarningsSummaryModel({required this.available});
  final bool available;
  static const unavailable = EarningsSummaryModel(available: false);
}

final class ProfessionalProfileInput {
  const ProfessionalProfileInput({
    required this.name,
    required this.phone,
    required this.experienceYears,
    this.bio,
    this.city,
    this.state,
    this.postalCode,
    this.photoPath,
  });
  final String name;
  final String phone;
  final int experienceYears;
  final String? bio;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? photoPath;
}

final class ProfessionalServiceInput {
  const ProfessionalServiceInput({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priceType,
    this.price,
    this.imagePaths = const [],
  });
  final int categoryId;
  final String title;
  final String description;
  final ProfessionalPriceType priceType;
  final String? price;
  final List<String> imagePaths;
}
