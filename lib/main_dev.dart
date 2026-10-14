import 'package:buzzer_app_admin/app.dart';
import 'package:buzzer_app_admin/bootstrap.dart';
import 'package:buzzer_app_admin/core/config/flavor.dart';

void main() {
  bootstrap(flavor: Flavor.dev, builder: () => const App());
}
