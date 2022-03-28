//state notifiers need to have a separate state class

//we use a freezed union to make this functionality scalable

//STEP 1: funion
//STEP 2: import freezed_annotation
//STEP 3: ptf below imports

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/github_authenticator.dart';

part 'auth_notifier.freezed.dart';

//this state is conceptually really in between the application layer and the presentation layer. They come out in the application layer, but they are useful in the presentation layer.
@freezed
class AuthState with _$AuthState {
  //inside of our auth state we will not be using the either type.
  const AuthState._();
  const factory AuthState.initial() =
      _Initial; //the state will be initial until it is something else. Like before checking if we are authenticated, etc
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.failure(AuthFailure failure) = _Failure;
}

typedef AuthUriCallback = Future<Uri> Function(Uri authorizationUrl);

class AuthNotifier extends StateNotifier<AuthState> {
  final GithubAuthenticator
      _authenticator; //we add the dependency from our infrastructure layer.

  AuthNotifier(this._authenticator)
      : super(const AuthState
            .initial()); //It is always good to first create the states, and only then go ahead an implement the notifier instead. You should think before about the states. And only once you know that, then you will implement the notifier.

  //This authNotifier will be responsible for working with the github authenticator to either get the data across to the presentation layer in a fashion that is useful for the presentation layer. Out widgets do not need to really operate with the credentials. We just need to know in the presentation layer (widget tree) whether we are signed in or not. We don't need to get into details. In the auth notifier (state notifier) is where we usually have the methods that unite the infrastructure methods.

  //we transform a method on the github authenticator FROM THE INFRASTRUCTURE LAYER into something that the presentation layer is gonna be able to easily understand. This way we fulfil the purpose of the application layer. We took something from infrastructure, dealt with its return types (although we didn't have any entities since it was not necessary) and in the application layer we transformed this data into something that the presentation layer can understand easily in the form of a state.
  Future<void> checkAndUpdateAuthStatus() async {
    state = (await _authenticator
            .isSignedSign() //this should normally be an entity, but in this case a boolean was enough.
        )
        ? const AuthState.authenticated()
        : const AuthState.unauthenticated();
  }

  //orchestrates the three methods that deal with sign in (create grant, get authorization url, handle authorization response).
  Future<void> signIn(AuthUriCallback authorizationCallback) async {
    //this sign in method demonstrates the concept of the application logic. Application logic views things from the point of view of our repo viewer application.
    //THE AuthUriCallback will be able to communicate back to the auth notifier, the redirect uri with the code parameter which we will exchange for the access token.
    final grant = _authenticator.createAuthorizationCodeGrant();

    //here is where we use a callback. Knowing how to use callbacks is key.
    final redirectUrl =
        await authorizationCallback(_authenticator.getAuthorizationUrl(grant));
    final failureOrSuccess = await _authenticator.handleAuthorizationResponse(
      grant,
      redirectUrl.queryParameters,
    );

    state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.authenticated(),
    );

    grant.close();
  }

  Future<void> signOut () async {
    final failureOrSuccess = await _authenticator.signOut();
       state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.unauthenticated(),
    );
  }
}
