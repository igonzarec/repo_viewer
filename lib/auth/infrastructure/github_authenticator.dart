// ignore: depend_on_referenced_packages

import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/core/infrastructure/dio_extensions.dart';
import 'package:repo_viewer/core/shared/encoders.dart';
import 'credentials_storage/credentials_storage.dart';

// For the auth feature, in the infrastructure we will not have data transfer
// objects since we don’t have entities.
// It does not have repositories or remote services either. It is kind of a
// special feature. That’s because authentication happens always on the remote
// server. Already using the oauth package. We will only have a class called
// github authenticator.

//we are chaining different clients together so that we get a modified request,
//and this modified request is going to contain the accept header
class GitHubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

/// Having the secure credentials storage already finished, in the github
/// authenticator when need to use the credentials storage to get the signed
/// in credentials. That means we depend on another class in order to implement
/// the functionality in this class.
class GithubAuthenticator {
  //We are going to depend on the abstract class in order to change
  //the implementation on the fly (which we will do with riverpod).
  final CredentialsStorage _credentialsStorage;
  final Dio _dio;

  GithubAuthenticator(this._credentialsStorage, this._dio);

  //Next variables come from: https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps

  static const clientId = '3b88ef31c0f8214c89e6';
  static const clientSecret = '1657e1e6a5c366f40952d8a0ebe4d829b0570e98';
  static const scopes = ['read:user', 'repo']; //found also in the repo
  static final authorizationEndPoint = Uri.parse(
      'https://github.com/login/oauth/authorize'); //later on in this module we will pass this client secret in build time.

  static final tokenEndPoint =
      Uri.parse('https://github.com/login/oauth/access_token');

  //revocation is not part of oauth
  static final revocationEndpoint =
      Uri.parse('https://api.github.com//applications/$clientId/token');

  //Authorization callback URL is another name for redirect URL. This
  //is defined in the developer section of our projects in github.

  ///On mobile we will not be redirected to this url, WE WILL INTERCEPT THE
  ///REDIRECTION (before any redirection happens). This url is more
  ///for Flutter for web.
  static final redirectUrl = Uri.parse('http://localhost:3000/callback');

  //TODO: complete client id, client secret, scopes.

  ///Credentials hold the access token. Once we are signed in, we will
  ///store the credentials in the device.
  Future<Credentials?> getSignedInCredentials() async {
    try {
      final storedCredentials = await _credentialsStorage.read();

      if (storedCredentials != null) {
        if (storedCredentials.canRefresh && storedCredentials.isExpired) {
         final failureOrCredentials = await refresh(storedCredentials);
         return failureOrCredentials.fold((l) => null, (r) => r); //to return either a failure (left) or the success value (right).
        }
      }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedSign() =>
      getSignedInCredentials().then((credentials) => credentials != null);

  //This will be called from a state notifier.
  AuthorizationCodeGrant createAuthorizationCodeGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authorizationEndPoint,
      tokenEndPoint,
      secret: clientSecret,
      httpClient:
          GitHubOAuthHttpClient(), //so will github respond with a json formatted response
    );
  }

  //This will be called from a state notifier
  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
  }

  //Unit is used for void. This function would normally be Future<void>, but
  //because we want to handle failures and success, we use [Either].
  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
    AuthorizationCodeGrant grant,
    Map<String, String> queryParams,
  ) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(
          queryParams); //this Client includes the authorization header with the access token.
      await _credentialsStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server("${e.error}:${e.description}"));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
    //NOTE: github returns its data containing the access token in a not
    //very standard way.

    //The oauth package expects a response in json format.

    //this method exchanges the authorization code for the access token.
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken = await _credentialsStorage
        .read()
        .then((credentials) => credentials?.accessToken);

    final userNameAndPassword =
        stringToBase64.encode('$clientId:$clientSecret');

    try {
      try {
        _dio.deleteUri(
          revocationEndpoint,
          data: {
            'access_token': accessToken,
          },
          options: Options(
            headers: {
              'Authorization': 'basic $userNameAndPassword',
            },
          ),
        );
      } on DioError catch (e) {
        if (e.isNoConnectionError) {
          //Ignoring
        } else {
          rethrow;
        }
      }
      //just specifying the endpoint is not enough.
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Credentials>> refresh(
    Credentials
        credentials, //these are gonna be the old credentials, expired, in the need of being refreshed.
  ) async {
    try {
      final refreshCredentials = await credentials.refresh(
        identifier: clientId,
        secret: clientSecret,
        httpClient: GitHubOAuthHttpClient(),
      );
      await _credentialsStorage.save(refreshCredentials);
      return right(refreshCredentials);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
