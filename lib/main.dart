import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'src/order_models.dart';
part 'src/order_app.dart';
part 'src/orders_dashboard.dart';
part 'src/order_widgets.dart';
part 'src/order_form_sheet.dart';
part 'src/print_preview.dart';
part 'src/formatting.dart';
part 'src/bhav_page.dart';
part 'src/auth_service.dart';
part 'src/rates_service.dart';
part 'src/app_sync_service.dart';
part 'src/tag_service.dart';
part 'src/qr_scanner_page.dart';

bool get _shouldLockPortrait =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get _supportsQrScanning =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

AppAccessRole? get _requiredAccessRoleForPlatform {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return AppAccessRole.admin;
  }
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return AppAccessRole.user;
  }
  return null;
}

String get _platformAppTitle {
  switch (_requiredAccessRoleForPlatform) {
    case AppAccessRole.admin:
      return 'Jewellery Admin';
    case AppAccessRole.user:
    case null:
      return 'Jewellery Orders';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_shouldLockPortrait) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const OrderApp());
}
