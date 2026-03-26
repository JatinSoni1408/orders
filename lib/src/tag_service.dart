part of '../main.dart';

class _TagImportService {
  const _TagImportService();

  static const String _projectId = 'shubham-jewellers-1976';
  static const String _apiKey = 'AIzaSyCoR4bdnNAFxCPFxwNj6sTSsU6sc2m5e6o';

  Future<_ImportedTagData> fetchTagFromQr(String rawQr) async {
    final tagId = _extractTagId(rawQr);
    if (tagId == null) {
      throw const FormatException('Scan a valid QR tag.');
    }
    return fetchTag(tagId);
  }

  Future<_ImportedTagData> fetchTag(String tagId) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/tags/$tagId',
      {'key': _apiKey},
    );
    final response = await http.get(uri);
    if (response.statusCode == 404) {
      throw StateError('Tag not found in Firestore.');
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Tag lookup failed with status ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Firestore tag response.');
    }
    return _ImportedTagData.fromFirestoreDocument(body);
  }

  String? _extractTagId(String rawQr) {
    final text = rawQr.trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.startsWith('QR1:')) {
      final id = text.substring(4).trim();
      return id.isEmpty ? null : id;
    }
    return text;
  }
}

class _ImportedTagData {
  const _ImportedTagData({
    required this.sourceTagId,
    required this.name,
    required this.category,
    required this.makingType,
    required this.isHuid,
    required this.makingChargeText,
    required this.grossWeightText,
    required this.lessWeightText,
    required this.additionalChargeText,
    required this.notes,
  });

  factory _ImportedTagData.fromFirestoreDocument(Map<String, dynamic> document) {
    final fields = document['fields'];
    if (fields is! Map<String, dynamic>) {
      throw const FormatException('Firestore tag document is missing fields.');
    }

    final decoded = _decodeFields(fields);
    final sourceTagId =
        document['name']?.toString().split('/').last.trim() ?? '';
    final category = _normalizeCategory(decoded['category']?.toString());
    if (category == null) {
      throw StateError('This tag category is not supported in New Items.');
    }

    final makingType = _normalizeMakingType(
      category: category,
      raw: decoded['makingType']?.toString(),
    );
    final isHuid = _boolValue(decoded['huid']);
    final makingChargeText = _stringValue(decoded['makingCharge']);
    final grossWeightText = _stringValue(decoded['grossWeight']);
    final lessWeightText = _stringValue(
      decoded['lessWeight'] ?? _sumEntryValues(decoded['lessCategories']),
    );
    final additionalChargeText = _stringValue(
      _sumEntryValues(decoded['additionalTypes']),
    );
    final notes = _buildNotes(
      sourceTagId: sourceTagId,
      location: decoded['location']?.toString(),
      lessCategories: decoded['lessCategories'],
      additionalTypes: decoded['additionalTypes'],
    );

    return _ImportedTagData(
      sourceTagId: sourceTagId,
      name: decoded['itemName']?.toString().trim().isNotEmpty == true
          ? decoded['itemName'].toString().trim()
          : 'Imported Tag',
      category: category,
      makingType: makingType,
      isHuid: isHuid,
      makingChargeText: makingChargeText,
      grossWeightText: grossWeightText,
      lessWeightText: lessWeightText,
      additionalChargeText: additionalChargeText,
      notes: notes,
    );
  }

  final String sourceTagId;
  final String name;
  final String category;
  final String makingType;
  final bool isHuid;
  final String makingChargeText;
  final String grossWeightText;
  final String lessWeightText;
  final String additionalChargeText;
  final String notes;

  static Map<String, dynamic> _decodeFields(Map<String, dynamic> fields) {
    return fields.map(
      (key, value) => MapEntry(key, _decodeFirestoreValue(value)),
    );
  }

  static dynamic _decodeFirestoreValue(dynamic rawField) {
    if (rawField is! Map<String, dynamic>) {
      return null;
    }
    if (rawField.containsKey('stringValue')) {
      return rawField['stringValue'];
    }
    if (rawField.containsKey('integerValue')) {
      return double.tryParse(rawField['integerValue'].toString()) ?? 0;
    }
    if (rawField.containsKey('doubleValue')) {
      return double.tryParse(rawField['doubleValue'].toString()) ?? 0;
    }
    if (rawField.containsKey('booleanValue')) {
      return rawField['booleanValue'] == true;
    }
    if (rawField.containsKey('timestampValue')) {
      return rawField['timestampValue'];
    }
    if (rawField.containsKey('nullValue')) {
      return null;
    }
    if (rawField.containsKey('mapValue')) {
      final mapValue = rawField['mapValue'];
      if (mapValue is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }
      final fields = mapValue['fields'];
      if (fields is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }
      return _decodeFields(fields);
    }
    if (rawField.containsKey('arrayValue')) {
      final arrayValue = rawField['arrayValue'];
      if (arrayValue is! Map<String, dynamic>) {
        return <dynamic>[];
      }
      final values = arrayValue['values'];
      if (values is! List) {
        return <dynamic>[];
      }
      return values.map(_decodeFirestoreValue).toList();
    }
    return null;
  }

  static String? _normalizeCategory(String? raw) {
    final value = (raw ?? '').trim();
    if (value == 'Gold22kt' || value == 'Gold18kt' || value == 'Silver') {
      return value;
    }
    final lower = value.toLowerCase();
    if (lower.contains('22')) {
      return 'Gold22kt';
    }
    if (lower.contains('18')) {
      return 'Gold18kt';
    }
    if (lower.contains('silver')) {
      return 'Silver';
    }
    return null;
  }

  static String _normalizeMakingType({
    required String category,
    required String? raw,
  }) {
    final value = (raw ?? '').trim();
    final allowed = category == 'Silver'
        ? _OrdersDashboardState._silverMakingTypeOptions
        : _OrdersDashboardState._goldMakingTypeOptions;
    if (allowed.contains(value)) {
      return value;
    }
    return category == 'Silver' ? 'PerGram' : 'FixRate';
  }

  static double _sumEntryValues(dynamic raw) {
    if (raw is List) {
      return raw.fold<double>(0, (sum, item) {
        if (item is Map<String, dynamic>) {
          return sum + _toDouble(item['value']);
        }
        if (item is Map) {
          return sum + _toDouble(item['value']);
        }
        return sum;
      });
    }
    if (raw is Map<String, dynamic>) {
      return _toDouble(raw['value']);
    }
    if (raw is Map) {
      return _toDouble(raw['value']);
    }
    return 0;
  }

  static String _stringValue(dynamic raw) {
    final value = _toDouble(raw);
    if (value == 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static double _toDouble(dynamic raw) {
    if (raw == null) {
      return 0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    final cleaned = raw.toString().replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  static bool _boolValue(dynamic raw) {
    if (raw is bool) {
      return raw;
    }
    final text = raw?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty) {
      return false;
    }
    return text != 'false' &&
        text != '0' &&
        text != 'no' &&
        text != 'off';
  }

  static String _buildNotes({
    required String sourceTagId,
    required String? location,
    required dynamic lessCategories,
    required dynamic additionalTypes,
  }) {
    final lines = <String>[];
    final locationText = (location ?? '').trim();
    if (locationText.isNotEmpty) {
      lines.add('Location: $locationText');
    }
    final lessSummary = _entriesSummary(
      lessCategories,
      labelKey: 'category',
      valueKey: 'value',
    );
    if (lessSummary.isNotEmpty) {
      lines.add('Less: $lessSummary');
    }
    final additionalSummary = _entriesSummary(
      additionalTypes,
      labelKey: 'type',
      valueKey: 'value',
    );
    if (additionalSummary.isNotEmpty) {
      lines.add('Additional: $additionalSummary');
    }
    return lines.join('\n');
  }

  static String _entriesSummary(
    dynamic raw, {
    required String labelKey,
    required String valueKey,
  }) {
    final parts = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) {
          continue;
        }
        final label = item[labelKey]?.toString().trim() ?? '';
        final value = item[valueKey]?.toString().trim() ?? '';
        if (label.isEmpty && value.isEmpty) {
          continue;
        }
        parts.add(
          label.isEmpty || value.isEmpty ? '$label$value' : '$label $value',
        );
      }
    } else if (raw is Map) {
      final label = raw[labelKey]?.toString().trim() ?? '';
      final value = raw[valueKey]?.toString().trim() ?? '';
      if (label.isNotEmpty || value.isNotEmpty) {
        parts.add(
          label.isEmpty || value.isEmpty ? '$label$value' : '$label $value',
        );
      }
    }
    return parts.join(', ');
  }
}
