import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';

class SavePreferences {
  const SavePreferences(this._repository);

  final FoundationRepository _repository;

  Future<void> call(AppPreferences preferences) {
    return _repository.savePreferences(preferences);
  }
}
