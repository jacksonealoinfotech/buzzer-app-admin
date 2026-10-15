import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Shared bottom nav from the dashboard file (keep all files in the same folder)

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

enum PlayerStatus { active, pending, banned, flagged }

enum PlayerFilter { all, active, pending, banned, flagged }

enum PlayerSort { name, status, score }

/// Actions in the long-press sheet.
enum PlayerAction { view, approve, flag, clearFlag, ban, unban }

/// Actions in the top-right menu.
enum DirectoryMenuAction { export, refresh }

class PlayerItem {
  const PlayerItem({
    required this.id,
    required this.name,
    required this.status,
    required this.score,
    this.avatar,
  });

  final String id;
  final String name;
  final PlayerStatus status;
  final int score;
  final ImageProvider? avatar;
}

const List<PlayerItem> samplePlayers = [
  PlayerItem(
    id: '1',
    name: 'Riya Sharma',
    status: PlayerStatus.active,
    score: 3420,
  ),
  PlayerItem(
    id: '2',
    name: 'Aarav Mehta',
    status: PlayerStatus.active,
    score: 3180,
  ),
  PlayerItem(
    id: '3',
    name: 'Sneha Patel',
    status: PlayerStatus.active,
    score: 2960,
  ),
  PlayerItem(
    id: '4',
    name: 'Karan Singh',
    status: PlayerStatus.active,
    score: 2780,
  ),
  PlayerItem(
    id: '5',
    name: 'Priya Nair',
    status: PlayerStatus.active,
    score: 2640,
  ),
  PlayerItem(
    id: '6',
    name: 'Rohit Verma',
    status: PlayerStatus.banned,
    score: 2120,
  ),
  PlayerItem(
    id: '7',
    name: 'Ananya Das',
    status: PlayerStatus.active,
    score: 1980,
  ),
  PlayerItem(
    id: '8',
    name: 'Dev Mehta',
    status: PlayerStatus.active,
    score: 1760,
  ),
  PlayerItem(
    id: '9',
    name: 'Neha Kapoor',
    status: PlayerStatus.pending,
    score: 1540,
  ),
  PlayerItem(
    id: '10',
    name: 'Arjun Patel',
    status: PlayerStatus.flagged,
    score: 1210,
  ),
];

// ======================================================================
// Screen
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class PlayerDirectoryScreen extends StatefulWidget {
  const PlayerDirectoryScreen({
    super.key,
    this.players = samplePlayers,
    this.currentTab = 2,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onPlayerTap,
    this.onPlayerAction,
    this.onMenuAction,
  });

  final List<PlayerItem> players;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final ValueChanged<PlayerItem>? onPlayerTap;
  final void Function(PlayerItem player, PlayerAction action)? onPlayerAction;
  final ValueChanged<DirectoryMenuAction>? onMenuAction;

  @override
  State<PlayerDirectoryScreen> createState() => _PlayerDirectoryScreenState();
}

class _PlayerDirectoryScreenState extends State<PlayerDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  PlayerFilter _filter = PlayerFilter.all;
  PlayerSort _sort = PlayerSort.score;
  bool _ascending = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(PlayerItem p) => switch (_filter) {
    PlayerFilter.all => true,
    PlayerFilter.active => p.status == PlayerStatus.active,
    PlayerFilter.pending => p.status == PlayerStatus.pending,
    PlayerFilter.banned => p.status == PlayerStatus.banned,
    PlayerFilter.flagged => p.status == PlayerStatus.flagged,
  };

  List<PlayerItem> get _visible {
    final q = _query.trim().toLowerCase();
    final list = widget.players
        .where(
          (p) => _matches(p) && (q.isEmpty || p.name.toLowerCase().contains(q)),
        )
        .toList();

    int cmp(PlayerItem a, PlayerItem b) => switch (_sort) {
      PlayerSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      PlayerSort.status => a.status.index.compareTo(b.status.index),
      PlayerSort.score => a.score.compareTo(b.score),
    };

    list.sort((a, b) => _ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  void _onSort(PlayerSort s) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sort == s) {
        _ascending = !_ascending;
      } else {
        _sort = s;
        _ascending = s != PlayerSort.score; // score defaults to high -> low
      }
    });
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _filter = PlayerFilter.all;
    });
  }

  Future<void> _showActions(PlayerItem p) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<PlayerAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActionSheet(player: p),
    );
    if (action != null) widget.onPlayerAction?.call(p, action);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final players = _visible;

    return Scaffold(
      backgroundColor: cs.surface,
      // bottomNavigationBar: AdminBottomNav(
      //   currentIndex: widget.currentTab,
      //   onSelected: widget.onTabSelected,
      // ),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ---- App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed:
                          widget.onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Player Directory',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PopupMenuButton<DirectoryMenuAction>(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_vert_rounded),
                      color: cs.surfaceContainerHigh,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: widget.onMenuAction,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: DirectoryMenuAction.export,
                          child: Row(
                            children: [
                              Icon(Icons.file_download_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Export list'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: DirectoryMenuAction.refresh,
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: _query.isEmpty
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : IconButton(
                              key: const ValueKey('clear'),
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.primary, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---- Filter chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: PlayerFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = PlayerFilter.values[i];
                    return _FilterChip(
                      label: _filterLabel(f),
                      selected: _filter == f,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ---- Table card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        children: [
                          _TableHeader(
                            sort: _sort,
                            ascending: _ascending,
                            onSort: _onSort,
                            count: players.length,
                          ),
                          Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: cs.primary,
                              backgroundColor: cs.surfaceContainerHigh,
                              onRefresh:
                                  widget.onRefresh ??
                                  () => Future<void>.delayed(
                                    const Duration(milliseconds: 900),
                                  ),
                              child: players.isEmpty
                                  ? _EmptyState(onClear: _clearAll)
                                  : ListView.separated(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: players.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      itemBuilder: (context, i) {
                                        final p = players[i];
                                        return _Entry(
                                          key: ValueKey(
                                            '${p.id}-${_filter.name}',
                                          ),
                                          index: i,
                                          child: _PlayerRow(
                                            player: p,
                                            onTap: widget.onPlayerTap == null
                                                ? null
                                                : () => widget.onPlayerTap!(p),
                                            onLongPress: () => _showActions(p),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterLabel(PlayerFilter f) => switch (f) {
    PlayerFilter.all => 'All',
    PlayerFilter.active => 'Active',
    PlayerFilter.pending => 'Pending',
    PlayerFilter.banned => 'Banned',
    PlayerFilter.flagged => 'Flagged',
  };
}

// ======================================================================
// Table header (tap a column to sort)
// ======================================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.count,
  });

  final PlayerSort sort;
  final bool ascending;
  final ValueChanged<PlayerSort> onSort;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _HeaderCell(
              label: 'Player ($count)',
              active: sort == PlayerSort.name,
              ascending: ascending,
              onTap: () => onSort(PlayerSort.name),
            ),
          ),
          Expanded(
            flex: 3,
            child: _HeaderCell(
              label: 'Status',
              active: sort == PlayerSort.status,
              ascending: ascending,
              onTap: () => onSort(PlayerSort.status),
            ),
          ),
          Expanded(
            flex: 3,
            child: _HeaderCell(
              label: 'Score',
              active: sort == PlayerSort.score,
              ascending: ascending,
              alignEnd: true,
              onTap: () => onSort(PlayerSort.score),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final bool active;
  final bool ascending;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurface.withValues(alpha: 0.55);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: active ? 1 : 0,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: ascending ? 0.5 : 0, // arrow_drop_down flips for asc
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Row
// ======================================================================

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    this.onTap,
    required this.onLongPress,
  });
  final PlayerItem player;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: player.avatar,
                    child: player.avatar == null
                        ? Text(
                            player.name.isEmpty
                                ? '?'
                                : player.name[0].toUpperCase(),
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PlayerStatusBadge(status: player.status),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _fmt(player.score),
                textAlign: TextAlign.end,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable on the Player Profile / Hosts screens too.
class PlayerStatusBadge extends StatelessWidget {
  const PlayerStatusBadge({super.key, required this.status});
  final PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color bg, Color fg, String label) = switch (status) {
      PlayerStatus.active => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        'Active',
      ),
      PlayerStatus.pending => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        'Pending',
      ),
      PlayerStatus.banned => (cs.errorContainer, cs.onErrorContainer, 'Banned'),
      PlayerStatus.flagged => (
        cs.error.withValues(alpha: 0.10),
        cs.error,
        'Flagged',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: status == PlayerStatus.flagged
            ? Border.all(color: cs.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ======================================================================
// Long-press action sheet
// ======================================================================

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.player});
  final PlayerItem player;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget tile(PlayerAction a, IconData icon, String label, {Color? color}) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () => Navigator.pop(context, a),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: player.avatar,
                  child: player.avatar == null
                      ? Text(
                          player.name.isEmpty ? '?' : player.name[0],
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    player.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PlayerStatusBadge(status: player.status),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
          tile(PlayerAction.view, Icons.person_outline_rounded, 'View profile'),
          if (player.status == PlayerStatus.pending)
            tile(
              PlayerAction.approve,
              Icons.check_circle_outline_rounded,
              'Approve player',
            ),
          if (player.status == PlayerStatus.flagged)
            tile(PlayerAction.clearFlag, Icons.flag_outlined, 'Clear flag')
          else if (player.status != PlayerStatus.banned)
            tile(PlayerAction.flag, Icons.outlined_flag_rounded, 'Flag player'),
          if (player.status == PlayerStatus.banned)
            tile(PlayerAction.unban, Icons.lock_open_rounded, 'Unban player')
          else
            tile(
              PlayerAction.ban,
              Icons.block_rounded,
              'Ban player',
              color: cs.error,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ======================================================================
// Small shared bits
// ======================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: selected ? cs.onPrimary : cs.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index.clamp(0, 9) * 55),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 48),
        _Entry(
          index: 0,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search_rounded,
                  size: 34,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No players found',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different search or filter.',
                style: text.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
