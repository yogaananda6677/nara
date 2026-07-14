import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nara/features/foundation/presentation/pages/foundation_gate.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FoundationGate()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
