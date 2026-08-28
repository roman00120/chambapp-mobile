import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';

enum JobStatus {
  pending('pending', 'Pendiente'),
  searching('searching', 'Buscando profesional'),
  matched('matched', 'Profesional encontrado'),
  awaitingQuote('awaiting_quote', 'Esperando cotización'),
  accepted('accepted', 'Aceptado'),
  rejected('rejected', 'Rechazado'),
  awaitingPayment('awaiting_payment', 'Pendiente de pago'),
  paid('paid', 'Pagado'),
  onTheWay('on_the_way', 'En camino'),
  arrived('arrived', 'Llegó'),
  inProgress('in_progress', 'En proceso'),
  awaitingConfirmation('awaiting_confirmation', 'Esperando confirmación'),
  completed('completed', 'Completado'),
  cancelled('cancelled', 'Cancelado'),
  expired('expired', 'Expirado'),
  disputed('disputed', 'En disputa'),
  unknown('unknown', 'Estado pendiente');

  const JobStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static JobStatus fromApi(Object? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => JobStatus.unknown,
  );

  bool get pollingFinished => this != searching;
  bool get active => !{completed, cancelled, expired, rejected}.contains(this);
}

final class JobModel {
  const JobModel({
    required this.id,
    this.clientId,
    this.professionalId,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    this.serviceMode,
    this.category,
    this.service,
    this.professional,
    this.city,
    this.state,
    this.scheduledFor,
    this.scheduledSlot,
    this.agreedPrice,
    this.currency,
    this.economicBreakdown,
    this.quotes = const [],
    this.payment,
    this.review,
    this.address,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.completionCode,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? clientId;
  final int? professionalId;
  final String title;
  final String description;
  final String? serviceMode;
  final JobStatus status;
  final String statusLabel;
  final CategoryModel? category;
  final ServiceModel? service;
  final ProfessionalModel? professional;
  final String? city;
  final String? state;
  final DateTime? scheduledFor;
  final String? scheduledSlot;
  final String? agreedPrice;
  final String? currency;
  final EconomicBreakdown? economicBreakdown;
  final List<JobQuoteModel> quotes;
  final PaymentModel? payment;
  final ReviewModel? review;
  final String? address;
  final String? postalCode;
  final String? latitude;
  final String? longitude;
  final String? completionCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get generalLocation =>
      [city, state].where((value) => value?.isNotEmpty == true).join(', ');

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final status = JobStatus.fromApi(json['status']);
    final privateDataAllowed = {
      JobStatus.paid,
      JobStatus.onTheWay,
      JobStatus.arrived,
      JobStatus.inProgress,
      JobStatus.awaitingConfirmation,
      JobStatus.completed,
      JobStatus.disputed,
    }.contains(status);
    return JobModel(
      id: jsonInt(json['id']),
      clientId: json['client_id'] != null ? jsonInt(json['client_id']) : null,
      professionalId: json['professional_id'] != null ? jsonInt(json['professional_id']) : null,
      title: json['title']?.toString() ?? 'Chamba',
      description: json['description']?.toString() ?? '',
      serviceMode: json['service_mode']?.toString(),
      status: status,
      statusLabel: json['status_label']?.toString() ?? status.label,
      category: json['category'] is Map
          ? CategoryModel.fromJson(jsonMap(json['category']))
          : null,
      service: json['service'] is Map
          ? ServiceModel.fromJson(jsonMap(json['service']))
          : null,
      professional: json['professional'] is Map
          ? ProfessionalModel.fromJson(jsonMap(json['professional']))
          : null,
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      scheduledFor: DateTime.tryParse(json['scheduled_for']?.toString() ?? ''),
      scheduledSlot: json['scheduled_slot']?.toString(),
      agreedPrice: json['agreed_price']?.toString(),
      currency: json['currency']?.toString(),
      economicBreakdown: json['economic_breakdown'] is Map
          ? EconomicBreakdown.fromJson(jsonMap(json['economic_breakdown']))
          : null,
      quotes: jsonList(json['quotes']).map(JobQuoteModel.fromJson).toList(),
      payment: json['payment'] is Map
          ? PaymentModel.fromJson(jsonMap(json['payment']))
          : null,
      review: json['review'] is Map
          ? ReviewModel.fromJson(jsonMap(json['review']))
          : null,
      address: privateDataAllowed ? json['address']?.toString() : null,
      postalCode: privateDataAllowed ? json['postal_code']?.toString() : null,
      latitude: privateDataAllowed ? json['latitude']?.toString() : null,
      longitude: privateDataAllowed ? json['longitude']?.toString() : null,
      completionCode: status == JobStatus.awaitingConfirmation
          ? json['completion_code']?.toString()
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

enum DisputeReason {
  incompleteWork('incomplete_work', 'Trabajo incompleto'),
  notAsAgreed('not_as_agreed', 'No coincide con lo acordado'),
  damageOrIssue('damage_or_issue', 'Daño durante el trabajo'),
  professionalAbsent('professional_absent', 'El profesional no acudió'),
  other('other', 'Otro');

  const DisputeReason(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum QuoteStatus {
  pending,
  accepted,
  rejected,
  expired,
  superseded,
  unknown;

  static QuoteStatus fromApi(Object? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => unknown);
}

final class JobQuoteModel {
  const JobQuoteModel({
    required this.id,
    required this.jobId,
    required this.professionalId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    this.economicBreakdown,
    this.expiresAt,
    this.acceptedAt,
    this.rejectedAt,
    this.createdAt,
  });
  final int id;
  final int jobId;
  final int professionalId;
  final String amount;
  final String currency;
  final String description;
  final QuoteStatus status;
  final EconomicBreakdown? economicBreakdown;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;

  factory JobQuoteModel.fromJson(Map<String, dynamic> json) => JobQuoteModel(
    id: jsonInt(json['id']),
    jobId: jsonInt(json['job_id']),
    professionalId: jsonInt(json['professional_id']),
    amount: json['amount']?.toString() ?? '0.00',
    currency: json['currency']?.toString() ?? 'MXN',
    description: json['description']?.toString() ?? '',
    status: QuoteStatus.fromApi(json['status']),
    economicBreakdown: json['economic_breakdown'] is Map
        ? EconomicBreakdown.fromJson(jsonMap(json['economic_breakdown']))
        : null,
    expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    acceptedAt: DateTime.tryParse(json['accepted_at']?.toString() ?? ''),
    rejectedAt: DateTime.tryParse(json['rejected_at']?.toString() ?? ''),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

enum PaymentStatus {
  pending,
  processing,
  approved,
  rejected,
  cancelled,
  refunded,
  partiallyRefunded,
  unknown;

  static PaymentStatus fromApi(Object? value) => switch (value) {
    'pending' => pending,
    'processing' => processing,
    'approved' => approved,
    'rejected' => rejected,
    'cancelled' => cancelled,
    'refunded' => refunded,
    'partially_refunded' => partiallyRefunded,
    _ => unknown,
  };

  bool get terminal => {
    approved,
    rejected,
    cancelled,
    refunded,
    partiallyRefunded,
  }.contains(this);
}

final class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.jobId,
    required this.status,
    required this.grossAmount,
    required this.platformFeePercent,
    required this.platformFee,
    required this.professionalAmount,
    required this.currency,
    this.economicModelVersion = 'single_platform_fee_15',
    this.baseAmount,
    this.clientServiceFeePercent,
    this.clientServiceFee,
    this.professionalCommissionPercent,
    this.professionalCommission,
    this.customerTotal,
    this.platformGrossFee,
    this.professionalAmountBeforeExternalCosts,
    this.providerFee,
    this.professionalSettlementAmount,
    this.paidAt,
  });
  final int id;
  final int jobId;
  final PaymentStatus status;
  final String grossAmount;
  final String platformFeePercent;
  final String platformFee;
  final String professionalAmount;
  final String currency;
  final String economicModelVersion;
  final String? baseAmount;
  final String? clientServiceFeePercent;
  final String? clientServiceFee;
  final String? professionalCommissionPercent;
  final String? professionalCommission;
  final String? customerTotal;
  final String? platformGrossFee;
  final String? professionalAmountBeforeExternalCosts;
  final String? providerFee;
  final String? professionalSettlementAmount;
  final DateTime? paidAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: jsonInt(json['id']),
    jobId: jsonInt(json['job_id']),
    status: PaymentStatus.fromApi(json['status']),
    grossAmount:
        json['gross_amount']?.toString() ??
        json['customer_total']?.toString() ??
        '0.00',
    platformFeePercent:
        json['platform_fee_percent']?.toString() ??
        json['professional_commission_percent']?.toString() ??
        '0.00',
    platformFee:
        json['platform_fee']?.toString() ??
        json['platform_gross_fee']?.toString() ??
        json['professional_commission']?.toString() ??
        '0.00',
    professionalAmount:
        json['professional_amount']?.toString() ??
        json['professional_amount_before_external_costs']?.toString() ??
        '0.00',
    currency: json['currency']?.toString() ?? 'MXN',
    economicModelVersion:
        json['economic_model_version']?.toString() ?? 'single_platform_fee_15',
    baseAmount: json['base_amount']?.toString(),
    clientServiceFeePercent: json['client_service_fee_percent']?.toString(),
    clientServiceFee: json['client_service_fee']?.toString(),
    professionalCommissionPercent: json['professional_commission_percent']
        ?.toString(),
    professionalCommission: json['professional_commission']?.toString(),
    customerTotal: json['customer_total']?.toString(),
    platformGrossFee: json['platform_gross_fee']?.toString(),
    professionalAmountBeforeExternalCosts:
        json['professional_amount_before_external_costs']?.toString(),
    providerFee: json['provider_fee']?.toString(),
    professionalSettlementAmount: json['professional_settlement_amount']
        ?.toString(),
    paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
  );
}

final class EconomicBreakdown {
  const EconomicBreakdown({
    required this.baseAmount,
    required this.currency,
    this.economicModelVersion,
    this.clientServiceFeePercent,
    this.clientServiceFee,
    this.professionalCommissionPercent,
    this.professionalCommission,
    this.customerTotal,
    this.platformGrossFee,
    this.professionalAmountBeforeExternalCosts,
  });

  final String baseAmount;
  final String currency;
  final String? economicModelVersion;
  final String? clientServiceFeePercent;
  final String? clientServiceFee;
  final String? professionalCommissionPercent;
  final String? professionalCommission;
  final String? customerTotal;
  final String? platformGrossFee;
  final String? professionalAmountBeforeExternalCosts;

  factory EconomicBreakdown.fromJson(Map<String, dynamic> json) =>
      EconomicBreakdown(
        baseAmount: json['base_amount']?.toString() ?? '0.00',
        currency: json['currency']?.toString() ?? 'MXN',
        economicModelVersion: json['economic_model_version']?.toString(),
        clientServiceFeePercent: json['client_service_fee_percent']?.toString(),
        clientServiceFee: json['client_service_fee']?.toString(),
        professionalCommissionPercent: json['professional_commission_percent']
            ?.toString(),
        professionalCommission: json['professional_commission']?.toString(),
        customerTotal: json['customer_total']?.toString(),
        platformGrossFee: json['platform_gross_fee']?.toString(),
        professionalAmountBeforeExternalCosts:
            json['professional_amount_before_external_costs']?.toString(),
      );
}

final class CheckoutResult {
  const CheckoutResult({required this.checkoutUrl, required this.payment});
  final String checkoutUrl;
  final PaymentModel payment;
}

final class JobStatusModel {
  const JobStatusModel({
    required this.status,
    required this.label,
    this.professional,
    this.updatedAt,
    this.expiresAt,
  });

  final JobStatus status;
  final String label;
  final ProfessionalModel? professional;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  factory JobStatusModel.fromJson(Map<String, dynamic> json) {
    final status = JobStatus.fromApi(json['status']);
    return JobStatusModel(
      status: status,
      label: json['status_label']?.toString() ?? status.label,
      professional: json['professional'] is Map
          ? ProfessionalModel.fromJson(jsonMap(json['professional']))
          : null,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}

final class JobLocationInput {
  const JobLocationInput({
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.state,
    this.postalCode,
  });
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;

  Map<String, dynamic> toJson() => {
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (address?.trim().isNotEmpty == true) 'address': address!.trim(),
    if (city?.trim().isNotEmpty == true) 'city': city!.trim(),
    if (state?.trim().isNotEmpty == true) 'state': state!.trim(),
    if (postalCode?.trim().isNotEmpty == true)
      'postal_code': postalCode!.trim(),
  };
}

final class ImmediateJobInput {
  const ImmediateJobInput({
    required this.categoryId,
    required this.description,
    required this.location,
    this.serviceId,
  });
  final int categoryId;
  final int? serviceId;
  final String description;
  final JobLocationInput location;
}

final class ScheduledJobInput {
  const ScheduledJobInput({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.location,
    required this.scheduledFor,
    required this.scheduledSlot,
    this.serviceId,
  });
  final int categoryId;
  final int? serviceId;
  final String title;
  final String description;
  final JobLocationInput location;
  final DateTime scheduledFor;
  final String scheduledSlot;
}
