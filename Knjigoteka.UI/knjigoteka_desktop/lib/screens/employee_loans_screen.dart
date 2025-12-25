import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:knjigoteka_desktop/models/onboarding_item_type.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import 'package:knjigoteka_desktop/providers/onboarding_provider.dart';

import '../models/borrowing.dart';
import '../models/branch_inventory.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../providers/borrowing_provider.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/user_provider.dart';

class EmployeeLoansScreen extends StatefulWidget {
  @override
  State<EmployeeLoansScreen> createState() => _EmployeeLoansScreenState();
}

class _EmployeeLoansScreenState extends State<EmployeeLoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _tabListenerAttached = false;

  String _borrowingSearch = '';
  String _reservationSearch = '';

  final GlobalKey _reservationsTabKey = GlobalKey();
  TutorialCoachMark? _reservationsTabTutorial;
  bool _reservationsTabTutorialShown = false;

  static const String _reservationTutorialFindCode =
      'reservations_tutorial_open_module';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartReservationsTabTutorial();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabListenerAttached) {
      _tabListenerAttached = true;
      _tabController.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    final onboarding = context.read<OnboardingProvider>();
    final code = onboarding.activeItemCode;

    final bool borrowingOnboardingActive =
        code != null && code.startsWith('borrowing_');

    if (borrowingOnboardingActive && _tabController.index == 1) {
      _tabController.index = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prvo završi tutorijal/misiju za posudbe, pa tek onda idi na rezervacije.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reservationsTabTutorial?.finish();
    _reservationsTabTutorial = null;
    _tabController.dispose();
    super.dispose();
  }

  void _maybeStartReservationsTabTutorial() {
    final onboarding = context.read<OnboardingProvider>();
    final code = onboarding.activeItemCode;

    if (code != _reservationTutorialFindCode) return;
    if (_reservationsTabTutorialShown) return;
    if (_reservationsTabKey.currentContext == null) return;

    _reservationsTabTutorialShown = true;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'reservations_tab',
        keyTarget: _reservationsTabKey,
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
                  'Tab Rezervacije',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Klikni ovdje da se prebaciš na listu rezervacija.\n'
                  'U sljedećem koraku pokazaćemo ti pretragu i tabelu rezervacija.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    _reservationsTabTutorial = TutorialCoachMark(
      hideSkip: true,
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      onFinish: () {
        _tabController.index = 1;
      },
      onSkip: () {
        _tabController.index = 1;
        return true;
      },
    )..show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Scaffold(
        backgroundColor: const Color(0xfff7f9fb),
        appBar: AppBar(
          backgroundColor: const Color(0xfff7f9fb),
          elevation: 0,
          toolbarHeight: 100,
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          title: const Padding(
            padding: EdgeInsets.zero,
            child: Text(
              'Posudbe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF233348),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              color: const Color(0xfff7f9fb),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF233348),
                labelColor: const Color(0xFF233348),
                unselectedLabelColor: Colors.black45,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  const Tab(text: 'Posudbe'),
                  Tab(key: _reservationsTabKey, text: 'Rezervacije'),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: TabBarView(
            controller: _tabController,
            children: [
              BorrowingsTab(
                search: _borrowingSearch,
                onSearchChanged: (val) =>
                    setState(() => _borrowingSearch = val),
              ),
              ReservationsTab(
                search: _reservationSearch,
                onSearchChanged: (val) =>
                    setState(() => _reservationSearch = val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BorrowingsTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;

  const BorrowingsTab({required this.search, required this.onSearchChanged});

  @override
  State<BorrowingsTab> createState() => _BorrowingsTabState();
}

class _BorrowingsTabState extends State<BorrowingsTab> {
  bool _loading = true;
  String? _error;
  List<Borrowing> _borrowings = [];

  final GlobalKey _searchFieldKey = GlobalKey();
  final GlobalKey _borrowingsTableKey = GlobalKey();
  final GlobalKey _missionReturnCheckboxKey = GlobalKey();

  TutorialCoachMark? _tutorial;

  static const String _borrowingTutorialOpenModuleCode =
      'borrowing_tutorial_open_module';
  static const String _borrowingMissionMarkReturnedCode =
      'borrowing_mission_mark_returned';

  bool _borrowingTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboarding = context.read<OnboardingProvider>();
      final code = onboarding.activeItemCode;

      switch (code) {
        case _borrowingTutorialOpenModuleCode:
          _startBorrowingOpenModuleTutorial(onboarding);
          break;
        case _borrowingMissionMarkReturnedCode:
          _showBorrowingMissionIntroDialog();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tutorial?.finish();
    _tutorial = null;
    super.dispose();
  }

  Future<void> _loadBorrowings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final isSandbox = auth.sandboxMode;
      final branchId = auth.effectiveBranchId!;
      final provider = context.read<BorrowingProvider>();

      final results = await provider.getAllBorrowings(
        branchId,
        sandbox: isSandbox,
      );

      if (!mounted) return;
      setState(() => _borrowings = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _startBorrowingOpenModuleTutorial(
    OnboardingProvider onboarding,
  ) async {
    if (!mounted || _borrowingTutorialShown) return;
    _borrowingTutorialShown = true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dobrodošli u modul Posudbe'),
        content: const Text(
          'Ovo je ekran za rad sa posudbama.\n\n'
          'Prvo ćemo ti pokazati polje za pretragu, '
          'a zatim tabelu sa svim posudbama.',
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
        identify: 'borrowings_searchField',
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
                  'Pretraga posudbi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje pretražuješ posudbe po imenu i prezimenu korisnika '
                  'ili po nazivu knjige.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'borrowings_table',
        keyTarget: _borrowingsTableKey,
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
                  'Lista posudbi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje vidiš ko je posudio knjigu, kada, do kada treba vratiti '
                  'i da li je vraćena.\n Također, ovdje možeš označiti knjigu kao vraćenu ili obrisati posudbu.\n Posudbe su sortirane po statusu vraćanja i datumu posudbe.',
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
          _borrowingTutorialOpenModuleCode,
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
      },
      onSkip: () => true,
    )..show(context: context);
  }

  Future<void> _showBorrowingMissionIntroDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    setState(() {});

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Misija: Označi knjigu kao vraćenu'),
        content: const Text(
          'Jedan korisnik vraća knjigu u poslovnicu.\n\n'
          'Potvrdi vraćanje te knjige.',
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

  Future<void> _showBorrowingMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_borrowingMissionMarkReturnedCode);
    final attempts = status?.attempts ?? 0;
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (attempts == 0 && !hintShown) {
      title = 'Opis misije';
      body =
          'Jedan korisnik vraća knjigu u poslovnicu.\n\n'
          'Potvrdi vraćanje te knjige.';
    } else if (!hintShown) {
      title = 'Hint';
      body =
          'Pogledaj kolonu „Vraćeno“ i fokusiraj se na one redove gdje checkbox nije označen.\n\n'
          'Klikni na checkbox takve posudbe i potvrdi vraćanje u dijalogu koji se pojavi.';

      showMoreButton = true;
    } else {
      title = 'Detaljno uputstvo';
      body =
          '1. Na ekranu posudbi pronađi red u kojem posuđena knjiga još nije vraćena '
          '(checkbox u koloni „Vraćeno“ je prazan).\n'
          '2. Klikni na taj checkbox.\n'
          '3. U dijalogu koji se pojavi, potvrdi vraćanje.\n'
          'Kada uspješno simuliraš vraćanje aktivne posudbe, misija će biti označena kao završena.';
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          if (showMoreButton)
            TextButton(
              onPressed: () async {
                await onboarding.markHintShown(
                  _borrowingMissionMarkReturnedCode,
                  OnboardingItemType.mission,
                );
                Navigator.pop(ctx);
                _showBorrowingMissionHintDialog();
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
      ),
    );
  }

  Future<void> _returnBook(Borrowing b, bool returned) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdi vraćanje'),
        content: const Text(
          'Da li ste sigurni da želite označiti ovu knjigu kao vraćenu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final onboarding = context.read<OnboardingProvider>();
    final bool isMissionActive =
        onboarding.activeItemCode == _borrowingMissionMarkReturnedCode;

    if (isMissionActive) {
      final bool missionSuccess = returned && b.returnedAt == null;

      if (missionSuccess) {
        await onboarding.registerAttempt(
          _borrowingMissionMarkReturnedCode,
          OnboardingItemType.mission,
          success: true,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bravo! Uspješno si simulirao/la vraćanje posuđene knjige. Misija je uspješno završena.',
            ),
          ),
        );

        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
      } else {
        final status = await onboarding.registerMissionFailure(
          _borrowingMissionMarkReturnedCode,
          OnboardingItemType.mission,
        );

        final msg = status.attempts == 1
            ? "Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu."
            : "Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).";

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }

      return;
    }

    await context.read<BorrowingProvider>().setReturned(b.id, returned);
    await _loadBorrowings();
  }

  Future<void> _deleteBorrowing(Borrowing b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdi brisanje'),
        content: const Text(
          'Da li ste sigurni da želite obrisati ovu posudbu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<BorrowingProvider>().deleteBorrowing(b.id);
    await _loadBorrowings();
  }

  void _showAddBorrowingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddBorrowingDialog(
        onSave: (userId, bookId) async {
          await context.read<BorrowingProvider>().insert({
            'userId': userId,
            'bookId': bookId,
            'reservationId': null,
          });
          await _loadBorrowings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.search.isEmpty
        ? _borrowings
        : _borrowings
              .where(
                (l) =>
                    l.userName.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ) ||
                    l.bookTitle.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ),
              )
              .toList();

    final onboarding = context.watch<OnboardingProvider>();
    final String? activeCode = onboarding.activeItemCode;
    final bool isBorrowingMissionActive =
        activeCode == _borrowingMissionMarkReturnedCode;

    bool missionCheckboxAssigned = false;

    final content = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: _searchFieldKey,
                    decoration: InputDecoration(
                      hintText: 'Pretraži posudbe',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black45,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 18),
                ElevatedButton.icon(
                  onPressed: _showAddBorrowingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj novu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF233348),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nema posudbi za prikaz.',
                      style: TextStyle(fontSize: 18, color: Colors.black45),
                    ),
                  )
                : SingleChildScrollView(
                    key: _borrowingsTableKey,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: const [
                          DataColumn(label: Text('Ime i prezime')),
                          DataColumn(label: Text('Knjiga')),
                          DataColumn(label: Text('Datum posudjivanja')),
                          DataColumn(label: Text('Rok za vraćanje')),
                          DataColumn(label: Text('Vraćeno')),
                          DataColumn(label: Text('Obriši')),
                        ],
                        rows: filtered.map((b) {
                          final isReturned = b.returnedAt != null;
                          final bool assignMissionKey =
                              isBorrowingMissionActive &&
                              !isReturned &&
                              !missionCheckboxAssigned;

                          if (assignMissionKey) {
                            missionCheckboxAssigned = true;
                          }

                          return DataRow(
                            color: MaterialStateProperty.resolveWith(
                              (states) =>
                                  isReturned ? Colors.grey[200] : Colors.white,
                            ),
                            cells: [
                              DataCell(
                                Text(
                                  b.userName,
                                  style: TextStyle(
                                    color: isReturned
                                        ? Colors.black54
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  b.bookTitle,
                                  style: TextStyle(
                                    color: isReturned
                                        ? Colors.black54
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  b.borrowedAt.toString().substring(0, 10),
                                  style: TextStyle(
                                    color: isReturned
                                        ? Colors.black54
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                Builder(
                                  builder: (context) {
                                    final now = DateTime.now();
                                    final daysLeft = b.dueDate
                                        .difference(now)
                                        .inDays;

                                    String text;
                                    TextStyle style = TextStyle(
                                      color: isReturned
                                          ? Colors.black54
                                          : Colors.black,
                                    );

                                    if (isReturned) {
                                      text = 'Vraćeno';
                                    } else if (daysLeft < 0) {
                                      text = 'Kasni ${-daysLeft} dana';
                                      style = style.copyWith(
                                        color: Colors.red[700],
                                      );
                                    } else if (daysLeft == 0) {
                                      text = 'Rok ističe danas';
                                      style = style.copyWith(
                                        color: Colors.orange[800],
                                      );
                                    } else {
                                      text = '$daysLeft dana';
                                      if (daysLeft <= 3) {
                                        style = style.copyWith(
                                          color: Colors.orange[800],
                                        );
                                      }
                                    }

                                    return Text(text, style: style);
                                  },
                                ),
                              ),
                              isReturned
                                  ? const DataCell(SizedBox())
                                  : DataCell(
                                      Checkbox(
                                        key: assignMissionKey
                                            ? _missionReturnCheckboxKey
                                            : null,
                                        value: b.returnedAt != null,
                                        onChanged: (val) =>
                                            _returnBook(b, val ?? false),
                                      ),
                                    ),
                              isReturned
                                  ? const DataCell(SizedBox())
                                  : DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFF233348),
                                        ),
                                        onPressed: () => _deleteBorrowing(b),
                                      ),
                                    ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        content,
        if (isBorrowingMissionActive)
          Positioned(
            left: 32,
            bottom: 32,
            child: FloatingActionButton(
              heroTag: 'borrowingMissionHintFab',
              onPressed: _showBorrowingMissionHintDialog,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              child: const Icon(Icons.lightbulb_outline),
            ),
          ),
      ],
    );
  }
}

class AddBorrowingDialog extends StatefulWidget {
  final Future<void> Function(int userId, int bookId) onSave;

  const AddBorrowingDialog({required this.onSave});

  @override
  State<AddBorrowingDialog> createState() => _AddBorrowingDialogState();
}

class _AddBorrowingDialogState extends State<AddBorrowingDialog> {
  final _userController = TextEditingController();
  final _bookController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  User? _selectedUser;
  BranchInventory? _selectedBook;

  List<User> _users = [];
  List<BranchInventory> _books = [];

  bool _loadingUsers = false;
  bool _loadingBooks = false;

  Timer? _debounceUser;
  Timer? _debounceBook;

  void _fetchUsers(String query) {
    if (_debounceUser?.isActive ?? false) _debounceUser?.cancel();

    _debounceUser = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingUsers = true);
      try {
        final result = await context.read<UserProvider>().searchUsers(
          FTS: query,
        );

        if (!mounted) return;
        setState(() => _users = result);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loadingUsers = false);
    });
  }

  void _fetchBooks(String query) {
    if (_debounceBook?.isActive ?? false) _debounceBook?.cancel();

    _debounceBook = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingBooks = true);
      try {
        final branchId = context.read<AuthProvider>().branchId!;
        final result = await context
            .read<BranchInventoryProvider>()
            .getAvailableForBranch(branchId, fts: query);

        if (!mounted) return;
        setState(() {
          _books = result
              .where((b) => b.supportsBorrowing && b.quantityForBorrow > 0)
              .toList();
        });
      } catch (_) {}
      if (!mounted) return;
      setState(() => _loadingBooks = false);
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _bookController.dispose();
    _debounceUser?.cancel();
    _debounceBook?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width < 900 ? 400.0 : 480.0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dodaj posudbu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Autocomplete<User>(
                  displayStringForOption: (user) =>
                      '${user.fullName} <${user.email}>',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2) {
                      return const Iterable<User>.empty();
                    }
                    _fetchUsers(value.text);
                    return _users.where(
                      (u) =>
                          u.fullName.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ) ||
                          u.email.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ),
                    );
                  },
                  onSelected: (user) {
                    setState(() => _selectedUser = user);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _userController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Korisnik (ime ili email)',
                            border: const OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedUser = null;
                                        _users = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) => _selectedUser == null
                              ? 'Odaberi korisnika'
                              : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _users = [];
                                _selectedUser = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingUsers
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final User option = options.elementAt(
                                      index,
                                    );
                                    return ListTile(
                                      title: Text(option.fullName),
                                      subtitle: Text(option.email),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<BranchInventory>(
                  displayStringForOption: (book) =>
                      '${book.title} - ${book.author}',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2) {
                      return const Iterable<BranchInventory>.empty();
                    }
                    _fetchBooks(value.text);
                    return _books.where(
                      (b) =>
                          (b.title.toLowerCase().contains(
                                value.text.toLowerCase(),
                              ) ||
                              b.author.toLowerCase().contains(
                                value.text.toLowerCase(),
                              )) &&
                          b.supportsBorrowing &&
                          b.quantityForBorrow > 0,
                    );
                  },
                  onSelected: (book) {
                    setState(() => _selectedBook = book);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _bookController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Knjiga (naslov ili autor)',
                            border: const OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedBook = null;
                                        _books = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) =>
                              _selectedBook == null ? 'Odaberi knjigu' : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _books = [];
                                _selectedBook = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingBooks
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final BranchInventory option = options
                                        .elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        '${option.title} - ${option.author}',
                                      ),
                                      subtitle: Text(
                                        'Dostupno: ${option.quantityForBorrow}',
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedUser == null || _selectedBook == null) {
                          return;
                        }
                        await widget.onSave(
                          _selectedUser!.id,
                          _selectedBook!.bookId,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Sačuvaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReservationsTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;

  const ReservationsTab({required this.search, required this.onSearchChanged});

  @override
  State<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  bool _loading = true;
  String? _error;
  List<Reservation> _reservations = [];

  final GlobalKey _searchFieldKey = GlobalKey();
  final GlobalKey _reservationsTableKey = GlobalKey();
  final GlobalKey _missionCheckboxKey = GlobalKey();

  TutorialCoachMark? _tutorial;
  bool _reservationTutorialShown = false;

  static const String _reservationTutorialFindCode =
      'reservations_tutorial_open_module';
  static const String _reservationMissionMarkDoneCode =
      'reservations_mission_mark_done';

  bool _reservationMissionActive = false;

  @override
  void initState() {
    super.initState();
    _loadReservations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboarding = context.read<OnboardingProvider>();
      final code = onboarding.activeItemCode;

      switch (code) {
        case _reservationTutorialFindCode:
          _startReservationsTutorial(onboarding);
          break;
        case _reservationMissionMarkDoneCode:
          _reservationMissionActive = true;
          _showReservationMissionIntroDialog();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tutorial?.finish();
    _tutorial = null;
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final branchId = auth.effectiveBranchId!;
      final isSandbox = auth.sandboxMode;
      final provider = context.read<ReservationProvider>();

      final results = await provider.getAllReservations(
        branchId: branchId,
        sandbox: isSandbox,
      );

      if (!mounted) return;
      setState(() => _reservations = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _startReservationsTutorial(OnboardingProvider onboarding) async {
    if (!mounted || _reservationTutorialShown) return;
    _reservationTutorialShown = true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rad sa rezervacijama'),
        content: const Text(
          'Na ovom ekranu vidiš sve aktivne rezervacije za tvoju poslovnicu.\n\n'
          'Pokazaćemo ti gdje se nalazi polje za pretragu i lista rezervacija.',
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
        identify: 'reservations_searchField',
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
                  'Pretraga rezervacija',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje možeš pretraživati rezervacije po imenu i prezimenu korisnika '
                  'ili po nazivu knjige.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'reservations_table',
        keyTarget: _reservationsTableKey,
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
                  'Lista rezervacija',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ovdje vidiš ko je rezervisao koju knjigu i kada, '
                  'te možeš potvrditi preuzimanje ili obrisati rezervaciju.\n Rezervacije su poredane po statusu i datumu rezervacije.',
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
          _reservationTutorialFindCode,
          OnboardingItemType.tutorial,
        );
        onboarding.clearActiveItem();
        onboarding.requestShowOnboardingDashboard();
      },
      onSkip: () => true,
    )..show(context: context);
  }

  Future<void> _showReservationMissionIntroDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    setState(() {
      _reservationMissionActive = true;
    });

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Misija: Označi rezervaciju kao preuzetu'),
        content: const Text(
          'Korisnik došao po svoju rezervisanu knjigu.\n\n'
          'Potvrdi preuzimanje rezervacije.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _reservationMissionActive = false;
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

  Future<void> _showReservationMissionHintDialog() async {
    final onboarding = context.read<OnboardingProvider>();

    if (onboarding.overview == null) {
      await onboarding.getOverview();
    }

    final status = onboarding.getItemStatus(_reservationMissionMarkDoneCode);
    final attempts = status?.attempts ?? 0;
    final hintShown = status?.hintShown ?? false;

    String title;
    String body;
    bool showMoreButton = false;

    if (attempts == 0 && !hintShown) {
      title = 'Opis misije';
      body =
          'Korisnik došao po svoju rezervisanu knjigu.\n\n'
          'Potvrdi preuzimanje rezervacije.';
    } else if (!hintShown) {
      title = 'Hint';
      body =
          'Pogledaj kolonu „Potvrdi“ i fokusiraj se na one redove gdje checkbox nije označen.\n\n'
          'Klikni na checkbox takve rezervacije i potvrdi preuzimanje u dijalogu koji se pojavi.';
      showMoreButton = true;
    } else {
      title = 'Detaljno uputstvo';
      body =
          '1. Na listi rezervacija pronađi red gdje rezervacija još nije potvrđena.'
          '(checkbox u koloni „Potvrdi“ je prazan).\n'
          '2. Klikni na checkbox u koloni „Potvrdi“ za tu rezervaciju.\n'
          '3. U dijalogu potvrdi da želiš evidentirati preuzimanje.\n'
          'Kada uspješno simuliraš preuzimanje aktivne rezervacije, misija će biti označena kao završena.';
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          if (showMoreButton)
            TextButton(
              onPressed: () async {
                await onboarding.markHintShown(
                  _reservationMissionMarkDoneCode,
                  OnboardingItemType.mission,
                );
                Navigator.pop(ctx);
                _showReservationMissionHintDialog();
              },
              child: const Text('Prikaži detaljnije uputstvo'),
            ),
          TextButton(
            onPressed: () {
              onboarding.clearActiveItem();
              _reservationMissionActive = false;
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
      ),
    );
  }

  Future<void> _deleteReservation(Reservation res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdi brisanje'),
        content: const Text(
          'Da li ste sigurni da želite obrisati ovu rezervaciju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF233348),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<ReservationProvider>().deleteReservation(res.id);
    await _loadReservations();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filtered = widget.search.isEmpty
        ? _reservations
        : _reservations
              .where(
                (r) =>
                    r.userName.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ) ||
                    r.bookTitle.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ),
              )
              .where((r) => r.expiredAt == null || r.expiredAt!.isAfter(now))
              .toList();

    final onboarding = context.watch<OnboardingProvider>();
    final String? activeCode = onboarding.activeItemCode;
    final bool isReservationMissionActive =
        activeCode == _reservationMissionMarkDoneCode;

    bool missionCheckboxAssigned = false;

    final content = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: _searchFieldKey,
                    decoration: InputDecoration(
                      hintText: 'Pretraži rezervacije',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black45,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nema rezervacija za prikaz.',
                      style: TextStyle(fontSize: 18, color: Colors.black45),
                    ),
                  )
                : SingleChildScrollView(
                    key: _reservationsTableKey,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: const [
                          DataColumn(label: Text('Ime i prezime')),
                          DataColumn(label: Text('Knjiga')),
                          DataColumn(label: Text('Datum rezervacije')),
                          DataColumn(label: Text('Potvrdi')),
                          DataColumn(label: Text('Obriši')),
                        ],
                        rows: filtered.map((r) {
                          final isAccepted =
                              r.status.toLowerCase() != 'pending';

                          final bool assignMissionKey =
                              isReservationMissionActive &&
                              !isAccepted &&
                              !missionCheckboxAssigned;

                          if (assignMissionKey) {
                            missionCheckboxAssigned = true;
                          }

                          return DataRow(
                            color: MaterialStateProperty.resolveWith(
                              (states) =>
                                  isAccepted ? Colors.grey[200] : Colors.white,
                            ),
                            cells: [
                              DataCell(Text(r.userName)),
                              DataCell(Text(r.bookTitle)),
                              DataCell(
                                Text(r.reservedAt.toString().substring(0, 10)),
                              ),
                              isAccepted
                                  ? const DataCell(SizedBox())
                                  : DataCell(
                                      Checkbox(
                                        key: assignMissionKey
                                            ? _missionCheckboxKey
                                            : null,
                                        value: false,
                                        onChanged: (val) async {
                                          final onboarding = context
                                              .read<OnboardingProvider>();
                                          final bool isMissionActive =
                                              onboarding.activeItemCode ==
                                              _reservationMissionMarkDoneCode;

                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Potvrdi preuzimanje rezervacije',
                                              ),
                                              content: const Text(
                                                'Da li želite evidentirati posudbu za ovu rezervaciju?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: const Text('Otkaži'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF233348,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  child: const Text('Potvrdi'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed != true) {
                                            return;
                                          }

                                          if (isMissionActive) {
                                            final bool missionSuccess =
                                                r.status.toLowerCase() ==
                                                'pending';

                                            if (missionSuccess) {
                                              await onboarding.registerAttempt(
                                                _reservationMissionMarkDoneCode,
                                                OnboardingItemType.mission,
                                                success: true,
                                              );

                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Bravo! Uspješno si simulirao/la preuzimanje rezervacije. Misija je uspješno završena!',
                                                  ),
                                                ),
                                              );
                                              onboarding.clearActiveItem();
                                              _reservationMissionActive = false;
                                              onboarding
                                                  .requestShowOnboardingDashboard();
                                            } else {
                                              final status = await onboarding
                                                  .registerMissionFailure(
                                                    _reservationMissionMarkDoneCode,
                                                    OnboardingItemType.mission,
                                                  );

                                              final msg = status.attempts == 1
                                                  ? "Misija nije uspjela. Pogledaj hint preko ikone sijalice u donjem lijevom uglu."
                                                  : "Misija i dalje nije uspjela. Preporučujemo da pogledaš detaljno uputstvo (ikona sijalice).";

                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(content: Text(msg)),
                                              );
                                            }

                                            return;
                                          }

                                          await context
                                              .read<BorrowingProvider>()
                                              .insert({
                                                'userId': r.userId,
                                                'bookId': r.bookId,
                                                'reservationId': r.id,
                                              });

                                          await _loadReservations();
                                        },
                                      ),
                                    ),
                              isAccepted
                                  ? const DataCell(SizedBox())
                                  : DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFF233348),
                                        ),
                                        onPressed: () => _deleteReservation(r),
                                      ),
                                    ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        content,
        if (_reservationMissionActive)
          Positioned(
            left: 32,
            bottom: 32,
            child: FloatingActionButton(
              heroTag: 'reservationMissionHintFab',
              onPressed: _showReservationMissionHintDialog,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              child: const Icon(Icons.lightbulb_outline),
            ),
          ),
      ],
    );
  }
}
