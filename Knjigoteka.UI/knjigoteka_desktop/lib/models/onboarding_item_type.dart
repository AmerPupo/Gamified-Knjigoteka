enum OnboardingItemType {
  tutorial,
  mission;

  static OnboardingItemType fromInt(int value) {
    switch (value) {
      case 0:
        return OnboardingItemType.tutorial;
      case 1:
        return OnboardingItemType.mission;
      default:
        throw ArgumentError('Nepoznat OnboardingItemType: $value');
    }
  }

  int toInt() {
    switch (this) {
      case OnboardingItemType.tutorial:
        return 0;
      case OnboardingItemType.mission:
        return 1;
    }
  }
}
