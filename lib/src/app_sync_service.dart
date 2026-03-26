part of '../main.dart';

class _FirestoreAppSyncService {
  const _FirestoreAppSyncService();

  static const String _projectId = 'shubham-jewellers-1976';
  static const String _apiKey = 'AIzaSyCoR4bdnNAFxCPFxwNj6sTSsU6sc2m5e6o';

  Future<List<Order>> fetchOrders({required String idToken}) async {
    final documents = await _fetchCollectionDocuments(
      'orders',
      idToken: idToken,
      pageSize: 500,
    );
    return documents
        .map((document) {
          final fields = document['fields'];
          if (fields is! Map<String, dynamic>) {
            return null;
          }
          final decoded = _decodeFields(fields);
          return Order.fromJson(decoded);
        })
        .whereType<Order>()
        .toList();
  }

  Future<void> saveOrder({required String idToken, required Order order}) {
    return _patchDocument(
      'orders/${order.id}',
      fields: {
        ..._encodeMap(order.toJson()),
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
      idToken: idToken,
    );
  }

  Future<void> deleteOrder({required String idToken, required String orderId}) {
    return _deleteDocument('orders/$orderId', idToken: idToken);
  }

  Future<Map<String, dynamic>?> fetchDraft({
    required String idToken,
    required String uid,
  }) async {
    final document = await _fetchDocument(
      'app_state/draft_$uid',
      idToken: idToken,
    );
    if (document == null) {
      return null;
    }
    final fields = document['fields'];
    if (fields is! Map<String, dynamic>) {
      return null;
    }
    return _decodeFields(fields);
  }

  Future<void> saveDraft({
    required String idToken,
    required String uid,
    required Map<String, dynamic> draft,
  }) {
    return _patchDocument(
      'app_state/draft_$uid',
      fields: {
        ..._encodeMap(draft),
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
      idToken: idToken,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCollectionDocuments(
    String collectionPath, {
    required String idToken,
    int pageSize = 500,
  }) async {
    final documents = <Map<String, dynamic>>[];
    String? pageToken;

    do {
      final query = <String, String>{'key': _apiKey, 'pageSize': '$pageSize'};
      if (pageToken != null && pageToken.isNotEmpty) {
        query['pageToken'] = pageToken;
      }

      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$_projectId/databases/(default)/documents/$collectionPath',
        query,
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode == 404) {
        return documents;
      }
      if (response.statusCode != 200) {
        throw StateError(
          'Firestore collection request failed with status ${response.statusCode}.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException(
          'Unexpected Firestore collection response.',
        );
      }

      final pageDocuments = body['documents'];
      if (pageDocuments is List) {
        for (final document in pageDocuments) {
          if (document is Map<String, dynamic>) {
            documents.add(document);
          }
        }
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    return documents;
  }

  Future<Map<String, dynamic>?> _fetchDocument(
    String documentPath, {
    required String idToken,
  }) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/$documentPath',
      {'key': _apiKey},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore document request failed with status ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Firestore document response.');
    }
    return body;
  }

  Future<void> _patchDocument(
    String documentPath, {
    required Map<String, dynamic> fields,
    required String idToken,
  }) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/$documentPath',
      {'key': _apiKey},
    );
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': fields}),
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore write failed with status ${response.statusCode}.',
      );
    }
  }

  Future<void> _deleteDocument(
    String documentPath, {
    required String idToken,
  }) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/$documentPath',
      {'key': _apiKey},
    );
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw StateError(
        'Firestore delete failed with status ${response.statusCode}.',
      );
    }
  }

  static Map<String, dynamic> _encodeMap(Map<String, dynamic> value) {
    return value.map((key, item) => MapEntry(key, _encodeValue(item)));
  }

  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    }
    if (value is bool) {
      return {'booleanValue': value};
    }
    if (value is int) {
      return {'integerValue': value.toString()};
    }
    if (value is double) {
      return {'doubleValue': value};
    }
    if (value is num) {
      return {'doubleValue': value.toDouble()};
    }
    if (value is String) {
      return {'stringValue': value};
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()},
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': _encodeMap(value)},
      };
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields': _encodeMap(
            value.map((key, item) => MapEntry(key.toString(), item)),
          ),
        },
      };
    }
    return {'stringValue': value.toString()};
  }

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
      return num.tryParse(rawField['integerValue'].toString()) ?? 0;
    }
    if (rawField.containsKey('doubleValue')) {
      return num.tryParse(rawField['doubleValue'].toString()) ?? 0;
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
      final nestedFields = mapValue['fields'];
      if (nestedFields is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }
      return _decodeFields(nestedFields);
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
}
