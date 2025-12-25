import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:knjigoteka_desktop/models/onboarding_item_status.dart';
import 'package:knjigoteka_desktop/models/onboarding_item_type.dart';
import 'package:knjigoteka_desktop/models/onboarding_overview.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import 'package:knjigoteka_desktop/providers/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(OnboardingItemStatus item)? onStartItem;

  const OnboardingScreen({Key? key, this.onStartItem}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const List<_OnboardingLevelDef> _levelDefs = [
  _OnboardingLevelDef(
    key: 'sales',
    title: 'Nivo 1: Prodaja',
    description: 'Osnovni rad sa modulom prodaje (pretraga, korpa, naplata).',
  ),
  _OnboardingLevelDef(
    key: 'books',
    title: 'Nivo 2: Knjige/zalihe',
    description: 'Pregled i uređivanje zaliha knjiga po poslovnicama.',
  ),
  _OnboardingLevelDef(
    key: 'borrowing',
    title: 'Nivo 3: Posudbe',
    description: 'Rad sa posudbama knjiga i vraćanjem primjeraka.',
  ),
  _OnboardingLevelDef(
    key: 'reservations',
    title: 'Nivo 4: Rezervacije',
    description: 'Rezervisanje naslova i rad sa rezervacijama korisnika.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<OnboardingOverview>? _future;
  String? _selectedLevelKey;

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();
    _future ??= onboardingProvider.getOverview();

    return FutureBuilder<OnboardingOverview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            onboardingProvider.overview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && onboardingProvider.overview == null) {
          return Center(
            child: Text(
              'Greška pri učitavanju onboardinga: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final overview = onboardingProvider.overview ?? snapshot.data!;

        final allByCode = {for (final i in overview.items) i.code: i};
        final levelStates = _buildLevelStates(overview);
        final badges = _computeBadges(overview);
        _handleNewBadgesAndCompletion(badges, overview);

        if (levelStates.isEmpty) {
          return const Center(
            child: Text('Nema definisanih nivoa za onboarding.'),
          );
        }

        final unlockedLevels = levelStates
            .where((l) => l.unlocked)
            .toList(growable: false);

        _selectedLevelKey ??= unlockedLevels.isNotEmpty
            ? unlockedLevels.last.def.key
            : levelStates.first.def.key;

        final selectedLevel = levelStates.firstWhere(
          (l) => l.def.key == _selectedLevelKey,
          orElse: () => levelStates.first,
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(onboardingProvider, badges),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: 320, child: _buildLevelsList(levelStates)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLevelDetails(
                        selectedLevel,
                        badges,
                        allByCode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header i značke
  // ---------------------------------------------------------------------------

  Widget _buildHeader(OnboardingProvider provider, List<_BadgeState> badges) {
    final done = provider.hasCompletedOnboarding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onboarding novih radnika',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          done
              ? 'Onboarding je završen. Sve značke koje si osvojio/la vidiš ispod.'
              : 'Onboarding je u toku. Završavaj nivoe redom i skupljaj značke.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (badges.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Osvojene značke (${badges.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map(_buildBadgeChip).toList(),
              ),
            ],
          )
        else
          Text(
            'Još nemaš nijednu značku. Kreni od prvog nivoa i osvoji titule.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildBadgeChip(_BadgeState b) {
    return Tooltip(
      message: '${b.name}\n${b.description}',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepPurple.withOpacity(0.25)),
        ),
        child: Icon(b.icon, size: 18, color: Colors.deepPurple),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lista nivoa (lijevi panel)
  // ---------------------------------------------------------------------------

  Widget _buildLevelsList(List<_LevelState> levels) {
    return Card(
      elevation: 1,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final level = levels[index];
          final selected = level.def.key == _selectedLevelKey;

          final colors = _levelColors(level);
          final total = level.items.length;
          final completedCount = level.items.where((i) => i.isCompleted).length;

          return InkWell(
            onTap: level.unlocked
                ? () {
                    setState(() {
                      _selectedLevelKey = level.def.key;
                    });
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? colors.background.withOpacity(0.9)
                    : colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Colors.blueGrey : Colors.grey.shade300,
                  width: selected ? 1.4 : 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    colors.icon,
                    color: level.unlocked
                        ? (level.completed ? Colors.green : Colors.blueAccent)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.def.title,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.def.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Napredak: $completedCount / $total zadataka',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    colors.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: level.completed
                          ? Colors.green.shade700
                          : (level.unlocked
                                ? Colors.blue.shade700
                                : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _LevelVisual _levelColors(_LevelState level) {
    if (!level.hasAnyItems) {
      return _LevelVisual(
        background: Colors.grey.shade100,
        icon: Icons.lock_outline,
        statusText: 'Nema definisanih zadataka',
      );
    }
    if (!level.unlocked) {
      return _LevelVisual(
        background: Colors.grey.shade200,
        icon: Icons.lock_outline,
        statusText: 'Zaključan nivo',
      );
    }
    if (level.completed) {
      return _LevelVisual(
        background: Colors.green.shade50,
        icon: Icons.check_circle,
        statusText: 'Završeno',
      );
    }
    return _LevelVisual(
      background: Colors.blue.shade50,
      icon: Icons.play_circle_fill,
      statusText: 'U toku',
    );
  }

  // ---------------------------------------------------------------------------
  // Detalji nivoa (desni panel)
  // ---------------------------------------------------------------------------

  Widget _buildLevelDetails(
    _LevelState level,
    List<_BadgeState> allBadges,
    Map<String, OnboardingItemStatus> allByCode,
  ) {
    if (!level.hasAnyItems) {
      return Card(
        elevation: 1,
        child: Center(
          child: Text(
            'Za ovaj nivo još nisu definisani tutorijali i misije.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final tutorials = level.items
        .where((i) => i.itemType == OnboardingItemType.tutorial)
        .toList();
    final missions = level.items
        .where((i) => i.itemType == OnboardingItemType.mission)
        .toList();
    final levelBadges = allBadges
        .where((b) => b.levelKey == level.def.key)
        .toList();
    final tutorialsCount = tutorials.length;
    final missionsCount = missions.length;
    final tutorialsDone = tutorials.where((i) => i.isCompleted).length;
    final missionsDone = missions.where((i) => i.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.def.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Tutorijali i misije za odabrani nivo.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (levelBadges.isNotEmpty) ...[
          const Text(
            'Značke za ovaj nivo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levelBadges.map(_buildLevelBadgeChip).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  if (tutorials.isNotEmpty) ...[
                    Text(
                      'Tutorijali ($tutorialsDone/$tutorialsCount)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tutorials.map(
                      (item) => _buildItemTile(
                        item,
                        enabled: _isItemEnabled(level, item, allByCode),
                        lockedReason: _computeLockedReason(item, allByCode),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (missions.isNotEmpty) ...[
                    Text(
                      'Misije ($missionsDone/$missionsCount)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...missions.map(
                      (item) => _buildItemTile(
                        item,
                        enabled: _isItemEnabled(level, item, allByCode),
                        lockedReason: _computeLockedReason(item, allByCode),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBadgeChip(_BadgeState b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(b.icon, size: 18, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            b.name,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _isItemEnabled(
    _LevelState level,
    OnboardingItemStatus item,
    Map<String, OnboardingItemStatus> allByCode,
  ) {
    final lockedReason = _computeLockedReason(item, allByCode);
    return level.unlocked && lockedReason == null;
  }

  // ---------------------------------------------------------------------------
  // Tile za pojedinačni tutorijal / misiju
  // ---------------------------------------------------------------------------

  Widget _buildItemTile(
    OnboardingItemStatus item, {
    required bool enabled,
    String? lockedReason,
  }) {
    final isCompleted = item.isCompleted;
    final baseColor = !enabled
        ? Colors.grey
        : (isCompleted ? Colors.green : Colors.blueGrey);

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Card(
        child: ListTile(
          leading: Icon(
            item.itemType == OnboardingItemType.tutorial
                ? Icons.menu_book
                : Icons.flag,
            color: baseColor,
          ),
          title: Text(item.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              if (lockedReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lockedReason,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          onTap: enabled ? () => _onItemTap(item) : null,
        ),
      ),
    );
  }

  Future<void> _onItemTap(OnboardingItemStatus item) async {
    final auth = context.read<AuthProvider>();
    final onboarding = context.read<OnboardingProvider>();

    final isMission = item.itemType == OnboardingItemType.mission;
    final moduleName = _getModuleNameForCode(item.code);

    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              isMission ? 'Pokretanje misije' : 'Pokretanje tutorijala',
            ),
            content: Text(
              isMission
                  ? 'Pokrenut ćeš misiju "${item.name}" u modulu $moduleName.\n\n'
                        'Bićeš prebačen/a u taj modul i tamo ćeš dobiti upute šta tačno trebaš uraditi.'
                  : 'Pokrenut ćeš tutorijal "${item.name}" u modulu $moduleName.\n\n'
                        'Bićeš prebačen/a u taj modul i tamo ćeš dobiti kratko objašnjenje koraka.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
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

    if (!shouldStart) return;

    auth.enableSandboxMode();
    onboarding.startItem(item.code);

    if (widget.onStartItem != null) {
      widget.onStartItem!(item);
    } else {
      _showModuleSnackBarForCode(item.code);
    }

    debugPrint('Pokrenut onboarding item: ${item.code}');
  }

  String _getModuleNameForCode(String code) {
    if (code.startsWith('sales_')) return 'Prodaja';
    if (code.startsWith('books_')) return 'Knjige/zalihe';
    if (code.startsWith('borrowing_')) return 'Posudbe';
    if (code.startsWith('reservations_')) return 'Rezervacije';
    return 'Sistem';
  }

  void _showModuleSnackBarForCode(String code) {
    String? message;

    final bool isMission = code.contains('_mission_');
    final bool isTutorial = code.contains('_tutorial_');

    String prefix;
    if (isMission) {
      prefix = 'Misija je pokrenuta.';
    } else if (isTutorial) {
      prefix = 'Tutorijal je pokrenut.';
    } else {
      prefix = 'Onboarding je pokrenut.';
    }

    if (code.startsWith('sales_') &&
        !code.contains('sales_tutorial_open_module')) {
      message = '$prefix Otvorite modul Prodaja u meniju.';
    } else if (code.startsWith('books_') &&
        !code.contains('books_tutorial_open_module')) {
      message = '$prefix Otvorite modul Knjige u meniju.';
    } else if (code.startsWith('borrowing_') &&
        !code.contains('borrowing_tutorial_open_module')) {
      message = '$prefix Otvorite modul Posudbe u meniju.';
    } else if (code.startsWith('reservations_') &&
        !code.contains('reservations_tutorial_open_module')) {
      message = '$prefix Otvorite modul Rezervacije.';
    }

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ---------------------------------------------------------------------------
  // Helperi za zaključavanje, naslove i tekst dijaloga
  // ---------------------------------------------------------------------------

  String? _computeLockedReason(
    OnboardingItemStatus item,
    Map<String, OnboardingItemStatus> byCode,
  ) {
    if (item.requiredItemCodes.isEmpty) return null;

    final unmet = <String>[];
    for (final code in item.requiredItemCodes) {
      final dep = byCode[code];
      if (dep == null || !dep.isCompleted) {
        unmet.add(dep?.name ?? code);
      }
    }

    if (unmet.isEmpty) return null;
    if (unmet.length == 1) {
      return 'Prvo završi: ${unmet.first}.';
    }
    return 'Prvo završi: ${unmet.join(', ')}.';
  }

  // ---------------------------------------------------------------------------
  // Logika nivoa i znački
  // ---------------------------------------------------------------------------

  List<_LevelState> _buildLevelStates(OnboardingOverview overview) {
    final Map<String, List<OnboardingItemStatus>> byLevel = {};

    for (final item in overview.items) {
      final key = _levelKeyFromCode(item.code);
      if (key == null) continue;
      byLevel.putIfAbsent(key, () => []).add(item);
    }

    final meta = <_LevelMeta>[];

    for (final def in _levelDefs) {
      final items = byLevel[def.key] ?? <OnboardingItemStatus>[];
      final hasAny = items.isNotEmpty;
      final completed = hasAny && items.every((i) => i.isCompleted);
      final hasUnfinished = hasAny && items.any((i) => !i.isCompleted);

      meta.add(
        _LevelMeta(
          def: def,
          items: items,
          hasAnyItems: hasAny,
          completed: completed,
          hasUnfinished: hasUnfinished,
        ),
      );
    }

    int highestUnlockedIndex = -1;
    int lastWithAny = -1;

    for (int i = 0; i < meta.length; i++) {
      final m = meta[i];

      if (!m.hasAnyItems) break;
      lastWithAny = i;

      if (m.hasUnfinished) {
        highestUnlockedIndex = i;
        break;
      } else if (m.completed) {
        highestUnlockedIndex = i;
      }
    }

    if (highestUnlockedIndex == -1) {
      highestUnlockedIndex = lastWithAny;
    }
    if (highestUnlockedIndex < 0) {
      highestUnlockedIndex = 0;
    }

    final result = <_LevelState>[];
    for (int i = 0; i < meta.length; i++) {
      final m = meta[i];
      final unlocked = m.hasAnyItems && i <= highestUnlockedIndex;

      result.add(
        _LevelState(
          def: m.def,
          items: m.items,
          hasAnyItems: m.hasAnyItems,
          unlocked: unlocked,
          completed: m.completed,
          hasUnfinished: m.hasUnfinished,
        ),
      );
    }

    return result;
  }

  String? _levelKeyFromCode(String code) {
    if (code.startsWith('sales_')) return 'sales';
    if (code.startsWith('books_')) return 'books';
    if (code.startsWith('borrowing_')) return 'borrowing';
    if (code.startsWith('reservations_')) return 'reservations';
    return null;
  }

  List<_BadgeState> _computeBadges(OnboardingOverview overview) {
    final Map<String, List<OnboardingItemStatus>> byLevel = {};

    for (final item in overview.items) {
      final key = _levelKeyFromCode(item.code);
      if (key == null) continue;
      byLevel.putIfAbsent(key, () => []).add(item);
    }

    final badges = <_BadgeState>[];

    void addBadge(bool condition, _BadgeState badge) {
      if (condition) badges.add(badge);
    }

    void processLevel(String levelKey) {
      final items = byLevel[levelKey] ?? <OnboardingItemStatus>[];

      final levelCompleted =
          items.isNotEmpty && items.every((i) => i.isCompleted);
      if (!levelCompleted) return;
      switch (levelKey) {
        case 'sales':
          addBadge(
            levelCompleted,
            _BadgeState(
              id: 'sales_level_master',
              name: 'Majstor Prodaje',
              description:
                  'Završio/la si sve tutorijale i misije u modulu prodaje.',
              icon: Icons.shopping_cart_checkout,
              levelKey: levelKey,
            ),
          );
          break;
        case 'books':
          addBadge(
            levelCompleted,
            _BadgeState(
              id: 'books_level_master',
              name: 'Čuvar Polica',
              description:
                  'Završio/la si sve tutorijale i misije u modulu knjige/zalihe.',
              icon: Icons.library_books,
              levelKey: levelKey,
            ),
          );
          break;
        case 'borrowing':
          addBadge(
            levelCompleted,
            _BadgeState(
              id: 'borrowing_level_master',
              name: 'Gospodar Posuđivanja',
              description:
                  'Završio/la si sve tutorijale i misije u modulu posudbe.',
              icon: Icons.handshake,
              levelKey: levelKey,
            ),
          );
          break;
        case 'reservations':
          addBadge(
            levelCompleted,
            _BadgeState(
              id: 'reservations_level_master',
              name: 'Stražar Rezervacija',
              description:
                  'Završio/la si sve tutorijale i misije u modulu rezervacije.',
              icon: Icons.event_note,
              levelKey: levelKey,
            ),
          );
          break;
      }
    }

    for (final def in _levelDefs) {
      processLevel(def.key);
    }

    return badges;
  }

  void _handleNewBadgesAndCompletion(
    List<_BadgeState> badges,
    OnboardingOverview overview,
  ) {
    final onboardingProvider = context.read<OnboardingProvider>();
    final currentIds = badges.map((b) => b.id).toSet();

    final alreadyShown = onboardingProvider.shownBadgeIds;

    final newIds = currentIds.difference(alreadyShown);
    final newlyEarned = badges.where((b) => newIds.contains(b.id)).toList();

    final bool onboardingNowDone = overview.hasCompletedOnboarding;
    final bool shouldShowAllDone =
        onboardingNowDone && !onboardingProvider.onboardingCompletionPopupShown;

    if (newlyEarned.isEmpty && !shouldShowAllDone) {
      return;
    }
    for (final badge in newlyEarned) {
      onboardingProvider.markBadgeAsShown(badge.id);
    }
    if (shouldShowAllDone) {
      onboardingProvider.markOnboardingCompletionPopupShown();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      for (final badge in newlyEarned) {
        final levelDef = _levelDefs.firstWhere(
          (d) => d.key == badge.levelKey,
          orElse: () => _levelDefs.first,
        );

        final title = 'Nivo završen ✅';
        final content =
            'Završio/la si sve tutorijale i misije na nivou "${levelDef.title}".\n\n'
            'Osvojio/la si novu značku: "${badge.name}".';

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nastavi'),
              ),
            ],
          ),
        );

        onboardingProvider.markBadgeAsShown(badge.id);
      }

      if (shouldShowAllDone && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Onboarding završen 🎉'),
            content: const Text(
              'Završio/la si sve nivoe, tutorijale i misije u gemifikovanom '
              'onboardingu.\n\n'
              'Spreman/na si za samostalan rad u sistemu Knjigoteka. '
              'Onboarding modul i dalje možeš koristiti kao podsjetnik '
              'ili za dodatno uvježbavanje.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Super!'),
              ),
            ],
          ),
        );

        onboardingProvider.markOnboardingCompletionPopupShown();
      }
    });
  }
}

// -----------------------------------------------------------------------------
// Helper modeli za nivoe i značke
// -----------------------------------------------------------------------------

class _OnboardingLevelDef {
  final String key;
  final String title;
  final String description;

  const _OnboardingLevelDef({
    required this.key,
    required this.title,
    required this.description,
  });
}

class _LevelMeta {
  final _OnboardingLevelDef def;
  final List<OnboardingItemStatus> items;
  final bool hasAnyItems;
  final bool completed;
  final bool hasUnfinished;

  _LevelMeta({
    required this.def,
    required this.items,
    required this.hasAnyItems,
    required this.completed,
    required this.hasUnfinished,
  });
}

class _LevelState {
  final _OnboardingLevelDef def;
  final List<OnboardingItemStatus> items;
  final bool hasAnyItems;
  final bool unlocked;
  final bool completed;
  final bool hasUnfinished;

  _LevelState({
    required this.def,
    required this.items,
    required this.hasAnyItems,
    required this.unlocked,
    required this.completed,
    required this.hasUnfinished,
  });
}

class _BadgeState {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String levelKey;

  _BadgeState({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.levelKey,
  });
}

class _LevelVisual {
  final Color background;
  final IconData icon;
  final String statusText;

  _LevelVisual({
    required this.background,
    required this.icon,
    required this.statusText,
  });
}
