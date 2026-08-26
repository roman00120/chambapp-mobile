final class UserReport {
  const UserReport({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.status,
    required this.createdAt,
    this.reportedUserId,
    this.reportedUserName,
  });

  final int id;
  final String category;
  final String categoryLabel;
  final String status;
  final DateTime createdAt;
  final int? reportedUserId;
  final String? reportedUserName;

  factory UserReport.fromJson(Map<String, dynamic> json) {
    final reported = json['reported_user'] as Map<String, dynamic>?;
    return UserReport(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      category: json['category']?.toString() ?? '',
      categoryLabel:
          json['category_label']?.toString() ??
          json['category']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'submitted',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      reportedUserId: reported != null && reported['id'] != null
          ? int.tryParse(reported['id'].toString())
          : null,
      reportedUserName: reported?['name']?.toString(),
    );
  }
}

final class DisciplinaryActionModel {
  const DisciplinaryActionModel({
    required this.id,
    required this.actionType,
    required this.actionTypeLabel,
    required this.severity,
    required this.reasonText,
    required this.status,
    required this.statusLabel,
    required this.issuedAt,
    required this.isActive,
    this.expiresAt,
    this.appeal,
  });

  final int id;
  final String actionType;
  final String actionTypeLabel;
  final String severity;
  final String reasonText;
  final String status;
  final String statusLabel;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DisciplinaryAppealModel? appeal;

  factory DisciplinaryActionModel.fromJson(Map<String, dynamic> json) {
    return DisciplinaryActionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      actionType: json['action_type']?.toString() ?? '',
      actionTypeLabel:
          json['action_type_label']?.toString() ??
          json['action_type']?.toString() ??
          '',
      severity: json['severity']?.toString() ?? 'low',
      reasonText: json['reason_text']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      statusLabel:
          json['status_label']?.toString() ?? json['status']?.toString() ?? '',
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'].toString())
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : null,
      isActive: json['is_active'] == true,
      appeal: json['appeal'] != null
          ? DisciplinaryAppealModel.fromJson(
              json['appeal'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

final class DisciplinaryAppealModel {
  const DisciplinaryAppealModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final String status;
  final String statusLabel;
  final DateTime createdAt;

  factory DisciplinaryAppealModel.fromJson(Map<String, dynamic> json) {
    return DisciplinaryAppealModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      status: json['status']?.toString() ?? 'submitted',
      statusLabel:
          json['status_label']?.toString() ?? json['status']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}
