import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_type.dart';
import 'package:knjigoteka_desktop/providers/onboarding_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/branch_inventory.dart';
import '../models/book.dart';
import '../models/restock_request.dart';
import '../providers/auth_provider.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/restock_request_provider.dart';
import '../providers/book_provider.dart';

class EmployeeBooksScreen extends StatefulWidget {
  @override
  State<EmployeeBooksScreen> createState() => _EmployeeBooksScreenState();
}

class _EmployeeBooksScreenState extends State<EmployeeBooksScreen> {
  List<Book> _allBooks = [];
  Map<int, BranchInventory> _branchInventoryMap = {};
  Map<int, RestockRequest?> _approvedRestock = {};
  bool _loading = false;
  String _search = '';

  final GlobalKey _searchFieldKey = GlobalKey();
  final GlobalKey _booksListKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  TutorialCoachMark? _tutorial;

  bool _booksOpenModuleTutorialShown = false;

  static const String _booksTutorialOpenModuleCode =
      'books_tutorial_open_module';
  static const String _booksMissionRestockCode =
      'books_mission_restock_two_copies';

  static const String _baseUrl = String.fromEnvironment(
    'baseUrl',
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
        case _booksTutorialOpenModuleCode:
          _startBooksOpenModuleTutorial(onboarding);
          break;
        case _booksMissionRestockCode:
          _showBooksRestockMissionIntroDialog();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tutorial?.finish();
    _tutorial = null;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final isSandbox = auth.sandboxMode;
      final branchId = auth.effectiveBranchId!;

      final allBooks = await context.read<BookProvider>().getBooks(
        fts: _search,
        sandbox: isSandbox,
      );

      final branchBooks = await context
          .read<BranchInventoryProvider>()
          .getAvailableForBranch(branchId, fts: _search, sandbox: isSandbox);

      final restockProvider = context.read<RestockRequestProvider>();
      final restockMap = <int, RestockRequest?>{};

      for (final b in allBooks) {
        final requests = await restockProvider.getApprovedForBranchBook(b.id);
        restockMap[b.id] = requests.isNotEmpty ? requests.first : null;
      }

      if (!mounted) return;
      setState(() {
        _allBooks = allBooks;
        _branchInventoryMap = {for (final b in branchBooks) b.bookId: b};
        _approvedRestock = restockMap;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allBooks = [];
        _branchInventoryMap = {};
        _approvedRestock = {};
        _loading = false;
      });
    }
  }

  Future<void> _startBooksOpenModuleTutorial(
    OnboardingProvider onboarding,
  ) async {
    if (!mounted || _booksOpenModuleTutorialShown) return;
    _booksOpenModuleTutorialShown = true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dobrodošli u modul Knjige'),
        content: const Text(
          'Ovo je ekran za rad sa knjigama i zalihama.\n\n'
          'Prvo ćemo ti pokazati gdje se nalazi polje za pretragu, '
          'a zatim dio ekrana gdje vidiš listu knjiga sa stanjem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nastavi'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'books_searchField',
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
                  'Pretraga knjiga',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje pretražuješ knjige po nazivu ili autoru.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'books_list',
        keyTarget: _booksListKey,
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
                  'Lista knjiga i zaliha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje vidiš svaki naslov, trenutnu količinu u poslovnici '
                  'i akcije koje omogućavaju upravljanje zalihama.',
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
          _booksTutorialOpenModuleCode,
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
      },
      onSkip: () => true,
    )..show(context: context);
  }

  Future<void> _showBooksRestockMissionIntroDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Misija: Dopuna zaliha'),
        content: const Text(
          'Neke knjige su potpuno nestale sa polica tvoje poslovnice.\n\n'
          'Tvoj zadatak je da pronađeš jednu od njih i obezbijediš da 5 primjeraka ponovo bude dostupno čitaocima. ',
        ),
        actions: [
          TextButton(
            onPressed: () {
              onboarding.clearActiveItem();
              Navigator.pop(ctx);
              onboarding.requestShowOnboardingDashboard();
            },
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kreni'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBooksRestockMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_booksMissionRestockCode);
    final attempts = status?.attempts ?? 0;
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (attempts == 0 && !hintShown) {
      title = 'Opis misije';
      body =
          'Neke knjige su potpuno nestale sa polica tvoje poslovnice.\n\n'
          'Tvoj zadatak je da pronađeš jednu od njih i obezbijediš da 5 primjeraka ponovo bude dostupno čitaocima. ';
    } else if (!hintShown) {
      title = 'Hint';
      body =
          'Fokusiraj se na knjige koje u tvojoj poslovnici imaju 0 primjeraka.\n\n'
          'Na kartici takve knjige potraži opciju za dopunu zaliha i pazi da uneseš tačno broj 5 kao količinu koju tražiš.';
      showMoreButton = true;
    } else {
      title = 'Detaljno uputstvo';
      body =
          '1. Na ekranu knjiga/zaliha pronađi knjigu koja u tvojoj poslovnici ima 0 primjeraka za prodaju.\n'
          '2. Na toj knjizi klikni na dugme za dopunu „Dopuna“.\n'
          '3. U dijalogu za dopunu:\n'
          '   • unesi vrijednost 5 u polje za količinu,\n'
          '   • provjeri da u centralnom skladištu ima dovoljno primjeraka,\n'
          '   • potvrdi slanje zahtjeva.\n'
          '4. Sistem za misiju provjerava:\n'
          '   • da je knjiga bila na 0 u tvojoj poslovnici,\n'
          '   • da si zatražio/la tačno 5 primjeraka.\n\n'
          'Kada ovi uslovi budu ispunjeni, misija će biti označena kao završena.';
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
                    _booksMissionRestockCode,
                    OnboardingItemType.mission,
                  );
                  Navigator.pop(ctx);
                  _showBooksRestockMissionHintDialog();
                },
                child: const Text('Prikaži detaljnije uputstvo'),
              ),
            TextButton(
              onPressed: () {
                onboarding.clearActiveItem();
                Navigator.pop(ctx);
                onboarding.requestShowOnboardingDashboard();
              },
              child: const Text('Prekini misiju'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
  }

  void _openEditDialog(Book book, BranchInventory? inv) async {
    final rr = _approvedRestock[book.id];
    final int maxAdd = rr?.quantityRequested ?? 0;
    final int sale = inv?.quantityForSale ?? 0;
    final int borrow = inv?.quantityForBorrow ?? 0;

    int saleChange = 0;
    int borrowChange = 0;
    String error = '';

    final saleController = TextEditingController(text: '0');
    final borrowController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (rr == null || maxAdd <= 0) {
              return AlertDialog(
                title: Text('Unos knjiga (${book.title})'),
                content: const Text(
                  'Nema odobrenog zahtjeva za prijem ove knjige. '
                  'Zatraži dopunu preko "Dopuna" opcije.',
                  style: TextStyle(color: Colors.red),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Odustani'),
                  ),
                ],
              );
            }

            void updateSale(String v) {
              final val = int.tryParse(v) ?? 0;
              setState(() {
                saleChange = val;
                error = '';
              });
            }

            void updateBorrow(String v) {
              final val = int.tryParse(v) ?? 0;
              setState(() {
                borrowChange = val;
                error = '';
              });
            }

            final totalAdd =
                (saleChange > 0 ? saleChange : 0) +
                (borrowChange > 0 ? borrowChange : 0);

            return AlertDialog(
              title: Text('Unos knjiga (${book.title})'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Na stanju: prodaja: $sale, iznajmljivanje: $borrow'),
                  Text('Dostupno za prijem: $maxAdd'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text('Za prodaju:')),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (saleChange > 0) {
                            setState(() {
                              saleChange--;
                              saleController.text = saleChange.toString();
                              error = '';
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: saleController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (v) {
                            int val = int.tryParse(v) ?? 0;
                            if (val < 0) val = 0;
                            if (val + borrowChange > maxAdd) {
                              val = maxAdd - borrowChange;
                            }
                            saleController.text = val.toString();
                            saleController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: saleController.text.length),
                            );
                            updateSale(saleController.text);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (saleChange + borrowChange < maxAdd) {
                            setState(() {
                              saleChange++;
                              saleController.text = saleChange.toString();
                              error = '';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Za iznajmljivanje:')),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (borrowChange > 0) {
                            setState(() {
                              borrowChange--;
                              borrowController.text = borrowChange.toString();
                              error = '';
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: borrowController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (v) {
                            int val = int.tryParse(v) ?? 0;
                            if (val < 0) val = 0;
                            if (val + saleChange > maxAdd) {
                              val = maxAdd - saleChange;
                            }
                            borrowController.text = val.toString();
                            borrowController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: borrowController.text.length,
                                  ),
                                );
                            updateBorrow(borrowController.text);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (saleChange + borrowChange < maxAdd) {
                            setState(() {
                              borrowChange++;
                              borrowController.text = borrowChange.toString();
                              error = '';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (totalAdd != maxAdd)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Zbir mora biti tačno $maxAdd knjiga!',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (totalAdd != maxAdd) {
                      setState(
                        () => error = 'Zbir mora biti tačno $maxAdd knjiga!',
                      );
                      return;
                    }

                    try {
                      await context
                          .read<BranchInventoryProvider>()
                          .upsertInventory(
                            inv?.branchId ??
                                context.read<AuthProvider>().branchId!,
                            book.id,
                            saleChange,
                            borrowChange,
                          );
                      Navigator.pop(ctx);
                      _fetchData();
                    } catch (e) {
                      setState(() => error = e.toString());
                    }
                  },
                  child: const Text('Spasi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openRestockDialog(Book book, BranchInventory? inv) {
    final onboarding = context.read<OnboardingProvider>();
    final bool isRestockMissionActive =
        onboarding.activeItemCode == _booksMissionRestockCode;

    final int oldQty = inv?.quantityForSale ?? 0;
    int maxCentralStock = book.centralStock;
    int wanted = 1;
    String? error;

    final controller = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateWanted(String v) {
              int val = int.tryParse(v) ?? 1;
              if (val < 1) val = 1;
              if (val > maxCentralStock) val = maxCentralStock;
              wanted = val;
              controller.text = wanted.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              setState(() => error = null);
            }

            return AlertDialog(
              title: Text('Zatraži dopunu (${book.title})'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: wanted > 1
                            ? () {
                                setState(() {
                                  wanted--;
                                  controller.text = wanted.toString();
                                  error = null;
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                          onChanged: (v) => updateWanted(v),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: wanted < maxCentralStock
                            ? () {
                                setState(() {
                                  wanted++;
                                  controller.text = wanted.toString();
                                  error = null;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Dostupno u centralnom skladištu: $maxCentralStock'),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (wanted > maxCentralStock) {
                      setState(() => error = 'Nema dovoljno knjiga na stanju!');
                      return;
                    }
                    if (wanted < 1) {
                      setState(() => error = 'Minimalno 1 knjiga!');
                      return;
                    }

                    if (isRestockMissionActive) {
                      Navigator.pop(ctx);

                      final bool missionSuccess = oldQty == 0 && wanted == 5;

                      if (missionSuccess) {
                        await onboarding.registerAttempt(
                          _booksMissionRestockCode,
                          OnboardingItemType.mission,
                          success: true,
                        );

                        onboarding.clearActiveItem();
                        onboarding.requestShowOnboardingDashboard();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bravo! Poslao/la si zahtjev za dopunu od 5 primjeraka knjige koja je bila rasprodata u tvojoj poslovnici. Misija je uspješno završena!',
                            ),
                          ),
                        );
                      } else {
                        final status = await onboarding.registerMissionFailure(
                          _booksMissionRestockCode,
                          OnboardingItemType.mission,
                        );

                        final msg = status.attempts == 1
                            ? "Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu."
                            : "Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).";

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }

                      return;
                    }

                    try {
                      await context
                          .read<RestockRequestProvider>()
                          .createRestockRequest(book.id, wanted);

                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Zahtjev za dopunu je uspješno poslan!',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      await _fetchData();
                    } catch (e) {
                      setState(() => error = e.toString());
                    }
                  },
                  child: const Text('Zatraži'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeBook(Book book, BranchInventory? inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text(
          'Da li ste sigurni da želite trajno ukloniti knjigu "${book.title}" iz ove poslovnice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<BranchInventoryProvider>().removeBookFromBranch(
        inv!.branchId,
        book.id,
      );
      _fetchData();
    }
  }

  Widget _responsiveButton(
    String text,
    VoidCallback onPressed,
    Color? bg,
    Color? fg,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              minimumSize: const Size(0, 32),
              maximumSize: const Size(double.infinity, 34),
            ),
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final bool isBooksRestockMissionActive =
        onboarding.activeItemCode == _booksMissionRestockCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Knjige',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                        setState(() => _search = val);
                        _fetchData();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
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
                          final screenWidth = constraints.maxWidth;
                          final cardsPerRow = screenWidth > 1200
                              ? 3
                              : screenWidth > 800
                              ? 2
                              : 1;

                          final maxCross = screenWidth / cardsPerRow;
                          final cardHeight = maxCross * 0.4;
                          final childAspect = maxCross / cardHeight;

                          return GridView.builder(
                            key: _booksListKey,
                            padding: EdgeInsets.zero,
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

                              final available =
                                  inv != null &&
                                  (inv.quantityForSale > 0 ||
                                      inv.quantityForBorrow > 0);

                              return Opacity(
                                opacity: available ? 1.0 : 0.7,
                                child: Stack(
                                  children: [
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(16),
                                      color: const Color(0xFFFCFAFF),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: AspectRatio(
                                                aspectRatio: 0.65,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    color: Colors.grey.shade100,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child:
                                                      book
                                                          .photoEndpoint
                                                          .isNotEmpty
                                                      ? Image.network(
                                                          '$_baseUrl${book.photoEndpoint}',
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
                                                                color:
                                                                    Colors.grey,
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
                                            const SizedBox(width: 14),
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          book.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    book.author,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${book.genreName} • ${book.languageName}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      if (inv != null) ...[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .indigo[50],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Prodaja: ${inv.quantityForSale}',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.indigo,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors.teal[50],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Iznajmljivanje: ${inv.quantityForBorrow}',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .teal[900],
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  if (inv == null) ...[
                                                    _responsiveButton(
                                                      'Uredi',
                                                      () => _openEditDialog(
                                                        book,
                                                        null,
                                                      ),
                                                      Colors.blue[50],
                                                      Colors.blue[900],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                          ),
                                                      child: _responsiveButton(
                                                        'Dopuna',
                                                        () =>
                                                            _openRestockDialog(
                                                              book,
                                                              inv,
                                                            ),
                                                        Colors.deepOrange[50],
                                                        Colors.deepOrange,
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    _responsiveButton(
                                                      'Uredi',
                                                      () => _openEditDialog(
                                                        book,
                                                        inv,
                                                      ),
                                                      Colors.blue[50],
                                                      Colors.blue[900],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _responsiveButton(
                                                      'Dopuna',
                                                      () => _openRestockDialog(
                                                        book,
                                                        inv,
                                                      ),
                                                      Colors.deepOrange[50],
                                                      Colors.deepOrange,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _responsiveButton(
                                                      'Ukloni',
                                                      () => _removeBook(
                                                        book,
                                                        inv,
                                                      ),
                                                      Colors.red[50],
                                                      Colors.red[800],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (inv == null)
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.9),
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(18),
                                                  bottomRight: Radius.circular(
                                                    18,
                                                  ),
                                                ),
                                          ),
                                          child: const Text(
                                            'Nije dostupno',
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
            ],
          ),
          if (isBooksRestockMissionActive)
            Positioned(
              left: 32,
              bottom: 32,
              child: FloatingActionButton(
                heroTag: 'booksMissionHintFab',
                onPressed: _showBooksRestockMissionHintDialog,
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
