import 'package:nara/core/errors/app_failure.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';
import 'package:uuid/uuid.dart';

class SaveProfile {
  SaveProfile(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FoundationRepository _repository;
  final Uuid _uuid;

  Future<Result<UserProfile>> call({
    required String name,
    required String assistantName,
    UserProfile? existing,
  }) async {
    final normalizedName = name.trim();
    final normalizedAssistantName = assistantName.trim();

    if (normalizedName.isEmpty) {
      return const Failure(
        ValidationFailure(
          code: 'profile.name_required',
          message: 'Nama pengguna wajib diisi.',
        ),
      );
    }
    if (normalizedName.length > 100) {
      return const Failure(
        ValidationFailure(
          code: 'profile.name_too_long',
          message: 'Nama pengguna maksimal 100 karakter.',
        ),
      );
    }
    if (normalizedAssistantName.isEmpty ||
        normalizedAssistantName.length > 100) {
      return const Failure(
        ValidationFailure(
          code: 'profile.assistant_name_invalid',
          message: 'Nama asisten wajib diisi dan maksimal 100 karakter.',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      id: existing?.id ?? _uuid.v4(),
      name: normalizedName,
      preferredLanguage: existing?.preferredLanguage ?? 'id',
      timezone: existing?.timezone ?? 'Asia/Jakarta',
      assistantName: normalizedAssistantName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _repository.saveProfile(profile);
      return Success(profile);
    } catch (error) {
      return Failure(
        DatabaseFailure(
          code: 'profile.save_failed',
          message: 'Profil belum dapat disimpan.',
          cause: error,
        ),
      );
    }
  }
}
