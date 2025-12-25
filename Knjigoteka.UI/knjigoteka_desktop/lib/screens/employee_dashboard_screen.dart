import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_status.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import 'package:knjigoteka_desktop/providers/onboarding_provider.dart';
import 'package:knjigoteka_desktop/screens/employee_books_screen.dart';
import 'package:knjigoteka_desktop/screens/employee_loans_screen.dart';
import 'package:knjigoteka_desktop/screens/employee_sales_screen.dart';
import 'package:knjigoteka_desktop/screens/onboarding_screen.dart';
import 'package:knjigoteka_desktop/screens/settings_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 3;

  late List<Widget> _screens;

  static const List<String> _menuTitles = [
    'Prodaja',
    'Knjige',
    'Posudbe',
    'Onboarding',
    'Postavke',
  ];

  final GlobalKey _salesMenuKey = GlobalKey();
  final GlobalKey _booksMenuKey = GlobalKey();
  final GlobalKey _loansMenuKey = GlobalKey();

  TutorialCoachMark? _sidebarTutorial;
  bool _sidebarTutorialActive = false;
  String? _lastActiveItemCode;

  @override
  void initState() {
    super.initState();
    _screens = [
      EmployeeSalesScreen(),
      EmployeeBooksScreen(),
      EmployeeLoansScreen(),
      OnboardingScreen(onStartItem: _handleOnboardingStartFromDashboard),
      SettingsScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOnboardingStatus();
    });
  }

  @override
  void dispose() {
    _sidebarTutorial?.finish();
    _sidebarTutorialActive = false;
    super.dispose();
  }

  void _handleOnboardingStartFromDashboard(OnboardingItemStatus item) {
    final code = item.code;
    if (code == 'sales_tutorial_open_module' ||
        code == 'books_tutorial_open_module' ||
        code == 'borrowing_tutorial_open_module' ||
        code == 'reservations_tutorial_open_module') {
      if (_selectedIndex != 3) {
        setState(() => _selectedIndex = 3);
      }

      return;
    }
    int? targetIndex;

    if (code.startsWith('sales_')) {
      targetIndex = 0; // Prodaja
    } else if (code.startsWith('books_')) {
      targetIndex = 1; // Knjige
    } else if (code.startsWith('borrowing_')) {
      targetIndex = 2; // Posudbe
    } else if (code.startsWith('reservations_')) {
      targetIndex = 2;
    }

    if (targetIndex == null) return;

    setState(() {
      _selectedIndex = targetIndex!;
    });
  }

  Future<void> _initOnboardingStatus() async {
    final onboardingProvider = context.read<OnboardingProvider>();

    try {
      final overview = await onboardingProvider.getOverview();
      if (!mounted) return;
      setState(() {
        _selectedIndex = overview.hasCompletedOnboarding ? 0 : 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = 3;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri učitavanju onboardinga: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();

    if (_lastActiveItemCode != onboarding.activeItemCode) {
      _lastActiveItemCode = onboarding.activeItemCode;
      _sidebarTutorialActive = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartOpenModuleSidebarTutorial(onboarding);
    });

    if (onboarding.shouldShowOnboardingDashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_selectedIndex != 3) {
          setState(() => _selectedIndex = 3);
        }

        onboarding.clearShowOnboardingDashboardRequest();
      });
    }

    final bool onboardingDone = onboarding.hasCompletedOnboarding;

    final List<int> visibleIndices = [];

    if (onboardingDone) {
      visibleIndices.addAll([0, 1, 2, 3, 4]);
    } else {
      if (onboarding.showSalesIcon) {
        visibleIndices.add(0);
      }
      if (onboarding.showInventoryIcon) {
        visibleIndices.add(1);
      }
      if (onboarding.showLoansIcon) {
        visibleIndices.add(2);
      }
      visibleIndices.add(3);
      visibleIndices.add(4);
    }

    if (!visibleIndices.contains(_selectedIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!visibleIndices.contains(_selectedIndex)) {
          setState(() => _selectedIndex = 3);
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: const Color(0xFF233348),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Knjigoteka',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ...visibleIndices.map((idx) {
                  final bool selected = _selectedIndex == idx;
                  final bool enabled = _isIndexEnabled(idx, onboarding);

                  final Key? menuKey;
                  if (idx == 0) {
                    menuKey = _salesMenuKey;
                  } else if (idx == 1) {
                    menuKey = _booksMenuKey;
                  } else if (idx == 2) {
                    menuKey = _loansMenuKey;
                  } else {
                    menuKey = null;
                  }

                  return Opacity(
                    opacity: enabled ? 1.0 : 0.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4,
                      ),
                      child: Material(
                        color: selected
                            ? Colors.white.withOpacity(0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _onMenuTap(idx, onboarding),
                          child: Container(
                            decoration: selected
                                ? BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1.2,
                                    ),
                                  )
                                : null,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Row(
                              key: menuKey,
                              children: [
                                _getSidebarIcon(idx, selected),
                                const SizedBox(width: 14),
                                Text(
                                  _menuTitles[idx],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                const Divider(color: Colors.white30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white70),
                    title: const Text(
                      'Odjavi se',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              const Expanded(child: Text('Odjavi se?')),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx, false),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Da li ste sigurni da se želite odjaviti?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Odustani'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Odjavi se'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await context.read<AuthProvider>().logout();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F6FA),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  void _onMenuTap(int idx, OnboardingProvider onboarding) {
    final hasCompleted = onboarding.hasCompletedOnboarding;

    if (hasCompleted) {
      setState(() => _selectedIndex = idx);
      return;
    }

    if (idx == 3 || idx == 4) {
      setState(() => _selectedIndex = idx);
      return;
    }

    if (idx == 0) {
      if (onboarding.canClickSales) {
        setState(() => _selectedIndex = 0);
      } else {
        _showLockedSnack();
      }
      return;
    }

    if (idx == 1) {
      if (onboarding.canClickInventory) {
        setState(() => _selectedIndex = 1);
      } else {
        _showLockedSnack();
      }
      return;
    }

    if (idx == 2) {
      if (onboarding.canClickLoans) {
        setState(() => _selectedIndex = 2);
      } else {
        _showLockedSnack();
      }
      return;
    }
  }

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ovaj modul je dostupan samo tokom aktivnog tutorijala ili misije.',
        ),
      ),
    );
  }

  bool _isIndexEnabled(int idx, OnboardingProvider onboarding) {
    if (onboarding.hasCompletedOnboarding) return true;

    switch (idx) {
      case 0:
        return onboarding.canClickSales;
      case 1:
        return onboarding.canClickInventory;
      case 2:
        return onboarding.canClickLoans;
      case 3:
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _maybeStartOpenModuleSidebarTutorial(OnboardingProvider onboarding) {
    if (_selectedIndex != 3) return;

    if (_sidebarTutorialActive) return;

    final code = onboarding.activeItemCode;

    if (code != 'sales_tutorial_open_module' &&
        code != 'books_tutorial_open_module' &&
        code != 'borrowing_tutorial_open_module' &&
        code != 'reservations_tutorial_open_module') {
      return;
    }

    GlobalKey targetKey;
    bool iconVisible;
    int targetIndex;
    String title;
    String body;

    if (code == 'sales_tutorial_open_module') {
      targetKey = _salesMenuKey;
      iconVisible = onboarding.showSalesIcon;
      targetIndex = 0;
      title = 'Modul Prodaja';
      body =
          'Klikni ovdje da otvoriš modul Prodaja. '
          'Na sljedećem ekranu pokazaćemo ti pretragu i listu naslova sa zalihama.';
    } else if (code == 'books_tutorial_open_module') {
      targetKey = _booksMenuKey;
      iconVisible = onboarding.showInventoryIcon;
      targetIndex = 1;
      title = 'Modul Knjige';
      body =
          'Klikni ovdje da otvoriš modul Knjige. '
          'Na sljedećem ekranu pokazaćemo ti pretragu i listu naslova sa zalihama.';
    } else if (code == 'borrowing_tutorial_open_module') {
      targetKey = _loansMenuKey;
      iconVisible = onboarding.showLoansIcon;
      targetIndex = 2;
      title = 'Modul Posudbe';
      body =
          'Klikni ovdje da otvoriš modul Posudbe. '
          'Na sljedećem ekranu pokazaćemo ti pretragu i listu posudbi.';
    } else {
      targetKey = _loansMenuKey;
      iconVisible = onboarding.showLoansIcon;
      targetIndex = 2;
      title = 'Modul Rezervacije';
      body = 'Klikni ovdje da otvoriš modul Posudbe. ';
    }

    if (!iconVisible) return;

    if (targetKey.currentContext == null) return;

    _sidebarTutorialActive = true;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: code,
        keyTarget: targetKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 0,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ];

    _sidebarTutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        setState(() {
          _selectedIndex = targetIndex;
        });
      },
      onSkip: () {
        setState(() {
          _selectedIndex = targetIndex;
        });
        return true;
      },
    )..show(context: context);
  }

  Icon _getSidebarIcon(int idx, bool selected) {
    final Color iconColor = selected ? Colors.amberAccent : Colors.white;

    switch (idx) {
      case 0:
        return Icon(Icons.point_of_sale, color: iconColor);
      case 1:
        return Icon(Icons.book, color: iconColor);
      case 2:
        return Icon(Icons.swap_horiz, color: iconColor);
      case 3:
        return Icon(Icons.rocket_launch, color: iconColor);
      case 4:
        return Icon(Icons.settings, color: iconColor);
      default:
        return Icon(Icons.circle, color: iconColor);
    }
  }
}
