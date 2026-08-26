final class AchievementModel {
  const AchievementModel({
    required this.code,
    required this.name,
    required this.level,
    required this.levelLabel,
    required this.icon,
    required this.description,
  });

  final String code;
  final String name;
  final String level;
  final String levelLabel;
  final String icon;
  final String description;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: json['level']?.toString() ?? 'bronze',
      levelLabel:
          json['level_label']?.toString() ?? json['level']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'award',
      description: json['description']?.toString() ?? '',
    );
  }
}
