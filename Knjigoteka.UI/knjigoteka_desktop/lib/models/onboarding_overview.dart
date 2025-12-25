import 'onboarding_item_status.dart';

class OnboardingOverview {
  final bool hasCompletedOnboarding;
  final List<OnboardingItemStatus> items;

  OnboardingOverview({
    required this.hasCompletedOnboarding,
    required this.items,
  });

  factory OnboardingOverview.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return OnboardingOverview(
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      items: itemsJson
          .map((e) => OnboardingItemStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
