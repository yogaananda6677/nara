import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _assistantController = TextEditingController(text: 'Nara');
  var _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _assistantController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(foundationControllerProvider.notifier)
        .saveProfile(
          name: _nameController.text,
          assistantName: _assistantController.text,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result case Failure(:final failure)) {
      setState(() => _errorMessage = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Selamat datang di Nara',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Atur profil lokal Anda. Semua data V1 disimpan di perangkat ini.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nama Anda',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _assistantController,
                      textInputAction: TextInputAction.done,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nama asisten',
                        prefixIcon: Icon(Icons.smart_toy_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama asisten wajib diisi.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _continue(),
                    ),
                    if (_errorMessage case final message?) ...[
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _isSaving ? null : _continue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Mulai menggunakan Nara'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.offline_bolt, size: 18),
                        SizedBox(width: 6),
                        Text('Berjalan sepenuhnya offline'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
