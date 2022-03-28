//for code generation, the class has to have the dolar sign in front of it.
//STEP 1: dolar sign for class
//STEP 2: annotate with @MaterialAutoRouter
import 'package:auto_route/auto_route.dart';
import 'package:repo_viewer/auth/presentation/authorization_page.dart';
import 'package:repo_viewer/auth/presentation/sign_in_page.dart';
import 'package:repo_viewer/github/repos/starred_repos/presentation/starred_repos_page.dart';

import 'package:repo_viewer/splash/presentation/splash_page.dart';

@MaterialAutoRouter(routes: [
  MaterialRoute(page: SplashPage, initial: true),
  MaterialRoute(page: SignInPage, path: '/sign-in'),
  MaterialRoute(page: AuthorizationPage, path: '/auth'),
  MaterialRoute(page: StarredReposPage, path: '/starred'),
],
replaceInRouteName: 'Page,Route',//with this we replace words in route names
)
class $AppRouter {}
