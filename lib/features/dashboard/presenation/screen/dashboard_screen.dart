import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ======================================================================
// Models  (replace the sample data with your API models later)
// ======================================================================

enum GameStatus { live, scheduled, completed, flagged }

class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.trend,
    this.trendUp = true,
    this.trendGood = true,
  });

  final String label;
  final int value;
  final IconData icon;

  /// e.g. "12%" or "1"
  final String trend;

  /// Arrow direction.
  final bool trendUp;

  /// Whether this change is good news (colors the chip). Reports going DOWN is good.
  final bool trendGood;
}

class LiveGame {
  const LiveGame({
    required this.id,
    required this.title,
    required this.host,
    required this.players,
    this.status = GameStatus.live,
  });

  final String id;
  final String title;
  final String host;
  final int players;
  final GameStatus status;
}

const List<StatItem> sampleStats = [
  StatItem(
    label: 'Total Games',
    value: 48,
    icon: Icons.sports_esports_rounded,
    trend: '12%',
  ),
  StatItem(
    label: 'Live Now',
    value: 3,
    icon: Icons.sensors_rounded,
    trend: '1',
  ),
  StatItem(
    label: 'Total Players',
    value: 12482,
    icon: Icons.groups_rounded,
    trend: '18%',
  ),
  StatItem(
    label: 'Hosts',
    value: 24,
    icon: Icons.person_outline_rounded,
    trend: '4%',
  ),
  StatItem(
    label: 'Reports',
    value: 7,
    icon: Icons.warning_amber_rounded,
    trend: '36%',
    trendUp: false,
    trendGood: true,
  ),
];

const List<LiveGame> sampleLiveGames = [
  LiveGame(
    id: '1',
    title: 'Tech Trivia Challenge',
    host: 'Sarah Khan',
    players: 842,
  ),
  LiveGame(
    id: '2',
    title: 'General Knowledge Quiz',
    host: 'Mike Ross',
    players: 621,
  ),
  LiveGame(id: '3', title: 'Science Bowl', host: 'Priya Nair', players: 430),
];

// ======================================================================
// Dashboard
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.userName = 'Alex',
    this.avatar,
    this.stats = sampleStats,
    this.liveGames = sampleLiveGames,
    this.hasUnreadNotifications = true,
    this.currentTab = 0,
    this.onTabSelected,
    this.onRefresh,
    this.onNotifications,
    this.onProfile,
    this.onViewAllGames,
    this.onGameTap,
  });

  final String userName;
  final ImageProvider? avatar;
  final List<StatItem> stats;
  final List<LiveGame> liveGames;
  final bool hasUnreadNotifications;

  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final VoidCallback? onViewAllGames;
  final ValueChanged<LiveGame>? onGameTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final List<Animation<double>> _steps;
  static const int _stepCount = 5;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _steps = List.generate(_stepCount, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _enter,
        curve: Interval(
          start,
          (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final anim = _steps[i.clamp(0, _stepCount - 1)];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      // bottomNavigationBar: AdminBottomNav(
      //   currentIndex: widget.currentTab,
      //   onSelected: widget.onTabSelected,
      // ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHigh,
          onRefresh:
              widget.onRefresh ??
              () => Future<void>.delayed(const Duration(milliseconds: 900)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // ---- Header
              _reveal(
                0,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_greeting, ${widget.userName}!',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Here's what's happening on Buzzer.",
                            style: text.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationBell(
                      showDot: widget.hasUnreadNotifications,
                      onTap: widget.onNotifications,
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onProfile,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: widget.avatar,
                        child: widget.avatar == null
                            ? Text(
                                widget.userName.isEmpty
                                    ? '?'
                                    : widget.userName[0].toUpperCase(),
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ---- Stats (2 per row, last odd one full width)
              ..._buildStatRows(),
              const SizedBox(height: 14),

              // ---- Live games
              _reveal(
                4,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Live Games',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onViewAllGames,
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _LiveGamesTable(
                      games: widget.liveGames,
                      onTap: widget.onGameTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStatRows() {
    final rows = <Widget>[];
    final items = widget.stats;
    for (var i = 0; i < items.length; i += 2) {
      final hasPair = i + 1 < items.length;
      final stagger = 1 + (i ~/ 2); // steps 1..3
      rows.add(
        _reveal(
          stagger,
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: hasPair
                ? Row(
                    children: [
                      Expanded(child: _StatCard(item: items[i])),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(item: items[i + 1])),
                    ],
                  )
                : _StatCard(item: items[i], wide: true),
          ),
        ),
      );
    }
    return rows;
  }
}

// ======================================================================
// Stat card
// ======================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item, this.wide = false});
  final StatItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(item.icon, size: 22, color: cs.onPrimaryContainer),
    );

    final label = Text(
      item.label,
      style: text.bodySmall?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
    );

    final value = _CountUp(
      value: item.value,
      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
    );

    return _SoftCard(
      child: wide
          ? Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [label, value],
                  ),
                ),
                _TrendChip(item: item),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label,
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: value,
                      ),
                      const SizedBox(height: 6),
                      _TrendChip(item: item),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.item});
  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Good news -> tertiary, bad news -> error.
    // (Want a real "success green"? Add a ThemeExtension and swap it in here.)
    final color = item.trendGood ? cs.tertiary : cs.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.trendUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            item.trend,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Number that counts up from 0 when it first appears.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, this.style});
  final int value;
  final TextStyle? style;

  static String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        _format(v.round()),
        style: style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ======================================================================
// Live games table
// ======================================================================

class _LiveGamesTable extends StatelessWidget {
  const _LiveGamesTable({required this.games, this.onTap});
  final List<LiveGame> games;
  final ValueChanged<LiveGame>? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final headStyle = text.labelSmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );

    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('Game', style: headStyle)),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Players',
                    textAlign: TextAlign.end,
                    style: headStyle,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Status',
                    textAlign: TextAlign.end,
                    style: headStyle,
                  ),
                ),
              ],
            ),
          ),
          if (games.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No live games right now',
                style: text.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          for (var i = 0; i < games.length; i++) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
            _GameRow(game: games[i], onTap: onTap),
          ],
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, this.onTap});
  final LiveGame game;
  final ValueChanged<LiveGame>? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!(game);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                game.host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${game.players}',
                textAlign: TextAlign.end,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: StatusBadge(status: game.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Reusable pieces (you'll reuse these on other screens)
// ======================================================================

/// Status chip (LIVE / SCHEDULED / COMPLETED / FLAGGED). LIVE has a pulsing dot.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case GameStatus.live:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        label = 'LIVE';
      case GameStatus.scheduled:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        label = 'SCHEDULED';
      case GameStatus.completed:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        label = 'COMPLETED';
      case GameStatus.flagged:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        label = 'FLAGGED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == GameStatus.live) ...[
            _PulseDot(color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              blurRadius: 2 + 6 * _c.value,
              spreadRadius: 3 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.showDot, this.onTap});
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 26),
          if (showDot)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom navigation shared by Home / Games / Players / Reports / Settings.
class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    this.onSelected,
  });
  final int currentIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
