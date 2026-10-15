import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

enum ReportTarget { game, user }

enum ReportSeverity { high, medium }

class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.date,
    required this.reference,
    required this.reason,
    required this.evidence,
    required this.target,
    this.severity = ReportSeverity.high,
  });

  final String id;
  final String title; // game name or user name
  final String date; // already formatted, e.g. "Apr 25, 2025"
  final String reference; // e.g. "#621"
  final String reason; // e.g. "Cheating suspected"
  final String evidence; // full text; the card shows 1 line until tapped
  final ReportTarget target;

  /// high -> error color, medium -> secondary color
  final ReportSeverity severity;
}

const List<ReportItem> sampleReports = [
  ReportItem(
    id: 'r1',
    title: 'General Knowledge Quiz',
    date: 'Apr 25, 2025',
    reference: '#621',
    reason: 'Cheating suspected',
    evidence: 'Multiple identical answers submitted within milliseconds across 14 accounts.',
    target: ReportTarget.game,
  ),
  ReportItem(
    id: 'r2',
    title: 'Science Bowl',
    date: 'Apr 22, 2025',
    reference: '#430',
    reason: 'Inappropriate behavior',
    evidence: 'Chat message: offensive language directed at other players.',
    target: ReportTarget.game,
  ),
  ReportItem(
    id: 'r3',
    title: 'Math Masters',
    date: 'Apr 18, 2025',
    reference: '#312',
    reason: 'Suspicious activity',
    evidence: 'Unusual response pattern: every answer submitted in under 0.4s.',
    target: ReportTarget.game,
    severity: ReportSeverity.medium,
  ),
  ReportItem(
    id: 'r4',
    title: 'History Quiz',
    date: 'Apr 16, 2025',
    reference: '#280',
    reason: 'Spam / fake account',
    evidence: 'Multiple accounts, same IP address, joined within one minute.',
    target: ReportTarget.game,
  ),
  ReportItem(
    id: 'r5',
    title: 'Rohit Verma',
    date: 'Apr 24, 2025',
    reference: '#BZ30211',
    reason: 'Inappropriate behavior',
    evidence: 'Reported by 5 players for harassment in live game chat.',
    target: ReportTarget.user,
  ),
  ReportItem(
    id: 'r6',
    title: 'Arjun Patel',
    date: 'Apr 21, 2025',
    reference: '#BZ18874',
    reason: 'Suspicious activity',
    evidence: 'Score jumped 4x between two consecutive games.',
    target: ReportTarget.user,
    severity: ReportSeverity.medium,
  ),
];

/// Name suggestion: `ReportsModerationScreen`  (file: reports_moderation_screen.dart)
///
/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class ReportsModerationScreen extends StatefulWidget {
  const ReportsModerationScreen({
    super.key,
    this.reports = sampleReports,
    this.currentTab = 3,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onReview,
  });

  final List<ReportItem> reports;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  /// Open your review / action screen for this report.
  final ValueChanged<ReportItem>? onReview;

  @override
  State<ReportsModerationScreen> createState() =>
      _ReportsModerationScreenState();
}

class _ReportsModerationScreenState extends State<ReportsModerationScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['Flagged Games', 'Flagged Users', 'All Reports'];

  late final TabController _tabController;
  int _index = 0;
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (_tabController.index != _index) {
          HapticFeedback.selectionClick();
          setState(() {
            _previous = _index;
            _index = _tabController.index;
          });
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ReportItem> _itemsFor(int tab) => switch (tab) {
    0 => widget.reports.where((r) => r.target == ReportTarget.game).toList(),
    1 => widget.reports.where((r) => r.target == ReportTarget.user).toList(),
    _ => widget.reports,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final forward = _index >= _previous;
    final items = _itemsFor(_index);

    return Scaffold(
      backgroundColor: cs.surface,
      // bottomNavigationBar: AdminBottomNav(
      //   currentIndex: widget.currentTab,
      //   onSelected: widget.onTabSelected,
      // ),
      body: SafeArea(
        bottom: false,
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
                    'Reports & Moderation',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ---- Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _buildTabBar(cs),
            ),

            // ---- List
            Expanded(
              child: RefreshIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHigh,
                onRefresh:
                    widget.onRefresh ??
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 900)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(forward ? 0.05 : -0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: items.isEmpty
                      ? _EmptyState(key: ValueKey('empty-$_index'))
                      : ListView.separated(
                          key: ValueKey('list-$_index'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _Entry(
                            index: i,
                            child: _ReportCard(
                              item: items[i],
                              colorIndex: i,
                              onReview: widget.onReview == null
                                  ? null
                                  : () => widget.onReview!(items[i]),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(12),
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.65),
        labelStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        tabs: [
          for (var i = 0; i < _tabs.length; i++)
            Tab(
              height: 38,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_tabs[i]),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _index == i
                            ? cs.onPrimary.withValues(alpha: 0.22)
                            : cs.onSurface.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_itemsFor(i).length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _index == i ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================================
// Report card (tap to expand the evidence text)
// ======================================================================

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.item,
    required this.colorIndex,
    this.onReview,
  });

  final ReportItem item;
  final int colorIndex;
  final VoidCallback? onReview;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final item = widget.item;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    final severityColor = item.severity == ReportSeverity.high
        ? cs.error
        : cs.secondary;

    // Rotate through themed container colors for the leading tile.
    final (Color tileBg, Color tileFg) = switch (widget.colorIndex % 3) {
      0 => (cs.primaryContainer, cs.onPrimaryContainer),
      1 => (cs.secondaryContainer, cs.onSecondaryContainer),
      _ => (cs.tertiaryContainer, cs.onTertiaryContainer),
    };

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.target == ReportTarget.game
                      ? Icons.bolt_rounded
                      : Icons.person_rounded,
                  size: 24,
                  color: tileFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.date} · ${item.reference}',
                      style: text.labelSmall?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: severityColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            item.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelMedium?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topLeft,
                      child: Text.rich(
                        TextSpan(
                          text: 'Evidence: ',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: item.evidence,
                              style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        maxLines: _expanded ? null : 1,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: widget.onReview == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            widget.onReview!();
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      foregroundColor: cs.primary,
                      side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                  const SizedBox(height: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Small shared bits
// ======================================================================

class _Entry extends StatelessWidget {
  const _Entry({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index.clamp(0, 8) * 70),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // ListView so pull-to-refresh still works on the empty state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 72),
        _Entry(
          index: 0,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 36,
                  color: cs.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All clear',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Nothing to review here right now.',
                style: text.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
