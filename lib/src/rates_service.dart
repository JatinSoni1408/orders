part of '../main.dart';

class _RatesRepository {
  const _RatesRepository();

  static const String _projectId = 'shubham-jewellers-1976';
  static const String _apiKey = 'AIzaSyCoR4bdnNAFxCPFxwNj6sTSsU6sc2m5e6o';

  Future<_AppRates> fetchRates() async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/app_config/rates',
      {'key': _apiKey},
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore rate request failed with status ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Firestore response.');
    }

    return _AppRates.fromFirestoreDocument(body);
  }
}

class _AppRates {
  const _AppRates({
    required this.gold24Rate,
    required this.gold18Rate,
    required this.gold22Rate,
    required this.silverRate,
    this.updatedAt,
    this.updatedByEmail,
  });

  factory _AppRates.fromFirestoreDocument(Map<String, dynamic> document) {
    final fields = document['fields'];
    if (fields is! Map<String, dynamic>) {
      throw const FormatException('Firestore rates document is missing fields.');
    }

    return _AppRates(
      gold24Rate: _numberField(fields['rate_gold24']),
      gold18Rate: _numberField(fields['rate_gold18']),
      gold22Rate: _numberField(fields['rate_gold22']),
      silverRate: _numberField(fields['rate_silver']),
      updatedAt: _timestampField(fields['updatedAt']),
      updatedByEmail: _stringField(fields['updatedByEmail']),
    );
  }

  final double gold24Rate;
  final double gold18Rate;
  final double gold22Rate;
  final double silverRate;
  final DateTime? updatedAt;
  final String? updatedByEmail;

  static double _numberField(dynamic rawField) {
    if (rawField is! Map<String, dynamic>) {
      return 0;
    }
    final intValue = rawField['integerValue'];
    if (intValue != null) {
      return double.tryParse(intValue.toString()) ?? 0;
    }
    final doubleValue = rawField['doubleValue'];
    if (doubleValue != null) {
      return double.tryParse(doubleValue.toString()) ?? 0;
    }
    final stringValue = rawField['stringValue'];
    if (stringValue != null) {
      return double.tryParse(stringValue.toString()) ?? 0;
    }
    return 0;
  }

  static DateTime? _timestampField(dynamic rawField) {
    if (rawField is! Map<String, dynamic>) {
      return null;
    }
    final timestampValue = rawField['timestampValue'];
    if (timestampValue == null) {
      return null;
    }
    return DateTime.tryParse(timestampValue.toString())?.toLocal();
  }

  static String? _stringField(dynamic rawField) {
    if (rawField is! Map<String, dynamic>) {
      return null;
    }
    final value = rawField['stringValue'];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
