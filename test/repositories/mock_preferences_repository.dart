import 'package:somna/shared/models/user_preferences.dart';
import 'package:somna/shared/repositories/preferences_repository.dart';

class MockPreferencesRepository implements IPreferencesRepository {
  UserPreferences _preferences = const UserPreferences();

  @override
  Future<UserPreferences> getPreferences() async {
    return _preferences;
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    _preferences = preferences;
  }

  @override
  Future<void> resetPreferences() async {
    _preferences = const UserPreferences();
  }
}

