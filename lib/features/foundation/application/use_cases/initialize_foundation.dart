import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';

class FoundationSnapshot {
  const FoundationSnapshot({required this.profile, required this.preferences});

  final UserProfile? profile;
  final AppPreferences preferences;
}

class InitializeFoundation {
  const InitializeFoundation(this._repository);

  final FoundationRepository _repository;

  Future<FoundationSnapshot> call() async {
    await _repository.initialize();
    return FoundationSnapshot(
      profile: await _repository.getProfile(),
      preferences: await _repository.getPreferences(),
    );
  }
}
