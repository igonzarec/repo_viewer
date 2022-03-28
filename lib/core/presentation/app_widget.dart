import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/application/auth_notifier.dart';
import 'package:repo_viewer/auth/shared/providers.dart';
import 'package:repo_viewer/core/presentation/routes/app_router.gr.dart';
import 'package:repo_viewer/core/shared/providers.dart';

///Future provider for all initialization steps. INITIALIZED IN THE APPWIDGET
final initializationProvider = FutureProvider((ref) async {
  await ref.read(sembastProvider).init();
  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAndUpdateAuthStatus();
});

//With riverpod, if you want to access the objects the providers provide you need to wrap the top level widget with a provider scope.
// class AppWidget extends StatelessWidget {
//   final appRouter = AppRouter();

//   @override
//   Widget build(BuildContext context) {
//     return ProviderListener(
//       provider: initializationProvider,
//       onChange: (BuildContext context, value) {  },
//       child: MaterialApp.router(
//         title: 'Repo Viewer',
//         routerDelegate:  appRouter.delegate(),
//         routeInformationParser: appRouter.defaultRouteParser(),
//       ),
//     );
//   }
// }

// //With the new version of riverpod you can use a consumer widget.
class AppWidget extends ConsumerWidget {
  final appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(initializationProvider, (_) {});
    ref.listen<AuthState>(authNotifierProvider, (state) {
      state.maybeMap(
          orElse: () {},
          authenticated: (_) {
            appRouter.pushAndPopUntil(
              const StarredReposRoute(),
              predicate: (route) => false,//this will ensure that all routes are popped and only the starredReposRoute is pushed.
            );
          },
          unauthenticated: (_){
            appRouter.pushAndPopUntil(
              const SignInRoute(),
              predicate: (route) => false,//this will ensure that all routes are popped and only the starredReposRoute is pushed.
            );
          }
          );
    });

    return MaterialApp.router(
      title: 'Repo Viewer',
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }
}
