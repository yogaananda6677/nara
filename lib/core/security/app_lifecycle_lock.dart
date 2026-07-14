import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';

final appLockedProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);

class AppLockController extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}

class AppLifecycleLock extends ConsumerStatefulWidget {
  const AppLifecycleLock({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycleLock> createState() => _AppLifecycleLockState();
}

class _AppLifecycleLockState extends ConsumerState<AppLifecycleLock>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }

    final lockEnabled = ref
        .read(foundationControllerProvider)
        .value
        ?.preferences
        .appLockEnabled;
    if (lockEnabled ?? false) {
      ref.read(appLockedProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockedProvider);
    if (!isLocked) return widget.child;

    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56),
              SizedBox(height: 16),
              Text(
                'Nara terkunci',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Autentikasi PIN/biometrik akan dihubungkan pada fase security.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
