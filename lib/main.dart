import 'package:flutter_base_template/app.dart';
import 'package:flutter_base_template/bootstrap.dart';
import 'package:flutter_base_template/core/config/flavor.dart';

/// Default local run entry point (defaults to dev flavor).
void main() {
  bootstrap(
    flavor: Flavor.dev,
    builder: () => const App(),
  );
}
