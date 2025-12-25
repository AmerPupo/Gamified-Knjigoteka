import 'onboarding_item_type.dart';

class OnboardingItemStatus {
  final String code;
  final String name;
  final String description;
  final OnboardingItemType itemType;
  final int order;
  final bool isCompleted;
  final int attempts;
  final bool hintShown;
  final List<String> requiredItemCodes;

  OnboardingItemStatus({
    required this.code,
    required this.name,
    required this.description,
    required this.itemType,
    required this.order,
    required this.isCompleted,
    required this.attempts,
    required this.hintShown,
    required this.requiredItemCodes,
  });

  factory OnboardingItemStatus.fromJson(Map<String, dynamic> json) {
    final rawReq = json['requiredItemCodes'] as List<dynamic>? ?? [];
    return OnboardingItemStatus(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      itemType: OnboardingItemType.fromInt(json['itemType'] as int),
      order: json['order'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 0,
      hintShown: json['hintShown'] as bool? ?? false,
      requiredItemCodes: rawReq.map((e) => e.toString()).toList(),
    );
  }
}
