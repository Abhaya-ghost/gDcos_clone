import 'dart:convert';

import 'package:google_docs/constants.dart';
import 'package:google_docs/models/errorModel.dart';
import 'package:google_docs/models/userModel.dart';
import 'package:google_docs/repository/localStorage_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod/riverpod.dart';
import 'package:http/http.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
      googleSignIn: GoogleSignIn(),
      client: Client(),
      localStorageRepo: LocalStorageRepo(),
    ));

final userProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  final GoogleSignIn _googleSignIn;
  final Client _client;
  final LocalStorageRepo _localStorageRepo;

  AuthRepository(
      {required GoogleSignIn googleSignIn,
      required Client client,
      required LocalStorageRepo localStorageRepo})
      : _googleSignIn = googleSignIn,
        _client = client,
        _localStorageRepo = localStorageRepo;

  Future<ErrorModel> signInWithGoogle() async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        final userAcc = UserModel(
            name: user.displayName ?? '',
            email: user.email,
            profilePic: user.photoUrl ?? '',
            uid: '',
            token: '');

        var res = await _client.post(Uri.parse('$host/api/signup'),
            body: userAcc.toJson(),
            headers: {'Content-Type': 'application/json; charset=UTF-8'});

        switch (res.statusCode) {
          case 200:
            final newUser = userAcc.copyWith(
              uid: jsonDecode(res.body)['user']['_id'],
              token: jsonDecode(res.body)['token'],
            );
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepo.setToken(newUser.token);
            break;
        }
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> getUserData() async {
    ErrorModel error =
        ErrorModel(error: 'Some unexpected error occurred', data: null);
    try {
      String? token = await _localStorageRepo.getToken();

      if (token != null) {
        var res = await _client.get(Uri.parse('$host/'), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        });

        switch (res.statusCode) {
          case 200:
            final newUser =
                UserModel.fromJson(jsonEncode(jsonDecode(res.body)['user']))
                    .copyWith(token: token);
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepo.setToken(newUser.token);
            break;
        }
      }
    } catch (err) {
      error = ErrorModel(error: err.toString(), data: null);
    }
    return error;
  }

  void signOut() async {
    await _googleSignIn.signOut();
    _localStorageRepo.setToken('');
  }
}
