import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/foundation/application/use_cases/initialize_foundation.dart';
import 'package:nara/features/foundation/application/use_cases/save_preferences.dart';
import 'package:nara/features/foundation/application/use_cases/save_profile.dart';
import 'package:nara/features/foundation/data/repositories/drift_foundation_repository.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';

class FoundationState {
  const FoundationState({required this.profile, required this.preferences});

  final UserProfile? profile;
  final AppPreferences preferences;

  FoundationState copyWith({
    UserProfile? profile,
    AppPreferences? preferences,
  }) {
    return FoundationState(
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
    );
  }
}

final foundationRepositoryProvider = Provider<FoundationRepository>((ref) {
  return DriftFoundationRepository(ref.watch(appDatabaseProvider));
});

final initializeFoundationProvider = Provider<InitializeFoundation>((ref) {
  return InitializeFoundation(ref.watch(foundationRepositoryProvider));
});

final saveProfileProvider = Provider<SaveProfile>((ref) {
  return SaveProfile(ref.watch(foundationRepositoryProvider));
});

final savePreferencesProvider = Provider<SavePreferences>((ref) {
  return SavePreferences(ref.watch(foundationRepositoryProvider));
});

final foundationControllerProvider =
    AsyncNotifierProvider<FoundationController, FoundationState>(
      FoundationController.new,
    );

class FoundationController extends AsyncNotifier<FoundationState> {
  @override
  Future<FoundationState> build() async {
    final snapshot = await ref.watch(initializeFoundationProvider).call();
    return FoundationState(
      profile: snapshot.profile,
      preferences: snapshot.preferences,
    );
  }

  Future<Result<UserProfile>> saveProfile({
    required String name,
    required String assistantName,
  }) async {
    final current = state.value;
    final result = await ref
        .read(saveProfileProvider)
        .call(
          name: name,
          assistantName: assistantName,
          existing: current?.profile,
        );

    if (result case Success<UserProfile>(:final value)) {
      state = AsyncData(
        FoundationState(
          profile: value,
          preferences: current?.preferences ?? const AppPreferences(),
        ),
      );
    }
    return result;
  }

  Future<void> updatePreferences(AppPreferences preferences) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(preferences: preferences));
    try {
      await ref.read(savePreferencesProvider).call(preferences);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
