import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';

abstract interface class FoundationRepository {
  Future<void> initialize();

  Future<UserProfile?> getProfile();

  Future<void> saveProfile(UserProfile profile);

  Future<AppPreferences> getPreferences();

  Future<void> savePreferences(AppPreferences preferences);
}
