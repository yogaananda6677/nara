import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';

class FakeFoundationRepository implements FoundationRepository {
  FakeFoundationRepository({this.profile, AppPreferences? preferences})
    : preferences = preferences ?? const AppPreferences();

  UserProfile? profile;
  AppPreferences preferences;
  var initializeCount = 0;

  @override
  Future<AppPreferences> getPreferences() async => preferences;

  @override
  Future<UserProfile?> getProfile() async => profile;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    this.preferences = preferences;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    this.profile = profile;
  }
}
