import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:buzzer_app_admin/features/player_directory/presenation/screen/player_directory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Shared pieces from earlier screens (keep all files in the same folder)

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

class PlayHistoryItem {
  const PlayHistoryItem({
    required this.id,
    required this.gameTitle,
    required this.date,
    required this.score,
    required this.rank,
  });

  final String id;
  final String gameTitle;
  final String date; // already formatted, e.g. "Apr 26, 2025"
  final int score;
  final int rank;
}

enum AchievementTone { primary, secondary, tertiary }

class Achievement {
  const Achievement({
    required this.title,
    required this.count,
    required this.icon,
    this.tone = AchievementTone.primary,
  });

  final String title;
  final int count;
  final IconData icon;
  final AchievementTone tone;
}

class PlayerProfileData {
  const PlayerProfileData({
    required this.name,
    required this.playerId,
    required this.totalGames,
    required this.wins,
    required this.avgScore,
    required this.history,
    required this.achievements,
    this.status = PlayerStatus.active,
    this.verified = true,
    this.topPercent,
    this.avatar,
  });

  final String name;
  final String playerId; // e.g. "#BZ45231"
  final int totalGames;
  final int wins;
  final int avgScore;
  final List<PlayHistoryItem> history;
  final List<Achievement> achievements;
  final PlayerStatus status;
  final bool verified;

  /// e.g. 5 -> "Top 5%". Null hides the chip.
  final int? topPercent;
  final ImageProvider? avatar;
}

const PlayerProfileData sampleProfile = PlayerProfileData(
  name: 'Riya Sharma',
  playerId: '#BZ45231',
  totalGames: 24,
  wins: 8,
  avgScore: 2845,
  topPercent: 5,
  history: [
    PlayHistoryItem(
      id: '1',
      gameTitle: 'Tech Trivia Challenge',
      date: 'Apr 26, 2025',
      score: 3420,
      rank: 3,
    ),
    PlayHistoryItem(
      id: '2',
      gameTitle: 'General Knowledge Quiz',
      date: 'Apr 24, 2025',
      score: 2980,
      rank: 5,
    ),
    PlayHistoryItem(
      id: '3',
      gameTitle: 'Science Bowl',
      date: 'Apr 20, 2025',
      score: 2760,
      rank: 7,
    ),
  ],
  achievements: [
    Achievement(
      title: 'Top Scorer',
      count: 3,
      icon: Icons.emoji_events_rounded,
      tone: AchievementTone.secondary,
    ),
    Achievement(
      title: 'Quick Thinker',
      count: 5,
      icon: Icons.psychology_rounded,
      tone: AchievementTone.primary,
    ),
    Achievement(
      title: 'Consistency',
      count: 10,
      icon: Icons.shield_rounded,
      tone: AchievementTone.tertiary,
    ),
  ],
);

// ======================================================================
// Screen
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    super.key,
    this.data = sampleProfile,
    this.currentTab = 2,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onViewAllHistory,
    this.onHistoryTap,
    this.onAction,
  });

  final PlayerProfileData data;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onViewAllHistory;
  final ValueChanged<PlayHistoryItem>? onHistoryTap;

  /// Admin actions (flag / ban / approve ...) from the top-right menu.
  final ValueChanged<PlayerAction>? onAction;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  void _copyId() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.data.playerId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Player ID copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = widget.data;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: widget.currentTab,
        onSelected: widget.onTabSelected,
      ),
      body: SafeArea(
        bottom: false,
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
                      'Player Profile',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.onAction != null)
                    _AdminMenu(status: d.status, onSelected: widget.onAction!),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHigh,
                onRefresh:
                    widget.onRefresh ??
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 900)),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _Entry(index: 0, child: _buildHeader(cs, text, d)),
                    const SizedBox(height: 12),
                    _Entry(index: 1, child: _StatsCard(data: d)),
                    const SizedBox(height: 20),
                    _Entry(
                      index: 2,
                      child: _SectionHeader(
                        title: 'Recent Play History',
                        actionLabel: 'View all',
                        onAction: widget.onViewAllHistory,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Entry(
                      index: 3,
                      child: _HistoryCard(
                        items: d.history,
                        onTap: widget.onHistoryTap,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Entry(
                      index: 4,
                      child: const _SectionHeader(title: 'Achievements'),
                    ),
                    const SizedBox(height: 8),
                    _Entry(
                      index: 5,
                      child: _AchievementsCard(items: d.achievements),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, TextTheme text, PlayerProfileData d) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with slowly rotating gradient ring
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) => Transform.rotate(
                    angle: _ring.value * 2 * math.pi,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            cs.primary,
                            cs.tertiary,
                            cs.primary.withValues(alpha: 0.15),
                            cs.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerLowest,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: d.avatar,
                    child: d.avatar == null
                        ? Text(
                            d.name.isEmpty ? '?' : d.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (d.verified) ...[
                      const SizedBox(width: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _copyId,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Player ID: ${d.playerId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (d.status != PlayerStatus.active)
                      PlayerStatusBadge(status: d.status),
                    if (d.topPercent != null)
                      _Chip(
                        icon: Icons.emoji_events_rounded,
                        label: 'Top ${d.topPercent}%',
                        bg: cs.secondaryContainer,
                        fg: cs.onSecondaryContainer,
                      ),
                    if (d.verified)
                      _Chip(
                        icon: Icons.check_rounded,
                        label: 'Verified',
                        bg: cs.tertiaryContainer,
                        fg: cs.onTertiaryContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Stats
// ======================================================================

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});
  final PlayerProfileData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget divider() => Container(
      width: 1,
      height: 36,
      color: cs.outlineVariant.withValues(alpha: 0.7),
    );

    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _Stat(label: 'Total Games', value: data.totalGames),
          ),
          divider(),
          Expanded(
            child: _Stat(label: 'Wins', value: data.wins),
          ),
          divider(),
          Expanded(
            child: _Stat(label: 'Avg. Score', value: data.avgScore),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            _fmt(v.round()),
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// History
// ======================================================================

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.items, this.onTap});
  final List<PlayHistoryItem> items;
  final ValueChanged<PlayHistoryItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return _Card(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No games played yet',
            style: text.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            _HistoryRow(item: items[i], onTap: onTap),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, this.onTap});
  final PlayHistoryItem item;
  final ValueChanged<PlayHistoryItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final podium = item.rank <= 3;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!(item);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 22,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.gameTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.date,
                    style: text.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmt(item.score),
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: podium ? cs.primaryContainer : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${item.rank}',
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: podium
                      ? cs.onPrimaryContainer
                      : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Achievements
// ======================================================================

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({required this.items});
  final List<Achievement> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return _Card(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No achievements yet',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            height: 70,
            color: cs.outlineVariant.withValues(alpha: 0.7),
          ),
        );
      }
      children.add(
        Expanded(
          child: _AchievementTile(item: items[i], index: i),
        ),
      );
    }

    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: children),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item, required this.index});
  final Achievement item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (Color bg, Color fg) = switch (item.tone) {
      AchievementTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      AchievementTone.secondary => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      AchievementTone.tertiary => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 180),
      curve: Curves.elasticOut,
      builder: (context, v, child) =>
          Transform.scale(scale: v.clamp(0.0, 1.2), child: child),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: fg.withValues(alpha: 0.25), width: 2),
            ),
            child: Icon(item.icon, size: 28, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '(${item.count}x)',
            style: text.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Admin menu
// ======================================================================

class _AdminMenu extends StatelessWidget {
  const _AdminMenu({required this.status, required this.onSelected});
  final PlayerStatus status;
  final ValueChanged<PlayerAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    PopupMenuItem<PlayerAction> item(
      PlayerAction a,
      IconData icon,
      String label, {
      Color? color,
    }) => PopupMenuItem(
      value: a,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );

    return PopupMenuButton<PlayerAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert_rounded),
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (status == PlayerStatus.pending)
          item(
            PlayerAction.approve,
            Icons.check_circle_outline_rounded,
            'Approve player',
          ),
        if (status == PlayerStatus.flagged)
          item(PlayerAction.clearFlag, Icons.flag_outlined, 'Clear flag')
        else if (status != PlayerStatus.banned)
          item(PlayerAction.flag, Icons.outlined_flag_rounded, 'Flag player'),
        if (status == PlayerStatus.banned)
          item(PlayerAction.unban, Icons.lock_open_rounded, 'Unban player')
        else
          item(
            PlayerAction.ban,
            Icons.block_rounded,
            'Ban player',
            color: cs.error,
          ),
      ],
    );
  }
}

// ======================================================================
// Small shared bits
// ======================================================================

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
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
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index.clamp(0, 6) * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
