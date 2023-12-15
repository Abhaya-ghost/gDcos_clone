import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs/models/documentModel.dart';
import 'package:google_docs/models/errorModel.dart';
import 'package:http/http.dart';

import '../constants.dart';

final documentRepoProvider = Provider((ref) => DocumentRepo(client: Client()));

class DocumentRepo {
  final Client _client;

  DocumentRepo({required Client client}) : _client = client;

  Future<ErrorModel> createDocument(String token) async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      var res = await _client.post(
        Uri.parse('$host/doc/create'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
        body: jsonEncode({'createdAt': DateTime.now().millisecondsSinceEpoch}),
      );

      switch (res.statusCode) {
        case 200:
          error =
              ErrorModel(error: null, data: DocumentModel.fromJson(res.body));
          break;
        default:
          error = ErrorModel(error: res.body, data: null);
          break;
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> getDocument(String token) async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      var res = await _client.get(
        Uri.parse('$host/docs/me'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      switch (res.statusCode) {
        case 200:
          List<DocumentModel> docs = [];

          for (int i = 0; i < jsonDecode(res.body).length; i++) {
            docs.add(
                DocumentModel.fromJson(jsonEncode(jsonDecode(res.body)[i])));
          }
          error = ErrorModel(error: null, data: docs);
          break;
        default:
          error = ErrorModel(error: res.body, data: null);
          break;
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> updateTitle({
    required String token,
    required String id,
    required String title,
  }) async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      var res = await _client.post(
        Uri.parse('$host/doc/title'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'title': title,
          'id': id,
        }),
      );

      switch (res.statusCode) {
        case 200:
          error =
              ErrorModel(error: null, data: DocumentModel.fromJson(res.body));
          break;
        default:
          error = ErrorModel(error: res.body, data: null);
          break;
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> getDocumentById(String token, String id) async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      var res = await _client.get(
        Uri.parse('$host/doc/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      switch (res.statusCode) {
        case 200:
          error =
              ErrorModel(error: null, data: DocumentModel.fromJson(res.body));
          break;
        default:
          throw 'This Document does not exist, please create a new one  ';
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }
}
