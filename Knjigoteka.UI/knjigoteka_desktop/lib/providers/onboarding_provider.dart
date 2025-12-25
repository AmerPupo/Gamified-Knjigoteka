import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:knjigoteka_desktop/main.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_status.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_type.dart';
import 'package:knjigoteka_desktop/models/onboarding_overview.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';

class OnboardingProvider with ChangeNotifier {
  static const String _baseUrl = String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );

  // Pregled onboarding statusa sa backend-a
  OnboardingOverview? _overview;
  OnboardingOverview? get overview => _overview;
  bool get hasCompletedOnboarding => _overview?.hasCompletedOnboarding ?? false;

  // Za redirect na onboarding dashboard
  bool _shouldShowOnboardingDashboard = false;
  bool get shouldShowOnboardingDashboard => _shouldShowOnboardingDashboard;

  // Aktivni tutorijal/misija
  String? _activeItemCode;
  String? get activeItemCode => _activeItemCode;

  final AuthProvider _auth;

  OnboardingProvider(this._auth);

  // --- Helpers za čitanje statusa itema ---

  OnboardingItemStatus? getItemStatus(String code) {
    final items = _overview?.items ?? [];
    try {
      return items.firstWhere((x) => x.code == code);
    } catch (_) {
      return null;
    }
  }

  bool _isItemCompleted(String code) {
    final status = getItemStatus(code);
    return status?.isCompleted ?? false;
  }

  // --- Sidebar ikonice: vidljivost i klikabilnost ---

  bool _shouldShowModuleIcon(String openCode) {
    if (hasCompletedOnboarding) return true;
    return _isItemCompleted(openCode) || _activeItemCode == openCode;
  }

  bool _canClickForPrefixes(List<String> prefixes) {
    if (hasCompletedOnboarding) return true;
    final code = _activeItemCode ?? '';
    return prefixes.any((p) => code.startsWith(p));
  }

  bool get showSalesIcon => _shouldShowModuleIcon('sales_tutorial_open_module');

  bool get showInventoryIcon =>
      _shouldShowModuleIcon('books_tutorial_open_module');

  bool get showLoansIcon =>
      _shouldShowModuleIcon('borrowing_tutorial_open_module');

  bool get canClickSales => _canClickForPrefixes(['sales_']);

  bool get canClickInventory => _canClickForPrefixes(['books_']);

  bool get canClickLoans =>
      _canClickForPrefixes(['borrowing_', 'reservations_']);

  // --- Sandbox scenariji (itemi koji idu preko mock podataka) ---

  bool get isSandboxScenario {
    const sandboxCodes = {
      'sales_tutorial_open_module',
      'sales_tutorial_search',
      'sales_tutorial_add_to_cart',
      'sales_tutorial_availability',
      'sales_tutorial_finalize_sale',
      'sales_mission_basic_sale',
      'sales_mission_multi_sale',
      'sales_mission_check_availability',
      'sales_mission_quantity_availability',
      'books_tutorial_open_module',
      'books_mission_restock_two_copies',
      'borrowing_tutorial_open_module',
      'borrowing_mission_mark_returned',
      'reservations_tutorial_open_module',
      'reservations_mission_mark_done',
    };

    return sandboxCodes.contains(activeItemCode);
  }

  // --- Upravljanje aktivnim itemom ---

  void startItem(String itemCode) {
    _activeItemCode = itemCode;
    notifyListeners();
  }

  void clearActiveItem() {
    _activeItemCode = null;
    _auth.disableSandboxMode();
    notifyListeners();
  }

  // --- Onboarding dashboard redirect flag ---

  void requestShowOnboardingDashboard() {
    _shouldShowOnboardingDashboard = true;
    notifyListeners();
  }

  void clearShowOnboardingDashboardRequest() {
    _shouldShowOnboardingDashboard = false;
  }
  // --- Popup tracking (samo u memoriji aplikacije) ---

  final Set<String> _shownBadgeIds = {};
  Set<String> get shownBadgeIds => _shownBadgeIds;

  bool _onboardingCompletionPopupShown = false;
  bool get onboardingCompletionPopupShown => _onboardingCompletionPopupShown;

  void markBadgeAsShown(String badgeId) {
    _shownBadgeIds.add(badgeId);
  }

  void markOnboardingCompletionPopupShown() {
    _onboardingCompletionPopupShown = true;
  }
  // --- HTTP helperi ---

  Map<String, String> _headers() {
    final token = AuthProvider.token;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _get(String path) {
    return http.get(Uri.parse('$_baseUrl$path'), headers: _headers());
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  // --- API pozivi: overview & statusi ---

  Future<OnboardingOverview> getOverview() async {
    final res = await _get('/Onboarding/overview');
    _ensureValidResponseOrThrow(res);

    final Map<String, dynamic> data = jsonDecode(res.body);
    _overview = OnboardingOverview.fromJson(data);

    print("ovo je overview: $data u onboarding_provider");
    notifyListeners();
    return _overview!;
  }

  Future<void> markCompleted(
    String itemCode,
    OnboardingItemType itemType,
  ) async {
    final res = await _post('/Onboarding/complete', {
      'itemCode': itemCode,
      'itemType': itemType.toInt(),
    });

    _ensureValidResponseOrThrow(res);
    await getOverview();
  }

  Future<OnboardingItemStatus> registerAttempt(
    String itemCode,
    OnboardingItemType itemType, {
    required bool success,
  }) async {
    final res = await _post('/Onboarding/attempt', {
      'itemCode': itemCode,
      'itemType': itemType.toInt(),
      'success': success,
    });

    _ensureValidResponseOrThrow(res);

    final Map<String, dynamic> data = jsonDecode(res.body);
    final status = OnboardingItemStatus.fromJson(data);

    await getOverview();

    return status;
  }

  Future<OnboardingItemStatus> registerMissionFailure(
    String itemCode,
    OnboardingItemType itemType,
  ) async {
    final status = await registerAttempt(itemCode, itemType, success: false);

    if (!status.hintShown && status.attempts == 1) {
      await markHintShown(itemCode, itemType);
    }

    return getItemStatus(itemCode) ?? status;
  }

  Future<OnboardingItemStatus> markHintShown(
    String itemCode,
    OnboardingItemType itemType,
  ) async {
    final res = await _post('/Onboarding/hint-shown', {
      'itemCode': itemCode,
      'itemType': itemType.toInt(),
    });

    _ensureValidResponseOrThrow(res);

    final Map<String, dynamic> data = jsonDecode(res.body);
    final status = OnboardingItemStatus.fromJson(data);

    await getOverview();
    return status;
  }

  // --- Error handling za HTTP pozive ---

  void _ensureValidResponseOrThrow(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 401) {
      _auth.logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);

      throw Exception("Session expired. Please login again.");
    }

    String msg = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'];
      }
    } catch (_) {}

    throw Exception("Error ${res.statusCode}: $msg");
  }
}
