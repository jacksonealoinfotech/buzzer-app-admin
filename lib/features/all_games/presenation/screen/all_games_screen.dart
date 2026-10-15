import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

class GameItem {
  const GameItem({
    required this.id,
    required this.title,
    required this.host,
    required this.status,
    required this.players,
  });

  final String id;
  final String title;
  final String host;
  final GameStatus status;
  final int players;
}

enum GameFilter { all, live, scheduled, completed, flagged }

enum GameAction { view, monitor, clearFlag, end }

const List<GameItem> sampleGames = [
  GameItem(
    id: '1',
    title: 'Tech Trivia Challenge',
    host: 'Sarah Khan',
    status: GameStatus.live,
    players: 842,
  ),
  GameItem(
    id: '2',
    title: 'General Knowledge Quiz',
    host: 'Mike Ross',
    status: GameStatus.live,
    players: 621,
  ),
  GameItem(
    id: '3',
    title: 'Science Bowl',
    host: 'Priya Nair',
    status: GameStatus.live,
    players: 430,
  ),
  GameItem(
    id: '4',
    title: 'History Quiz',
    host: 'David Chen',
    status: GameStatus.scheduled,
    players: 310,
  ),
  GameItem(
    id: '5',
    title: 'Math Masters',
    host: 'Neha Kapoor',
    status: GameStatus.completed,
    players: 1200,
  ),
  GameItem(
    id: '6',
    title: 'Pop Culture Quiz',
    host: 'Arjun Patel',
    status: GameStatus.flagged,
    players: 542,
  ),
];

// ======================================================================
// Screen
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class AllGamesScreen extends StatefulWidget {
  const AllGamesScreen({
    super.key,
    this.games = sampleGames,
    this.currentTab = 1,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onGameTap,
    this.onAction,
  });

  final List<GameItem> games;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final ValueChanged<GameItem>? onGameTap;
  final void Function(GameItem game, GameAction action)? onAction;

  @override
  State<AllGamesScreen> createState() => _AllGamesScreenState();
}

class _AllGamesScreenState extends State<AllGamesScreen> {
  final _searchCtrl = TextEditingController();
  GameFilter _filter = GameFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(GameItem g) => switch (_filter) {
    GameFilter.all => true,
    GameFilter.live => g.status == GameStatus.live,
    GameFilter.scheduled => g.status == GameStatus.scheduled,
    GameFilter.completed => g.status == GameStatus.completed,
    GameFilter.flagged => g.status == GameStatus.flagged,
  };

  List<GameItem> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.games.where((g) {
      if (!_matchesFilter(g)) return false;
      if (q.isEmpty) return true;
      return g.title.toLowerCase().contains(q) ||
          g.host.toLowerCase().contains(q);
    }).toList();
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _filter = GameFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final games = _visible;

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
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
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
                    Text(
                      'All Games',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                    hintText: 'Search games or hosts...',
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
                  itemCount: GameFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = GameFilter.values[i];
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

              // ---- Result count
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '${games.length} ${games.length == 1 ? 'game' : 'games'}',
                      key: ValueKey(games.length),
                      style: text.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),

              // ---- List
              Expanded(
                child: RefreshIndicator(
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHigh,
                  onRefresh:
                      widget.onRefresh ??
                      () => Future<void>.delayed(
                        const Duration(milliseconds: 900),
                      ),
                  child: games.isEmpty
                      ? _EmptyState(onClear: _clearAll)
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: games.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final g = games[i];
                            return _Entry(
                              key: ValueKey('${g.id}-${_filter.name}'),
                              index: i,
                              child: _GameCard(
                                game: g,
                                onTap: widget.onGameTap == null
                                    ? null
                                    : () => widget.onGameTap!(g),
                                onAction: (a) => widget.onAction?.call(g, a),
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
    );
  }

  String _filterLabel(GameFilter f) => switch (f) {
    GameFilter.all => 'All',
    GameFilter.live => 'Live',
    GameFilter.scheduled => 'Scheduled',
    GameFilter.completed => 'Completed',
    GameFilter.flagged => 'Flagged',
  };
}

// ======================================================================
// Pieces
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

/// Fade + slide-up entrance; later items take slightly longer (staggered feel).
class _Entry extends StatelessWidget {
  const _Entry({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index.clamp(0, 8) * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, this.onTap, required this.onAction});

  final GameItem game;
  final VoidCallback? onTap;
  final ValueChanged<GameAction> onAction;

  static String _players(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(1).replaceAll('.0', '');
      return '${k}k players';
    }
    return '$n players';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    final flagged = game.status == GameStatus.flagged;
    final (Color dot, String statusText) = switch (game.status) {
      GameStatus.live => (cs.tertiary, 'Live'),
      GameStatus.scheduled => (cs.secondary, 'Scheduled'),
      GameStatus.completed => (
        cs.onSurface.withValues(alpha: 0.45),
        'Completed',
      ),
      GameStatus.flagged => (cs.error, 'Flagged'),
    };

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: flagged
                  ? cs.error.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: flagged ? cs.errorContainer : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 26,
                  color: flagged ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            game.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$statusText • ${_players(game.players)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(color: muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusBadge(status: game.status),
              _GameMenu(game: game, onSelected: onAction),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameMenu extends StatelessWidget {
  const _GameMenu({required this.game, required this.onSelected});
  final GameItem game;
  final ValueChanged<GameAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    PopupMenuItem<GameAction> item(
      GameAction a,
      IconData icon,
      String label, {
      Color? color,
    }) => PopupMenuItem<GameAction>(
      value: a,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );

    return PopupMenuButton<GameAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        item(GameAction.view, Icons.visibility_outlined, 'View details'),
        if (game.status == GameStatus.live)
          item(GameAction.monitor, Icons.sensors_rounded, 'Monitor live'),
        if (game.status == GameStatus.flagged)
          item(GameAction.clearFlag, Icons.flag_outlined, 'Clear flag'),
        if (game.status == GameStatus.live)
          item(
            GameAction.end,
            Icons.stop_circle_outlined,
            'End game',
            color: cs.error,
          ),
      ],
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

    // ListView so pull-to-refresh still works on the empty state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 64),
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
                  Icons.search_off_rounded,
                  size: 34,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No games found',
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
