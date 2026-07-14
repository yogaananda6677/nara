import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/features/foundation/presentation/pages/onboarding_page.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';
import 'package:nara/features/home/presentation/pages/home_page.dart';

class FoundationGate extends ConsumerWidget {
  const FoundationGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundation = ref.watch(foundationControllerProvider);

    return foundation.when(
      loading: () => const _FoundationLoading(),
      error: (error, stackTrace) => _FoundationError(
        onRetry: () => ref.invalidate(foundationControllerProvider),
      ),
      data: (state) {
        if (state.profile == null) return const OnboardingPage();
        return const HomePage();
      },
    );
  }
}

class _FoundationLoading extends StatelessWidget {
  const _FoundationLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Menyiapkan data lokal…'),
          ],
        ),
      ),
    );
  }
}

class _FoundationError extends StatelessWidget {
  const _FoundationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Data lokal belum dapat dibuka',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tidak ada data yang dikirim keluar perangkat. Coba buka kembali database lokal.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
