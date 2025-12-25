import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_type.dart';
import 'package:knjigoteka_desktop/providers/onboarding_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/book_provider.dart';
import '../models/branch_inventory.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/sale_provider.dart';
import '../models/sale_insert.dart';

class EmployeeSalesScreen extends StatefulWidget {
  @override
  State<EmployeeSalesScreen> createState() => _EmployeeSalesScreenState();
}

class _EmployeeSalesScreenState extends State<EmployeeSalesScreen> {
  List<Book> _allBooks = [];
  Map<int, BranchInventory> _branchInventoryMap = {};
  Map<int, int> _cart = {};
  bool _loading = false;
  String _search = '';

  // ključevi za tutorijale
  final GlobalKey _searchFieldKey = GlobalKey();
  final GlobalKey _resultsListKey = GlobalKey();
  final GlobalKey _cartButtonKey = GlobalKey();
  final GlobalKey _bookImageKey = GlobalKey();
  final GlobalKey _bookInfoKey = GlobalKey();
  final GlobalKey _bookPriceKey = GlobalKey();
  final GlobalKey _bookAvailabilityButtonKey = GlobalKey();
  final GlobalKey _bookAddButtonKey = GlobalKey();
  final GlobalKey _bookCartControlsKey = GlobalKey();
  final GlobalKey _cartTitleKey = GlobalKey();
  final GlobalKey _cartItemsKey = GlobalKey();
  final GlobalKey _cartTotalKey = GlobalKey();
  final GlobalKey _cartFinalizeButtonKey = GlobalKey();
  final GlobalKey _availabilityDialogListKey = GlobalKey();
  final GlobalKey _availabilityDialogRowKey = GlobalKey();

  bool _availabilityDialogCoachStarted = false;
  bool _searchTutorialWaitingForInput = false;
  bool _searchDetailsTutorialActive = false;
  bool _addToCartFlowActive = false;
  bool _addToCartWaitingForInput = false;
  bool _availabilityFlowActive = false;
  bool _availabilityWaitingForInput = false;

  bool _finalizeFlowActive = false;
  bool _finalizeWaitingForCartItem = false;
  int? _tutorialBookId;
  TutorialCoachMark? _tutorial;
  final TextEditingController _searchController = TextEditingController();
  static const String _missionBasicSaleCode = 'sales_mission_basic_sale';
  static const String _missionMultiSaleCode = 'sales_mission_multi_sale';
  static const String _missionAvailabilityCode =
      'sales_mission_check_availability';
  static const String _missionQuantityAvailabilityCode =
      'sales_mission_quantity_availability';
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );

  @override
  void initState() {
    super.initState();
    _fetchData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboarding = context.read<OnboardingProvider>();
      final code = onboarding.activeItemCode;
      switch (code) {
        case 'sales_tutorial_open_module':
          _handleOpenModuleTutorial(onboarding);
          break;
        case 'sales_tutorial_search':
          _startSearchTutorial(onboarding);
          break;
        case 'sales_tutorial_add_to_cart':
          _startAddToCartTutorial(onboarding);
          break;
        case 'sales_tutorial_availability':
          _startAvailabilityTutorial(onboarding);
          break;
        case 'sales_tutorial_finalize_sale':
          _startFinalizeSaleTutorial(onboarding);
          break;
        case 'sales_mission_basic_sale':
          _showMissionIntroDialog();
          break;
        case 'sales_mission_multi_sale':
          _showMultiMissionIntroDialog();
          break;
        case 'sales_mission_check_availability':
          _showAvailabilityMissionIntroDialog();
          break;
        case 'sales_mission_quantity_availability':
          _showQuantityAvailabilityMissionIntroDialog();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tutorial = null;
    _searchController.dispose();
    super.dispose();
  }

  Book? _findMissionTargetBook() {
    try {
      return _allBooks.firstWhere(
        (b) => b.title.trim().toLowerCase() == 'na drini ćuprija',
      );
    } catch (_) {
      return null;
    }
  }

  bool _isBasicSaleMissionSuccess() {
    final target = _findMissionTargetBook();
    if (target == null) return false;

    if (_cart.length != 1) return false;
    final qty = _cart[target.id] ?? 0;
    return qty == 1;
  }

  bool _isMultiSaleMissionSuccess() {
    final distinctTitlesCount = _cart.length;

    final totalQty = _cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return distinctTitlesCount >= 2 && totalQty >= 3;
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() => _loading = true);

    List<Book> allBooks = [];
    Map<int, BranchInventory> branchMap = {};

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final branchId = auth.effectiveBranchId!;
      final isSandbox = auth.sandboxMode;
      allBooks = await Provider.of<BookProvider>(
        context,
        listen: false,
      ).getBooks(fts: _search, sandbox: isSandbox);
      final branchBooks = await Provider.of<BranchInventoryProvider>(
        context,
        listen: false,
      ).getAvailableForSale(branchId, fts: _search, sandbox: isSandbox);
      branchMap = {for (var b in branchBooks) b.bookId: b};
    } catch (e) {
      allBooks = [];
      branchMap = {};
    }

    if (!mounted) return;

    setState(() {
      _allBooks = allBooks;
      _branchInventoryMap = branchMap;
      _loading = false;
    });
    _maybeStartSearchDetailsTutorial();
    _maybeStartAddToCartBookPhase();
    _maybeStartAvailabilityPhase();
  }

  void _showCart({bool barrierDismissible = true}) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
              minWidth: 320,
              maxHeight: 400,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xfffaf5fb),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _cart.isEmpty
                        ? const Center(child: Text("Korpa je prazna."))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Izabrane knjige",
                                key: _cartTitleKey,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),

                              Column(
                                key: _cartItemsKey,
                                mainAxisSize: MainAxisSize.min,
                                children: _cart.entries.map((e) {
                                  final b = _allBooks.firstWhere(
                                    (bk) => bk.id == e.key,
                                  );
                                  final inv = _branchInventoryMap[e.key];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                "${b.author} • ${b.genreName}",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${e.value} x ${inv?.price.toStringAsFixed(2) ?? '0.00'} KM",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const Divider(),
                              Padding(
                                key: _cartTotalKey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Ukupno:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_total.toStringAsFixed(2)} KM",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  key: _cartFinalizeButtonKey,
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _finalizeSale();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(170, 40),
                                  ),
                                  child: const Text("Finaliziraj prodaju"),
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addToCart(int bookId, int max) {
    setState(() {
      if (!_cart.containsKey(bookId)) _cart[bookId] = 1;
    });
    final onboarding = context.read<OnboardingProvider>();
    if (onboarding.activeItemCode == 'sales_tutorial_add_to_cart' &&
        _addToCartFlowActive &&
        _tutorialBookId == bookId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAddToCartCoachMarkOnCartControls(onboarding);
      });
    }
    if (onboarding.activeItemCode == 'sales_tutorial_finalize_sale' &&
        _finalizeFlowActive &&
        _finalizeWaitingForCartItem &&
        _cart.isNotEmpty) {
      _finalizeWaitingForCartItem = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startFinalizeSaleCoachMarkOnCartFab(onboarding);
      });
    }
  }

  void _updateCart(int bookId, int value, int max) {
    setState(() {
      if (value > 0 && value <= max) {
        _cart[bookId] = value;
      } else if (value == 0) {
        _cart.remove(bookId);
      }
    });
  }

  Future<void> _finalizeSale() async {
    if (_cart.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final onboarding = context.read<OnboardingProvider>();

    final employeeId = auth.userId!;
    final branchId = auth.effectiveBranchId!;
    final isSandbox = auth.sandboxMode;
    final String? activeCode = onboarding.activeItemCode;
    String? activeMissionCode;
    bool missionSuccess = false;

    if (activeCode == _missionBasicSaleCode) {
      activeMissionCode = _missionBasicSaleCode;
      missionSuccess = _isBasicSaleMissionSuccess();
    } else if (activeCode == _missionMultiSaleCode) {
      activeMissionCode = _missionMultiSaleCode;
      missionSuccess = _isMultiSaleMissionSuccess();
    }

    if (isSandbox) {
      if (activeMissionCode != null && !missionSuccess) {
        final status = await onboarding.registerMissionFailure(
          activeMissionCode,
          OnboardingItemType.mission,
        );

        final msg = status.attempts == 1
            ? "Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu."
            : "Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).";

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      setState(() {
        _cart.clear();
      });

      if (activeMissionCode != null) {
        await onboarding.markCompleted(
          activeMissionCode,
          OnboardingItemType.mission,
        );

        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        if (activeMissionCode == _missionBasicSaleCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bravo! Uspješno si završio/la misiju: 1 primjerak knjige „Na Drini ćuprija“ (sandbox simulacija).',
              ),
            ),
          );
        } else if (activeMissionCode == _missionMultiSaleCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bravo! Uspješno si završio/la misiju: najmanje 2 naslova i 3 knjige ukupno (sandbox simulacija).',
              ),
            ),
          );
        }

        return;
      }

      if (onboarding.activeItemCode == 'sales_tutorial_finalize_sale') {
        await onboarding.markCompleted(
          'sales_tutorial_finalize_sale',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
        setState(() {
          _finalizeFlowActive = false;
          _finalizeWaitingForCartItem = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tutorijal „Finalizacija prodaje“ je završen (sandbox simulacija, prodaja nije stvarno snimljena).',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prodaja uspješno simulirana u sandbox modu (bez slanja na backend).',
            ),
          ),
        );
      }

      return;
    }

    if (activeMissionCode != null && !missionSuccess) {
      final status = await onboarding.registerMissionFailure(
        activeMissionCode,
        OnboardingItemType.mission,
      );

      final msg = status.attempts == 1
          ? "Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu."
          : "Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final items = _cart.entries
        .map((e) => SaleItemInsert(bookId: e.key, quantity: e.value))
        .toList();

    try {
      await Provider.of<SaleProvider>(context, listen: false).createSale(
        SaleInsert(
          employeeId: employeeId,
          branchId: branchId,
          items: items,
        ).toJson(),
      );

      setState(() {
        _cart.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prodaja uspješna!')));

      _fetchData();

      if (activeMissionCode != null) {
        await onboarding.markCompleted(
          activeMissionCode,
          OnboardingItemType.mission,
        );

        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        if (activeMissionCode == _missionBasicSaleCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bravo! Uspješno si završio/la misiju: 1 primjerak knjige „Na Drini ćuprija“.',
              ),
            ),
          );
        } else if (activeMissionCode == _missionMultiSaleCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bravo! Uspješno si završio/la misiju: najmanje 2 naslova i 3 knjige ukupno.',
              ),
            ),
          );
        }
      }

      if (onboarding.activeItemCode == 'sales_tutorial_finalize_sale') {
        await onboarding.markCompleted(
          'sales_tutorial_finalize_sale',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
        setState(() {
          _finalizeFlowActive = false;
          _finalizeWaitingForCartItem = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorijal „Finalizacija prodaje“ je završen.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri finaliziranju prodaje: $e')),
      );
    }
  }

  Future<void> _showQuantityAvailabilityMissionIntroDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Misija: 5 primjeraka u jednoj poslovnici"),
        content: const Text(
          "Kupac želi kupiti 5 primjeraka knjige „Zločin i kazna“.\n\n"
          "Njega ne zanima u kojoj poslovnici će ih kupiti — bitno je da u jednoj "
          "može odjednom uzeti svih 5.\n\n"
          "Tvoj zadatak je da u listi dostupnosti pronađeš poslovnicu koja ima "
          "najmanje 5 primjeraka za prodaju.\n\n",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kreni"),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuantityAvailabilityMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_missionQuantityAvailabilityCode);
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (!hintShown) {
      title = "Hint";
      body =
          "Kada otvoriš dijalog „Dostupnost“, fokusiraj se na kolonu "
          "„Za prodaju“.\n\n"
          "Tebi treba poslovnica koja ima 5 ili više primjeraka.\n"
          "Pogledaj sve poslovnice i pronađi onu s dovoljno zaliha.";
      showMoreButton = true;
    } else {
      title = "Detaljno uputstvo";
      body =
          "1. U pretragu upiši „Zločin i kazna“.\n"
          "2. Na kartici knjige klikni na dugme „Dostupnost“.\n"
          "3. U listi poslovnica pregledaj količine „Za prodaju“.\n"
          "4. Pronađi poslovnicu gdje je vrijednost „Za prodaju“ ≥ 5.\n"
          "5. Kada to uradiš, misija će se automatski označiti kao uspješna.\n\n"
          "Cilj je samo identifikacija prave poslovnice — ne finaliziranje prodaje.";
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            if (showMoreButton)
              TextButton(
                onPressed: () async {
                  await onboarding.markHintShown(
                    _missionQuantityAvailabilityCode,
                    OnboardingItemType.mission,
                  );
                  Navigator.pop(ctx);
                  _showQuantityAvailabilityMissionHintDialog();
                },
                child: const Text("Prikaži detaljnije uputstvo"),
              ),
            TextButton(
              onPressed: () {
                onboarding.clearActiveItem();
                onboarding.requestShowOnboardingDashboard();

                Navigator.pop(ctx);
              },
              child: const Text("Prekini misiju"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Zatvori"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAvailabilityMissionIntroDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Misija: Provjera dostupnosti u drugim poslovnicama"),
        content: const Text(
          "Kupac želi kupiti knjigu \"Mali princ\", ali je trenutno nema "
          "u ovoj poslovnici.\n\n"
          "Kupac je spreman posjetiti bilo koju drugu poslovnicu samo da dođe do knjige.\n\n"
          "Ako zapneš, možeš koristiti ikonu sijalice u donjem lijevom uglu za hint.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kreni"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvailabilityMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_missionAvailabilityCode);
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (!hintShown) {
      title = "Hint";
      body =
          "Kupac je spreman otići u bilo koju poslovnicu, što znači da nije važno "
          "da li knjiga postoji baš u tvojoj poslovnici.\n\n"
          "Pogledaj karticu tražene knjige: ako vidiš oznaku „Nije dostupno“, "
          "razmisli koje dugme ti daje uvid u druge poslovnice i njihove količine.";
      showMoreButton = true;
    } else {
      title = "Detaljno uputstvo";
      body =
          "1. Preko pretrage pronađi traženu knjigu.\n"
          "2. Na kartici knjige primijeti oznaku „Nije dostupno“ za tvoju poslovnicu.\n"
          "3. Klikni na dugme „Dostupnost“ na kartici.\n"
          "4. U dijalogu se prikazuju sve poslovnice i količine za prodaju/iznajmljivanje.\n"
          "5. Kupcu možeš preporučiti onu poslovnicu koja ima bar jedan primjerak za prodaju.\n\n"
          "Ovim koracima si ispunio/la misiju – cilj nije prodaja, nego provjera dostupnosti.";
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            if (showMoreButton)
              TextButton(
                onPressed: () async {
                  await onboarding.markHintShown(
                    _missionAvailabilityCode,
                    OnboardingItemType.mission,
                  );
                  Navigator.pop(ctx);
                  _showAvailabilityMissionHintDialog();
                },
                child: const Text("Prikaži detaljnije uputstvo"),
              ),
            TextButton(
              onPressed: () {
                onboarding.clearActiveItem();
                onboarding.requestShowOnboardingDashboard();

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Misija je prekinuta.")),
                );
              },
              child: const Text("Prekini misiju"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Zatvori"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMultiMissionIntroDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Misija: Više naslova"),
        content: const Text(
          "Kupac želi kupiti nekoliko knjiga:\n\n"
          "• najmanje 2 različita naslova,\n"
          "• najmanje 3 knjige ukupno.\n\n"
          "Pokušaj samostalno da napraviš takvu kombinaciju u korpi.\n"
          "Ako zapneš, klikni na ikonu sijalice u donjem lijevom uglu za hint.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kreni"),
          ),
        ],
      ),
    );
  }

  Future<void> _showMultiMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_missionMultiSaleCode);
    final attempts = status?.attempts ?? 0;
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (attempts == 0) {
      title = "Opis misije";
      body =
          "Zadatak je da napraviš račun sa:\n\n"
          "• najmanje 2 različita naslova,\n"
          "• najmanje 3 knjige ukupno.\n\n"
          "Kombinaciju naslova i količina biraš sam/a.";
    } else if (attempts == 1 && !hintShown) {
      title = "Hint";
      body =
          "Pogledaj trenutnu korpu i razmisli:\n\n"
          "• imaš li barem 2 različita naslova?\n"
          "• da li je zbroj količina svih stavki najmanje 3?\n\n"
          "Ako imaš samo jedan naslov ili ukupno 1–2 knjige, dodaj još naslova ili još kopija.";
      showMoreButton = true;
    } else {
      title = "Detaljno uputstvo";
      body =
          "1. Odaberi prvu knjigu iz liste i dodaj je u korpu (1 ili više komada).\n"
          "2. Odaberi drugu knjigu (drugačiji naslov) i dodaj je u korpu.\n"
          "3. Po želji dodaj još kopija bilo koje od knjiga.\n"
          "4. U donjem desnom uglu otvori korpu i provjeri:\n"
          "   • da imaš barem 2 različita naslova u listi,\n"
          "   • da je zbroj količina svih stavki minstens 3.\n"
          "5. Kada uslovi važe, klikni na „Finaliziraj prodaju“.\n\n"
          "Ako i dalje ne prolazi, još jednom provjeri broj naslova i ukupnu količinu.";
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            if (showMoreButton)
              TextButton(
                onPressed: () async {
                  await onboarding.markHintShown(
                    _missionMultiSaleCode,
                    OnboardingItemType.mission,
                  );
                  Navigator.pop(ctx);
                  _showMultiMissionHintDialog();
                },
                child: const Text("Prikaži detaljnije uputstvo"),
              ),
            TextButton(
              onPressed: () {
                onboarding.clearActiveItem();
                onboarding.requestShowOnboardingDashboard();

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Misija je prekinuta.")),
                );
              },
              child: const Text("Prekini misiju"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Zatvori"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMissionIntroDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Misija: Prva prodaja"),
        content: const Text(
          "Kupac želi kupiti jedan primjerak knjige „Na Drini ćuprija“.\n\n"
          "Pokušaj samostalno da razmisliš kojim koracima dolaziš do toga na ovom ekranu.\n"
          "Ako zaglaviš, uvijek možeš kliknuti na ikonu sijalice u donjem lijevom uglu za hint.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kreni"),
          ),
        ],
      ),
    );
  }

  Future<void> _showMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_missionBasicSaleCode);
    final attempts = status?.attempts ?? 0;
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (attempts == 0) {
      title = "Opis misije";
      body =
          "Kupac želi kupiti jedan primjerak knjige „Na Drini ćuprija“.\n\n"
          "Pokušaj samostalno da razmisliš kojim koracima dolaziš do toga na ovom ekranu.";
    } else if (attempts == 1 && !hintShown) {
      title = "Hint";
      body =
          "Razmisli kojim redoslijedom inače praviš prodaju:\n\n"
          "• pronađeš knjigu preko pretrage,\n"
          "• dodaš je u korpu,\n"
          "• tek onda finaliziraš prodaju.\n\n"
          "Za ovu misiju fokus je na tačnom naslovu i tačno jednoj kopiji.";
      showMoreButton = true;
    } else {
      title = "Detaljno uputstvo";
      body =
          "1. U polje za pretragu upiši tačan naziv knjige: „Na Drini ćuprija“.\n"
          "2. U listi knjiga pronađi odgovarajuću karticu (sandbox verzija).\n"
          "3. Klikni na „Dodaj“ da dodaš TAČNO 1 primjerak u korpu.\n"
          "4. Klikni na ikonu korpe u donjem desnom uglu da otvoriš pregled.\n"
          "5. Provjeri da je u korpi samo ta knjiga i samo 1 komad.\n"
          "6. Klikni na „Finaliziraj prodaju“ i potvrdi.\n\n"
          "Ako sve uradiš ovako, misija će biti označena kao uspješno završena.";
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            if (showMoreButton)
              TextButton(
                onPressed: () async {
                  await onboarding.markHintShown(
                    _missionBasicSaleCode,
                    OnboardingItemType.mission,
                  );
                  Navigator.pop(ctx);
                  _showMissionHintDialog();
                },
                child: const Text("Prikaži detaljnije uputstvo"),
              ),
            TextButton(
              onPressed: () {
                onboarding.clearActiveItem();
                onboarding.requestShowOnboardingDashboard();

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Misija je prekinuta.")),
                );
              },
              child: const Text("Prekini misiju"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Zatvori"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleOpenModuleTutorial(OnboardingProvider onboarding) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dobrodošli u modul Prodaja"),
        content: const Text(
          "Ovo je ekran za prodaju knjiga.\n\n"
          "Prvo ćemo ti pokazati gdje se nalazi polje za pretragu, "
          "a zatim dio ekrana gdje se prikazuju knjige.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Nastavi"),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'searchField_open_module',
        keyTarget: _searchFieldKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Polje za pretragu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje unosiš naziv ili autora knjige.\n"
                  "Lista ispod će se filtrirati prema onome što upišeš.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'resultsList_open_module',
        keyTarget: _resultsListKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Lista knjiga",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje vidiš koje su knjige dostupne za prodaju "
                  "u tvojoj poslovnici.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () async {
        await onboarding.markCompleted(
          'sales_tutorial_open_module',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
      },
    );

    if (!mounted) return;
    _tutorial!.show(context: context);
  }

  Future<void> _startSearchTutorial(OnboardingProvider onboarding) async {
    if (!mounted) return;

    _searchController.clear();
    setState(() {
      _search = '';
      _tutorialBookId = null;
      _searchTutorialWaitingForInput = false;
      _searchDetailsTutorialActive = false;
    });
    await _fetchData();

    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tutorijal: Pretraga knjige"),
            content: const Text(
              "U polje za pretragu unesi tačan naziv knjige:\n\n"
              "\"Na Drini ćuprija\"\n\n"
              "Nije bitno koristiš li velika ili mala slova. "
              "Kad je pronađemo, objasnićemo ti detalje kartice pomoću tutorijala.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Započni"),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldStart || !mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'searchField_search_tutorial',
        keyTarget: _searchFieldKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Pretraga knjiga",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje unosiš naziv knjige \"Na Drini ćuprija\".",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        if (!mounted) return;
        setState(() {
          _searchTutorialWaitingForInput = true;
        });
      },
    )..show(context: context);
  }

  Future<void> _startAddToCartTutorial(OnboardingProvider onboarding) async {
    if (!mounted) return;

    _searchController.clear();
    setState(() {
      _search = '';
      _tutorialBookId = null;
      _cart.clear();
      _addToCartFlowActive = false;
      _addToCartWaitingForInput = false;
    });
    await _fetchData();

    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tutorijal: Dodavanje u korpu"),
            content: const Text(
              "U ovom tutorijalu ćeš:\n"
              "• pronaći knjigu \"Na Drini ćuprija\",\n"
              "• dodati je u korpu,\n"
              "• naučiti kako da povećaš/smanjiš količinu i obrišeš stavku,\n"
              "• otvoriš korpu i vidiš njene elemente.\n\n"
              "Za početak, pronađi knjigu tako što ćeš je upisati u polje za pretragu.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Započni"),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldStart || !mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'searchField_add_to_cart_tutorial',
        keyTarget: _searchFieldKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Pronađi knjigu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "U polje za pretragu unesi naziv knjige \"Na Drini ćuprija\".\n"
                  "Kad se pojavi u listi, vodićemo te dalje.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        if (!mounted) return;
        setState(() {
          _addToCartFlowActive = true;
          _addToCartWaitingForInput = true;
        });
      },
    )..show(context: context);
  }

  void _startAvailabilityDialogCoachMark(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_availabilityDialogListKey.currentContext == null ||
        _availabilityDialogRowKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAvailabilityDialogCoachMark(onboarding);
      });
      return;
    }

    if (_availabilityDialogCoachStarted) return;
    _availabilityDialogCoachStarted = true;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'availabilityDialogList',
        keyTarget: _availabilityDialogListKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Lista poslovnica",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "U listi se prikazuju sve poslovnice u kojima se knjiga nalazi.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'availabilityDialogRow',
        keyTarget: _availabilityDialogRowKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Detalji jedne poslovnice",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "U naslovu vidiš naziv i adresu poslovnice.\n"
                  "U podnaslovu su količine: koliko primjeraka je dostupno "
                  "za prodaju i koliko za iznajmljivanje.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,

      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () async {
        if (!mounted) return;

        Navigator.of(context).pop();

        await onboarding.markCompleted(
          'sales_tutorial_availability',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        if (!mounted) return;
        setState(() {
          _availabilityFlowActive = false;
          _availabilityWaitingForInput = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorijal „Provjera dostupnosti“ je završen.'),
          ),
        );
      },
    )..show(context: context);
  }

  Future<void> _startAvailabilityTutorial(OnboardingProvider onboarding) async {
    if (!mounted) return;

    _searchController.clear();
    setState(() {
      _search = '';
      _tutorialBookId = null;

      _availabilityFlowActive = false;
      _availabilityWaitingForInput = false;
    });
    await _fetchData();

    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tutorijal: Provjera dostupnosti"),
            content: const Text(
              "U ovom tutorijalu ćeš pronaći knjigu \"Ubiti pticu rugalicu\" "
              "i naučiti kako da provjeriš njenu dostupnost u svim poslovnicama.\n\n"
              "Za početak, potraži knjigu preko polja za pretragu.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Započni"),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldStart || !mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'searchField_availability_tutorial',
        keyTarget: _searchFieldKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Pronađi knjigu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "U polje za pretragu unesi naziv knjige \"Ubiti pticu rugalicu\".\n"
                  "Kada se pojavi u listi, prikazaćemo dugme za dostupnost.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        if (!mounted) return;
        setState(() {
          _availabilityFlowActive = true;
          _availabilityWaitingForInput = true;
        });
      },
    )..show(context: context);
  }

  void _startCartDetailsTutorial(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_cartItemsKey.currentContext == null ||
        _cartTotalKey.currentContext == null ||
        _cartFinalizeButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startCartDetailsTutorial(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'cartItems',
        keyTarget: _cartItemsKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Stavke u korpi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje vidiš sve knjige koje su dodane u korpu, zajedno sa autorom i žanrom. Takođe vidiš količinu i pojedinačnu cijenu svake stavke.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cartTotal',
        keyTarget: _cartTotalKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Ukupan iznos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje uvijek vidiš koliko ukupno iznosi račun za sve stavke u korpi.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cartFinalize',
        keyTarget: _cartFinalizeButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Završetak prodaje",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikom na „Finaliziraj prodaju“ zaključuješ transakciju i knjižiš prodaju.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () async {
        if (!mounted) return;
        Navigator.of(context).pop();

        await onboarding.markCompleted(
          'sales_tutorial_add_to_cart',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        if (!mounted) return;
        setState(() {
          _addToCartFlowActive = false;
          _addToCartWaitingForInput = false;
        });
      },
    )..show(context: context);
  }

  void _startFinalizeSaleCoachMarkOnFinalizeButton(
    OnboardingProvider onboarding,
  ) {
    if (!mounted) return;

    if (_cartFinalizeButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startFinalizeSaleCoachMarkOnFinalizeButton(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'finalizeButton_tutorial',
        keyTarget: _cartFinalizeButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Završetak prodaje",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikom na „Finaliziraj prodaju“ zaključuješ transakciju.\n"
                  "Nakon potvrde, prodaja će biti upisana u sistem.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {},
    )..show(context: context);
  }

  void _startFinalizeSaleCoachMarkOnCartFab(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_cartButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startFinalizeSaleCoachMarkOnCartFab(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'cartFab_finalize_sale',
        keyTarget: _cartButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Otvaranje korpe",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikom na ovu ikonu otvaraš prozor sa svim stavkama u korpi.\n"
                  "Sada ćemo je automatski otvoriti i označiti dugme „Finaliziraj prodaju“. ",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        _showCart(barrierDismissible: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startFinalizeSaleCoachMarkOnFinalizeButton(onboarding);
        });
      },
    )..show(context: context);
  }

  void _startAddToCartCoachMarkOnCartControls(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_bookCartControlsKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAddToCartCoachMarkOnCartControls(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'cartControls_add_to_cart_tutorial',
        keyTarget: _bookCartControlsKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Upravljanje količinom",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje možeš:\n"
                  "• smanjiti količinu (-),\n"
                  "• povećati količinu (+),\n"
                  "• obrisati stavku iz korpe (ikona kante).\n\n"
                  "U nastavku ti pokazujemo kako da otvoriš cijelu korpu.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startAddToCartCoachMarkOnCartFab(onboarding);
        });
      },
    )..show(context: context);
  }

  void _startAddToCartCoachMarkOnCartFab(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_cartButtonKey.currentContext == null) {
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'cartFab_add_to_cart_tutorial',
        keyTarget: _cartButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Otvaranje korpe",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikom na ovu ikonu otvaraš pregled korpe.\n"
                  "Sada ćemo je automatski otvoriti da ti pokažemo njene elemente.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      targets: targets,
      hideSkip: true,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        _showCart(barrierDismissible: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startCartDetailsTutorial(onboarding);
        });
      },
    )..show(context: context);
  }

  double get _total => _cart.entries.fold(0, (sum, entry) {
    final inv = _branchInventoryMap[entry.key];
    final price = inv?.price ?? 0;
    return sum + (price * entry.value);
  });
  void _maybeStartSearchDetailsTutorial() {
    if (!mounted) return;
    if (!_searchTutorialWaitingForInput) return;
    if (_searchDetailsTutorialActive) return;

    const targetTitle = 'na drini ćuprija';

    if (_allBooks.length != 1) return;

    final onlyBook = _allBooks.first;

    if (onlyBook.title.trim().toLowerCase() != targetTitle) return;

    setState(() {
      _tutorialBookId = onlyBook.id;
      _searchDetailsTutorialActive = true;
      _searchTutorialWaitingForInput = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final onboarding = context.read<OnboardingProvider>();
        _startSearchDetailsCoachMark(onboarding);
      });
    });
  }

  Future<void> _startSearchDetailsCoachMark(
    OnboardingProvider onboarding,
  ) async {
    if (!mounted) return;
    if (_tutorialBookId == null) return;

    if (_bookImageKey.currentContext == null ||
        _bookInfoKey.currentContext == null ||
        _bookPriceKey.currentContext == null ||
        _bookAvailabilityButtonKey.currentContext == null ||
        _bookAddButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startSearchDetailsCoachMark(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'bookImage',
        keyTarget: _bookImageKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Slika knjige",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje vidiš naslovnicu knjige. Ako nemamo sliku, prikazuje se ikonica.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bookInfo',
        keyTarget: _bookInfoKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Osnovni podaci",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "U kartici su prikazani osnovni podaci o knjizi. Ovdje vidiš naziv, autora, žanr i jezik knjige.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bookPrice',
        keyTarget: _bookPriceKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Cijena",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje uvijek možeš vidjeti prodajnu cijenu knjige.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bookAvailability',
        keyTarget: _bookAvailabilityButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Dostupnost",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovim dugmetom otvaraš prozor sa količinama u svim poslovnicama.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bookAddToCart',
        keyTarget: _bookAddButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Dodavanje u korpu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Ovdje dodaješ knjigu u korpu. U sljedećim tutorijalima ćeš završiti prodaju.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      hideSkip: true,
      onFinish: () async {
        await onboarding.markCompleted(
          'sales_tutorial_search',
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        if (!mounted) return;
        setState(() {
          _searchDetailsTutorialActive = false;
        });
      },
    )..show(context: context);
  }

  void _maybeStartAddToCartBookPhase() {
    if (!mounted) return;
    if (!_addToCartFlowActive) return;
    if (_tutorialBookId != null) return;
    if (!_addToCartWaitingForInput) return;

    const targetTitle = 'na drini ćuprija';

    if (_allBooks.length != 1) return;

    final onlyBook = _allBooks.first;
    if (onlyBook.title.trim().toLowerCase() != targetTitle) return;

    setState(() {
      _tutorialBookId = onlyBook.id;
      _addToCartWaitingForInput = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final onboarding = context.read<OnboardingProvider>();
        _startAddToCartCoachMarkOnAddButton(onboarding);
      });
    });
  }

  void _startAddToCartCoachMarkOnAddButton(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_bookAddButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAddToCartCoachMarkOnAddButton(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'addButton_add_to_cart_tutorial',
        keyTarget: _bookAddButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Dodavanje u korpu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikni na dugme \"Dodaj\" da bi ovu knjigu ubacio/la u korpu.\n"
                  "Nakon toga će se ovdje pojaviti kontrole za količinu.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {},
    )..show(context: context);
  }

  void _maybeStartAvailabilityPhase() {
    if (!mounted) return;
    if (!_availabilityFlowActive) return;
    if (!_availabilityWaitingForInput) return;

    const targetTitle = 'ubiti pticu rugalicu';

    if (_allBooks.length != 1) return;

    final onlyBook = _allBooks.first;
    if (onlyBook.title.trim().toLowerCase() != targetTitle) return;

    setState(() {
      _tutorialBookId = onlyBook.id;
      _availabilityWaitingForInput = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final onboarding = context.read<OnboardingProvider>();
        _startAvailabilityCoachMarkOnButton(onboarding);
      });
    });
  }

  void _startAvailabilityCoachMarkOnButton(OnboardingProvider onboarding) {
    if (!mounted) return;

    if (_bookAvailabilityButtonKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAvailabilityCoachMarkOnButton(onboarding);
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'availabilityButton_tutorial',
        keyTarget: _bookAvailabilityButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Provjera dostupnosti",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Klikom na dugme „Dostupnost“ otvaraš prozor u kojem vidiš "
                  "u kojim poslovnicama i u kojim količinama je knjiga dostupna.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {},
    )..show(context: context);
  }

  Future<void> _showAvailabilityDialog(int bookId) async {
    final onboarding = context.read<OnboardingProvider>();
    final auth = context.read<AuthProvider>();
    final isSandbox = auth.sandboxMode;
    final bool isTutorialAvailability =
        onboarding.activeItemCode == 'sales_tutorial_availability';
    final bool isAvailabilityMission =
        onboarding.activeItemCode == _missionAvailabilityCode;
    final bool isQuantityMission =
        onboarding.activeItemCode == _missionQuantityAvailabilityCode;
    List<BranchInventory> missionAvailability = [];
    if (isAvailabilityMission || isQuantityMission) {
      try {
        missionAvailability = await Provider.of<BranchInventoryProvider>(
          context,
          listen: false,
        ).getAvailabilityByBookId(bookId, sandbox: isSandbox);
      } catch (_) {
        missionAvailability = [];
      }
    }

    _availabilityDialogCoachStarted = false;
    await showDialog(
      context: context,
      barrierDismissible: !isTutorialAvailability,
      builder: (ctx) {
        if (isTutorialAvailability) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startAvailabilityDialogCoachMark(onboarding);
          });
        }
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              FutureBuilder<List<BranchInventory>>(
                future: Provider.of<BranchInventoryProvider>(
                  context,
                  listen: false,
                ).getAvailabilityByBookId(bookId, sandbox: isSandbox),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 140,
                      width: 340,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final data = snapshot.data ?? [];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    width: 340,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Dostupnost u poslovnicama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 16),
                        data.isEmpty
                            ? const Text(
                                'Knjiga nije dostupna ni u jednoj poslovnici.',
                                style: TextStyle(fontSize: 14),
                              )
                            : ConstrainedBox(
                                key: _availabilityDialogListKey,
                                constraints: const BoxConstraints(
                                  maxHeight: 220,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: data.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (_, i) {
                                    final inv = data[i];
                                    return ListTile(
                                      key: i == 0
                                          ? _availabilityDialogRowKey
                                          : null,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        (inv.branchName ?? 'Poslovnica') +
                                            ', ' +
                                            (inv.branchAddress ?? ''),
                                      ),
                                      subtitle: Text(
                                        'Za prodaju: ${inv.quantityForSale} | '
                                        'Za iznajmljivanje: ${inv.quantityForBorrow}',
                                        style: const TextStyle(fontSize: 13.5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
              if (!isTutorialAvailability)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                    splashRadius: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (isAvailabilityMission) {
      Book? target;
      for (final b in _allBooks) {
        if (b.title.trim().toLowerCase() == 'mali princ') {
          target = b;
          break;
        }
      }
      if (target == null) return;

      final bool isTargetBook = target.id == bookId;

      final localInv = _branchInventoryMap[bookId];
      final bool notInThisBranch =
          localInv == null || localInv.quantityForSale <= 0;
      final bool hasElsewhere = missionAvailability.any(
        (x) => x.quantityForSale > 0,
      );

      final bool missionOk = isTargetBook && notInThisBranch && hasElsewhere;

      if (missionOk) {
        await onboarding.markCompleted(
          _missionAvailabilityCode,
          OnboardingItemType.mission,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bravo! Pronašao/la si u kojim poslovnicama je knjiga „Mali princ“ dostupna.',
            ),
          ),
        );
      } else {
        final status = await onboarding.registerMissionFailure(
          _missionAvailabilityCode,
          OnboardingItemType.mission,
        );

        final msg = status.attempts == 1
            ? 'Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu'
            : 'Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (isQuantityMission) {
      Book? target;
      for (final b in _allBooks) {
        if (b.title.trim().toLowerCase() == 'zločin i kazna') {
          target = b;
          break;
        }
      }
      if (target == null || target.id != bookId) return;

      if (missionAvailability.isEmpty) return;

      final bool anyHasEnough = missionAvailability.any(
        (x) => x.quantityForSale >= 5,
      );
      if (!anyHasEnough) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ni jedna poslovnica trenutno nema 5 primjeraka „Zločin i kazna“ za prodaju.',
            ),
          ),
        );
        return;
      }

      final BranchInventory? selected =
          await _askQuantityMissionBranchSelection(missionAvailability);

      if (selected == null) {
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Misija je prekinuta.")));
        return;
      }

      final bool correct = selected.quantityForSale >= 5;

      if (!correct) {
        final status = await onboarding.registerMissionFailure(
          _missionQuantityAvailabilityCode,
          OnboardingItemType.mission,
        );

        final msg = status.attempts == 1
            ? 'Odgovor nije tačan. Obrati pažnju na kolonu „Za prodaju“ i pokušaj ponovo. '
                  'Možeš koristiti i hint (ikona sijalice).'
            : 'Još uvijek nije tačno. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      await onboarding.markCompleted(
        _missionQuantityAvailabilityCode,
        OnboardingItemType.mission,
      );

      onboarding.clearActiveItem();
      onboarding.requestShowOnboardingDashboard();

      final branchLabel = (selected.branchName ?? 'odabrana poslovnica');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bravo! Kupac će otići u poslovnicu $branchLabel koja ima dovoljno primjeraka.',
          ),
        ),
      );
    }
  }

  Future<BranchInventory?> _askQuantityMissionBranchSelection(
    List<BranchInventory> availability,
  ) async {
    BranchInventory? selected;

    return showDialog<BranchInventory>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Pitanje za misiju'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kupac želi kupiti 5 primjeraka knjige „Zločin i kazna“.\n\n'
                      'Na osnovu prikazane dostupnosti, u koju poslovnicu ćeš ga uputiti?',
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availability.length,
                        itemBuilder: (_, i) {
                          final inv = availability[i];
                          final title =
                              (inv.branchName ?? 'Poslovnica') +
                              ((inv.branchAddress != null &&
                                      inv.branchAddress!.isNotEmpty)
                                  ? ', ${inv.branchAddress}'
                                  : '');
                          return RadioListTile<BranchInventory>(
                            value: inv,
                            groupValue: selected,
                            onChanged: (value) {
                              setState(() {
                                selected = value;
                              });
                            },
                            title: Text(title),
                            subtitle: Text(
                              'Za prodaju: ${inv.quantityForSale} | '
                              'Za iznajmljivanje: ${inv.quantityForBorrow}',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Odustani'),
                ),
                TextButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(ctx, selected),
                  child: const Text('Potvrdi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startFinalizeSaleTutorial(OnboardingProvider onboarding) async {
    if (!mounted) return;

    setState(() {
      _finalizeFlowActive = false;
      _finalizeWaitingForCartItem = false;
    });

    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tutorijal: Finalizacija prodaje"),
            content: const Text(
              "U ovom tutorijalu ćeš naučiti kako da iz korpe završiš prodaju.\n\n"
              "1. Dodaj barem jednu knjigu u korpu.\n"
              "2. Otvori korpu klikom na ikonu sa kolicima.\n"
              "3. Klikni na dugme „Finaliziraj prodaju“.\n\n"
              "Kada uspješno završiš prodaju, označićemo tutorijal kao završen.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  onboarding.clearActiveItem();
                  Navigator.pop(ctx, false);
                  onboarding.requestShowOnboardingDashboard();
                },
                child: const Text("Odustani"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Započni"),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
    if (!shouldStart) {
      onboarding.clearActiveItem();
      onboarding.requestShowOnboardingDashboard();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tutorijal je prekinut.")));
      return;
    }
    if (_cart.isNotEmpty && _cartButtonKey.currentContext != null) {
      _startFinalizeSaleCoachMarkOnCartFab(onboarding);
      setState(() {
        _finalizeFlowActive = true;
        _finalizeWaitingForCartItem = false;
      });
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'results_finalize_sale',
        keyTarget: _resultsListKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: 4,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Dodaj knjigu u korpu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Odaberi bilo koju knjigu iz liste i pomoću dugmeta „Dodaj“ "
                  "ubaci je u korpu. Kada se pojavi ikona korpe, nastavljamo.",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _tutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        if (!mounted) return;
        setState(() {
          _finalizeFlowActive = true;
          _finalizeWaitingForCartItem = true;
        });
      },
    )..show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final String? activeCode = onboarding.activeItemCode;
    final bool isMissionBasicActive = activeCode == _missionBasicSaleCode;
    final bool isMissionMultiActive = activeCode == _missionMultiSaleCode;
    final bool isMissionAvailabilityActive =
        activeCode == _missionAvailabilityCode;
    final bool isMissionQuantityAvailabilityActive =
        activeCode == _missionQuantityAvailabilityCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Prodaja',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: _searchFieldKey,
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži po nazivu ili autoru...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _search = '';
                                  });
                                  _fetchData();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _search = val;
                        });
                        _fetchData();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  key: _resultsListKey,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _allBooks.isEmpty
                      ? const Center(
                          child: Text(
                            'Nema knjiga u sistemu.',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            double screenWidth = constraints.maxWidth;
                            int cardsPerRow = screenWidth > 1200
                                ? 3
                                : screenWidth > 800
                                ? 2
                                : 1;

                            double maxCross = screenWidth / cardsPerRow;
                            double cardHeight = maxCross * 0.4;
                            double childAspect = maxCross / cardHeight;
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: maxCross,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 18,
                                    childAspectRatio: childAspect,
                                  ),
                              itemCount: _allBooks.length,
                              itemBuilder: (_, idx) {
                                final book = _allBooks[idx];
                                final inv = _branchInventoryMap[book.id];
                                final inCart = _cart.containsKey(book.id);
                                final isAvailable =
                                    inv != null && inv.quantityForSale > 0;
                                final bool isTutorialBook =
                                    _tutorialBookId != null &&
                                    book.id == _tutorialBookId;
                                return Opacity(
                                  opacity: isAvailable ? 1.0 : 0.55,
                                  child: Stack(
                                    children: [
                                      Material(
                                        elevation: 2,
                                        borderRadius: BorderRadius.circular(18),
                                        color: const Color(0xfffaf5fb),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                flex: 30,
                                                child: AspectRatio(
                                                  aspectRatio: 0.65,
                                                  child: Container(
                                                    key: isTutorialBook
                                                        ? _bookImageKey
                                                        : null,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      color:
                                                          Colors.grey.shade100,
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child:
                                                        (book
                                                            .photoEndpoint
                                                            .isNotEmpty)
                                                        ? Image.network(
                                                            "$_baseUrl${book.photoEndpoint}",
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => const Icon(
                                                                  Icons
                                                                      .image_not_supported,
                                                                  size: 38,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 38,
                                                            color: Colors.grey,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Flexible(
                                                flex: 100,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                        left: 4.0,
                                                      ),
                                                  child: Column(
                                                    key: isTutorialBook
                                                        ? _bookInfoKey
                                                        : null,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        book.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      Text(
                                                        book.author,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        '${book.genreName} • ${book.languageName}',
                                                        style: TextStyle(
                                                          fontSize: 12.2,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const Spacer(),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            '${(inv?.price ?? book.price).toStringAsFixed(2)} KM',
                                                            key: isTutorialBook
                                                                ? _bookPriceKey
                                                                : null,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .indigo,
                                                                ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                SizedBox(
                                                                  width: 138,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    children: [
                                                                      ElevatedButton(
                                                                        key:
                                                                            isTutorialBook
                                                                            ? _bookAvailabilityButtonKey
                                                                            : null,
                                                                        onPressed: () =>
                                                                            _showAvailabilityDialog(
                                                                              book.id,
                                                                            ),
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.grey[300],
                                                                          foregroundColor:
                                                                              Colors.black87,
                                                                          minimumSize: const Size(
                                                                            0,
                                                                            35,
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                0,
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child: const Text(
                                                                          'Dostupnost',
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            8,
                                                                      ),
                                                                      isAvailable
                                                                          ? (inCart
                                                                                ? Row(
                                                                                    key: isTutorialBook
                                                                                        ? _bookCartControlsKey
                                                                                        : null,

                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    children: [
                                                                                      IconButton(
                                                                                        icon: const Icon(
                                                                                          Icons.remove_circle_outline,
                                                                                          size: 20,
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          final value =
                                                                                              (_cart[book.id] ??
                                                                                                  1) -
                                                                                              1;
                                                                                          _updateCart(
                                                                                            book.id,
                                                                                            value,
                                                                                            inv.quantityForSale,
                                                                                          );
                                                                                        },
                                                                                      ),
                                                                                      Text(
                                                                                        '${_cart[book.id]}',
                                                                                      ),
                                                                                      IconButton(
                                                                                        icon: const Icon(
                                                                                          Icons.add_circle_outline,
                                                                                          size: 20,
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          final value =
                                                                                              (_cart[book.id] ??
                                                                                                  1) +
                                                                                              1;
                                                                                          if (value <=
                                                                                              inv.quantityForSale) {
                                                                                            _updateCart(
                                                                                              book.id,
                                                                                              value,
                                                                                              inv.quantityForSale,
                                                                                            );
                                                                                          }
                                                                                        },
                                                                                      ),
                                                                                      IconButton(
                                                                                        icon: const Icon(
                                                                                          Icons.delete_outline,
                                                                                          size: 20,
                                                                                        ),
                                                                                        onPressed: () => _updateCart(
                                                                                          book.id,
                                                                                          0,
                                                                                          inv.quantityForSale,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : ElevatedButton(
                                                                                    key: isTutorialBook
                                                                                        ? _bookAddButtonKey
                                                                                        : null,
                                                                                    onPressed: () => _addToCart(
                                                                                      book.id,
                                                                                      inv.quantityForSale,
                                                                                    ),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      minimumSize: const Size(
                                                                                        0,
                                                                                        35,
                                                                                      ),
                                                                                      padding: const EdgeInsets.symmetric(
                                                                                        horizontal: 0,
                                                                                      ),
                                                                                      textStyle: const TextStyle(
                                                                                        fontSize: 16,
                                                                                      ),
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadius.circular(
                                                                                          8,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    child: const Text(
                                                                                      'Dodaj',
                                                                                    ),
                                                                                  ))
                                                                          : Container(
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal: 10,
                                                                                vertical: 6,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.red.withOpacity(
                                                                                  0.18,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(
                                                                                  8,
                                                                                ),
                                                                              ),
                                                                              child: const Center(
                                                                                child: Text(
                                                                                  "Nije dostupno",
                                                                                  textAlign: TextAlign.center,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: TextStyle(
                                                                                    color: Colors.red,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!isAvailable)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      18,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(18),
                                                  ),
                                            ),
                                            child: const Text(
                                              "Nije dostupno",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
          if (_cart.isNotEmpty)
            Positioned(
              right: 32,
              bottom: 32,
              child: FloatingActionButton.extended(
                key: _cartButtonKey,
                onPressed: _showCart,
                icon: const Icon(Icons.shopping_cart),
                label: Text('${_cart.values.fold(0, (sum, qty) => sum + qty)}'),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          if (isMissionBasicActive ||
              isMissionMultiActive ||
              isMissionAvailabilityActive ||
              isMissionQuantityAvailabilityActive)
            Positioned(
              left: 32,
              bottom: 32,
              child: FloatingActionButton(
                heroTag: 'missionHintFab',
                onPressed: () {
                  if (isMissionBasicActive) {
                    _showMissionHintDialog();
                  } else if (isMissionMultiActive) {
                    _showMultiMissionHintDialog();
                  } else if (isMissionAvailabilityActive) {
                    _showAvailabilityMissionHintDialog();
                  } else if (isMissionQuantityAvailabilityActive) {
                    _showQuantityAvailabilityMissionHintDialog();
                  }
                },
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                child: const Icon(Icons.lightbulb_outline),
              ),
            ),
        ],
      ),
    );
  }
}
