import 'package:flutter_base_template/app.dart';
import 'package:flutter_base_template/bootstrap.dart';
import 'package:flutter_base_template/core/config/flavor.dart';

void main() {
  bootstrap(
    flavor: Flavor.staging,
    builder: () => const App(),
  );
}
