import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_base_template/core/error/app_exception.dart';
import 'package:flutter_base_template/core/localization/locale_cubit.dart';
import 'package:flutter_base_template/core/responsive/app_spacing.dart';
import 'package:flutter_base_template/core/responsive/responsive_context.dart';
import 'package:flutter_base_template/core/result/result.dart';
import 'package:flutter_base_template/core/theme/theme_context_extensions.dart';
import 'package:flutter_base_template/core/theme/theme_cubit.dart';
import 'package:flutter_base_template/core/widgets/animations/app_animate.dart';
import 'package:flutter_base_template/core/widgets/animations/shimmer.dart';
import 'package:flutter_base_template/core/widgets/animations/staggered_animation.dart';
import 'package:flutter_base_template/core/widgets/buttons/app_button.dart';
import 'package:flutter_base_template/core/widgets/display/common_components.dart';
import 'package:flutter_base_template/core/widgets/feedback/messenger_service.dart';
import 'package:flutter_base_template/core/widgets/inputs/app_text_field.dart';
import 'package:flutter_base_template/core/widgets/inputs/search_field.dart';
import 'package:flutter_base_template/core/widgets/scaffold/app_scaffold.dart';
import 'package:flutter_base_template/core/widgets/views/async_state_view.dart';

/// Interactive showcase screen verifying all core features:
/// - M3 theme switching
/// - Responsive adaptive layout
/// - Micro-animations & Shimmer loaders
/// - Accessible widgets & buttons
/// - Result<T> pattern matching with safeCall()
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  bool _isButtonLoading = false;
  Result<String>? _apiResult;
  bool _isApiLoading = false;
  String _searchQuery = '';

  // Simulates clean architecture repository call with Result<T>
  Future<void> _simulateApiCall({required String scenario}) async {
    setState(() => _isApiLoading = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final result = await safeCall<String>(() async {
      return switch (scenario) {
        'success' => 'Production Clean Architecture template loaded successfully!',
        'network_error' => throw const NetworkException(),
        'unauthorized' => throw const UnauthorizedException(),
        'server_error' => throw const ServerException(statusCode: 500),
        'not_found' => throw const NotFoundException(),
        _ => throw const UnknownException(),
      };
    });

    if (mounted) {
      setState(() {
        _isApiLoading = false;
        _apiResult = result;
      });

      // Exhaustive pattern matching example
      switch (result) {
        case Success(:final data):
          MessengerService.showSuccess('Result: Success - $data');
        case FailureResult(:final failure):
          MessengerService.showError('Result: ${failure.runtimeType} - ${failure.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Flutter Clean Architecture'),
        actions: [
          IconButton(
            tooltip: 'Language Toggle',
            icon: const Icon(Icons.language_rounded),
            onPressed: () => context.read<LocaleCubit>().toggleLocale(),
          ),
          IconButton(
            tooltip: 'Theme Toggle',
            icon: Icon(
              context.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            tooltip: 'Security Self-Check',
            icon: const Icon(Icons.security_rounded),
            onPressed: () => context.push('/security-check'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. Hero Card
          _buildHeroCard(context),
          Gap.v16,

          // 2. Responsive Status
          _buildResponsiveCard(context),
          Gap.v24,

          // 3. Clean Architecture Result<T> Interactive Pipeline
          const SectionHeader(
            title: 'Result<T> & Error Handling Pipeline',
            subtitle: 'Tested with safeCall() and exhaustive pattern matching',
          ),
          _buildResultDemo(context),
          Gap.v24,

          // 4. Buttons & Interactions
          const SectionHeader(
            title: 'Accessible Buttons (48dp Touch Targets)',
            subtitle: 'Loading states, icon prefixes, tonal & semantic variants',
          ),
          _buildButtonsDemo(context),
          Gap.v24,

          // 5. Inputs & Form Fields
          const SectionHeader(
            title: 'Form Inputs & Debounce',
            subtitle: 'Material 3 styling with clear action and search debouncer',
          ),
          _buildInputsDemo(context),
          Gap.v24,

          // 6. Animations & Shimmer
          const SectionHeader(
            title: 'Micro-Interactions & Shimmer',
            subtitle: 'Reduced-motion aware animation system',
          ),
          _buildAnimationsDemo(context),
          Gap.v32,
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return AppAnimate(
      type: AnimationType.slideUp,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: context.gradients.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.shadows.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Production-Grade Base Template',
                  style: context.text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Gap.v8,
            const Text(
              'Clean Architecture • Dart 3.x Sealed Classes • sqflite • Typed GoRouter • OWASP MASVS Hardened',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            Gap.v16,
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => context.push('/security-check'),
                  child: const Text('Open Security Check'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => context.push('/explore'),
                  child: const Text('Explore Shell Tab'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCard(BuildContext context) {
    final colors = context.colors;
    final sizeClass = context.windowSizeClass;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              switch (sizeClass.name) {
                'compact' => Icons.phone_android_rounded,
                'medium' => Icons.tablet_rounded,
                _ => Icons.desktop_windows_rounded,
              },
              size: 32,
              color: colors.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window Class: ${sizeClass.name.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Width: ${context.screenWidth.toStringAsFixed(0)}dp • Height: ${context.screenHeight.toStringAsFixed(0)}dp',
                    style: context.text.bodySmall?.copyWith(color: colors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  text: 'Simulate 200 OK',
                  variant: ButtonVariant.primary,
                  onPressed: () => _simulateApiCall(scenario: 'success'),
                ),
                AppButton(
                  text: 'Simulate 401 Auth',
                  variant: ButtonVariant.tonal,
                  onPressed: () => _simulateApiCall(scenario: 'unauthorized'),
                ),
                AppButton(
                  text: 'Simulate Network Error',
                  variant: ButtonVariant.outlined,
                  onPressed: () => _simulateApiCall(scenario: 'network_error'),
                ),
                AppButton(
                  text: 'Simulate 500 Crash',
                  variant: ButtonVariant.danger,
                  onPressed: () => _simulateApiCall(scenario: 'server_error'),
                ),
              ],
            ),
            Gap.v16,
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AsyncStateView<String>(
                isLoading: _isApiLoading,
                result: _apiResult,
                initialBuilder: (_) => const Text(
                  'Tap any scenario button above to test the safeCall() pipeline.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                dataBuilder: (context, data) => Text(
                  'SUCCESS: $data',
                  style: TextStyle(
                    color: context.semanticColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              text: 'Primary Button',
              icon: const Icon(Icons.check_rounded, size: 18),
              onPressed: () => MessengerService.showSuccess('Primary clicked'),
            ),
            AppButton(
              text: 'Tonal Button',
              variant: ButtonVariant.tonal,
              onPressed: () => MessengerService.showSuccess('Tonal clicked'),
            ),
            AppButton(
              text: 'Outlined Button',
              variant: ButtonVariant.outlined,
              onPressed: () => MessengerService.showSuccess('Outlined clicked'),
            ),
            AppButton(
              text: 'Danger Button',
              variant: ButtonVariant.danger,
              onPressed: () => MessengerService.showError('Danger clicked'),
            ),
            AppButton(
              text: 'Toggle Loading',
              isLoading: _isButtonLoading,
              onPressed: () {
                setState(() => _isButtonLoading = true);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _isButtonLoading = false);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputsDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SearchField(
              hintText: 'Type to test 350ms debouncer...',
              onSearch: (q) => setState(() => _searchQuery = q),
            ),
            if (_searchQuery.isNotEmpty) ...[
              Gap.v8,
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Debounced Query: "$_searchQuery"'),
              ),
            ],
            Gap.v16,
            const AppTextField(
              labelText: 'Standard Text Input',
              hintText: 'Enter value',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationsDemo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shimmer Skeletons:', style: TextStyle(fontWeight: FontWeight.bold)),
            Gap.v8,
            Row(
              children: [
                AppShimmer.circle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer.box(width: double.infinity, height: 16),
                      const SizedBox(height: 6),
                      AppShimmer.box(width: 140, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            Gap.v16,
            const Text('Staggered Animated Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            Gap.v8,
            ...List.generate(3, (index) {
              return StaggeredAnimation(
                index: index,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: context.colors.surfaceContainer,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: Text('Staggered Item ${index + 1}'),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
