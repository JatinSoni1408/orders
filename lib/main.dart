import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'src/order_models.dart';
part 'src/order_app.dart';
part 'src/orders_dashboard.dart';
part 'src/order_widgets.dart';
part 'src/order_form_sheet.dart';
part 'src/print_preview.dart';
part 'src/formatting.dart';
part 'src/bhav_page.dart';

void main() {
  runApp(const OrderApp());
}
