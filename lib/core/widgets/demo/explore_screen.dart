import 'package:flutter/material.dart';
import 'package:buzzer_app_admin/core/responsive/app_spacing.dart';
import 'package:buzzer_app_admin/core/widgets/display/common_components.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(
            title: 'Explore Architecture Modules',
            subtitle: 'Shell navigation tab preserving independent state',
          ),
          ...List.generate(5, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('Architecture Pattern ${index + 1}'),
                subtitle: const Text(
                  'Demonstrating StatefulShellRoute state persistence',
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
            );
          }),
        ],
      ),
    );
  }
}
