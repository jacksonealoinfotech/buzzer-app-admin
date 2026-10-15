import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

enum HostStatus { verified, pending, suspended }

enum HostFilter { all, verified, pending, suspended }

enum HostSort { name, status, games }

/// Actions in the long-press sheet.
enum HostAction { view, verify, suspend, reinstate }

class HostItem {
  const HostItem({
    required this.id,
    required this.name,
    required this.status,
    required this.hostedGames,
    this.avatar,
  });

  final String id;
  final String name;
  final HostStatus status;
  final int hostedGames;
  final ImageProvider? avatar;
}

const List<HostItem> sampleHosts = [
  HostItem(
    id: '1',
    name: 'Sarah Khan',
    status: HostStatus.verified,
    hostedGames: 12,
  ),
  HostItem(
    id: '2',
    name: 'Mike Ross',
    status: HostStatus.verified,
    hostedGames: 10,
  ),
  HostItem(
    id: '3',
    name: 'Priya Nair',
    status: HostStatus.verified,
    hostedGames: 9,
  ),
  HostItem(
    id: '4',
    name: 'David Chen',
    status: HostStatus.verified,
    hostedGames: 8,
  ),
  HostItem(
    id: '5',
    name: 'Neha Kapoor',
    status: HostStatus.pending,
    hostedGames: 4,
  ),
  HostItem(
    id: '6',
    name: 'Arjun Patel',
    status: HostStatus.suspended,
    hostedGames: 2,
  ),
];

// ======================================================================
// Screen
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class HostsManagementScreen extends StatefulWidget {
  const HostsManagementScreen({
    super.key,
    this.hosts = sampleHosts,
    this.currentTab = 4,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onHostTap,
    this.onHostAction,
  });

  final List<HostItem> hosts;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final ValueChanged<HostItem>? onHostTap;

  /// Called after the admin picks an action (suspend is confirmed first).
  final void Function(HostItem host, HostAction action)? onHostAction;

  @override
  State<HostsManagementScreen> createState() => _HostsManagementScreenState();
}

class _HostsManagementScreenState extends State<HostsManagementScreen> {
  final _searchCtrl = TextEditingController();
  HostFilter _filter = HostFilter.all;
  HostSort _sort = HostSort.games;
  bool _ascending = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(HostItem h) => switch (_filter) {
    HostFilter.all => true,
    HostFilter.verified => h.status == HostStatus.verified,
    HostFilter.pending => h.status == HostStatus.pending,
    HostFilter.suspended => h.status == HostStatus.suspended,
  };

  List<HostItem> get _visible {
    final q = _query.trim().toLowerCase();
    final list = widget.hosts
        .where(
          (h) => _matches(h) && (q.isEmpty || h.name.toLowerCase().contains(q)),
        )
        .toList();

    int cmp(HostItem a, HostItem b) => switch (_sort) {
      HostSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      HostSort.status => a.status.index.compareTo(b.status.index),
      HostSort.games => a.hostedGames.compareTo(b.hostedGames),
    };

    list.sort((a, b) => _ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  void _onSort(HostSort s) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sort == s) {
        _ascending = !_ascending;
      } else {
        _sort = s;
        _ascending = s != HostSort.games; // games defaults to high -> low
      }
    });
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _filter = HostFilter.all;
    });
  }

  Future<void> _showActions(HostItem h) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<HostAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActionSheet(host: h),
    );
    if (action == null || !mounted) return;

    // Confirm the destructive one.
    if (action == HostAction.suspend) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            icon: Icon(Icons.block_rounded, color: cs.error),
            title: Text('Suspend ${h.name}?'),
            content: const Text(
              'They won\'t be able to host games until you reinstate them.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                child: const Text('Suspend'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;
    }
    widget.onHostAction?.call(h, action);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hosts = _visible;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: widget.currentTab,
        onSelected: widget.onTabSelected,
      ),
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
                      'Hosts Management',
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
                    hintText: 'Search hosts...',
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
                  itemCount: HostFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = HostFilter.values[i];
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
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            _TableHeader(
                              sort: _sort,
                              ascending: _ascending,
                              onSort: _onSort,
                              count: hosts.length,
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
                                child: hosts.isEmpty
                                    ? _EmptyState(onClear: _clearAll)
                                    : ListView.separated(
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: hosts.length,
                                        separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          indent: 16,
                                          endIndent: 16,
                                          color: cs.outlineVariant.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        itemBuilder: (context, i) {
                                          final h = hosts[i];
                                          return _Entry(
                                            key: ValueKey(
                                              '${h.id}-${_filter.name}',
                                            ),
                                            index: i,
                                            child: _HostRow(
                                              host: h,
                                              onTap: widget.onHostTap == null
                                                  ? null
                                                  : () => widget.onHostTap!(h),
                                              onLongPress: () =>
                                                  _showActions(h),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterLabel(HostFilter f) => switch (f) {
    HostFilter.all => 'All',
    HostFilter.verified => 'Verified',
    HostFilter.pending => 'Pending',
    HostFilter.suspended => 'Suspended',
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

  final HostSort sort;
  final bool ascending;
  final ValueChanged<HostSort> onSort;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _HeaderCell(
              label: 'Host ($count)',
              active: sort == HostSort.name,
              ascending: ascending,
              onTap: () => onSort(HostSort.name),
            ),
          ),
          Expanded(
            flex: 3,
            child: _HeaderCell(
              label: 'Status',
              active: sort == HostSort.status,
              ascending: ascending,
              onTap: () => onSort(HostSort.status),
            ),
          ),
          Expanded(
            flex: 4,
            child: _HeaderCell(
              label: 'Hosted Games',
              active: sort == HostSort.games,
              ascending: ascending,
              alignEnd: true,
              onTap: () => onSort(HostSort.games),
            ),
          ),
          const SizedBox(width: 24), // room for the row chevron
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
                turns: ascending ? 0.5 : 0,
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

class _HostRow extends StatelessWidget {
  const _HostRow({required this.host, this.onTap, required this.onLongPress});
  final HostItem host;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

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
              flex: 5,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: host.avatar,
                    child: host.avatar == null
                        ? Text(
                            host.name.isEmpty
                                ? '?'
                                : host.name[0].toUpperCase(),
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
                      host.name,
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
                child: HostStatusBadge(status: host.status),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                '${host.hostedGames}',
                textAlign: TextAlign.end,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable anywhere a host status is shown (e.g. Game Details).
class HostStatusBadge extends StatelessWidget {
  const HostStatusBadge({super.key, required this.status});
  final HostStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color bg, Color fg, String label) = switch (status) {
      HostStatus.verified => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        'Verified',
      ),
      HostStatus.pending => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        'Pending',
      ),
      HostStatus.suspended => (
        cs.errorContainer,
        cs.onErrorContainer,
        'Suspended',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
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
  const _ActionSheet({required this.host});
  final HostItem host;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget tile(HostAction a, IconData icon, String label, {Color? color}) =>
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
                  backgroundImage: host.avatar,
                  child: host.avatar == null
                      ? Text(
                          host.name.isEmpty ? '?' : host.name[0],
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
                    host.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                HostStatusBadge(status: host.status),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
          tile(HostAction.view, Icons.person_outline_rounded, 'View host'),
          if (host.status == HostStatus.pending)
            tile(HostAction.verify, Icons.verified_outlined, 'Verify host'),
          if (host.status == HostStatus.suspended)
            tile(
              HostAction.reinstate,
              Icons.lock_open_rounded,
              'Reinstate host',
            )
          else
            tile(
              HostAction.suspend,
              Icons.block_rounded,
              'Suspend host',
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
                'No hosts found',
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
