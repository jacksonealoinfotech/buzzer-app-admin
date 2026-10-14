import 'package:buzzer_app_admin/app.dart';
import 'package:buzzer_app_admin/bootstrap.dart';
import 'package:buzzer_app_admin/core/config/flavor.dart';

/// Default local run entry point (defaults to dev flavor).
void main() {
  bootstrap(flavor: Flavor.dev, builder: () => const App());
}
