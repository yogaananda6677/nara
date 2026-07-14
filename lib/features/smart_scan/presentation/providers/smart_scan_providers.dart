import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/smart_scan/application/document_classifier.dart';
import 'package:nara/features/smart_scan/application/receipt_parser.dart';
import 'package:nara/features/smart_scan/application/scan_gateways.dart';
import 'package:nara/features/smart_scan/application/smart_scan_service.dart';
import 'package:nara/features/smart_scan/data/repositories/drift_smart_scan_repository.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';
import 'package:nara/features/smart_scan/domain/repositories/smart_scan_repository.dart';

class SmartScanState {
  const SmartScanState({this.draft, this.isProcessing = false, this.message});
  final SmartScanDraft? draft;
  final bool isProcessing;
  final String? message;

  SmartScanState copyWith({
    SmartScanDraft? draft,
    bool clearDraft = false,
    bool? isProcessing,
    String? message,
    bool clearMessage = false,
  }) => SmartScanState(
    draft: clearDraft ? null : draft ?? this.draft,
    isProcessing: isProcessing ?? this.isProcessing,
    message: clearMessage ? null : message ?? this.message,
  );
}

final smartScanRepositoryProvider = Provider<SmartScanRepository>((ref) {
  return DriftSmartScanRepository(ref.watch(appDatabaseProvider));
});
final scanImagePickerProvider = Provider<ScanImagePicker>((ref) {
  return DeviceScanImagePicker();
});
final scanImagePreprocessorProvider = Provider<ScanImagePreprocessor>((ref) {
  return LocalScanImagePreprocessor();
});
final scanOcrEngineProvider = Provider<ScanOcrEngine>((ref) {
  return MlKitScanOcrEngine();
});
final documentClassifierProvider = Provider<LocalDocumentClassifier>((ref) {
  return const LocalDocumentClassifier();
});
final receiptParserProvider = Provider<LocalReceiptParser>((ref) {
  return const LocalReceiptParser();
});
final smartScanServiceProvider = Provider<SmartScanService>((ref) {
  return SmartScanService(
    ref.watch(smartScanRepositoryProvider),
    ref.watch(scanImagePreprocessorProvider),
    ref.watch(scanOcrEngineProvider),
    ref.watch(documentClassifierProvider),
    ref.watch(receiptParserProvider),
    ref.watch(financeServiceProvider),
  );
});

final smartScanControllerProvider =
    AsyncNotifierProvider.autoDispose<SmartScanController, SmartScanState>(
      SmartScanController.new,
    );

class SmartScanController extends AsyncNotifier<SmartScanState> {
  @override
  Future<SmartScanState> build() async {
    final lostPath = await ref
        .read(scanImagePickerProvider)
        .retrieveLostImage();
    if (lostPath == null) return const SmartScanState();
    return _processPath(lostPath, ScanSource.gallery);
  }

  Future<void> scan(ScanSource source) async {
    final current = state.value ?? const SmartScanState();
    if (current.isProcessing) return;
    if (current.draft != null) {
      await ref.read(smartScanServiceProvider).cancel(current.draft!.id);
    }
    state = const AsyncData(SmartScanState(isProcessing: true));
    try {
      final path = await ref.read(scanImagePickerProvider).pick(source);
      if (path == null) {
        state = const AsyncData(SmartScanState());
        return;
      }
      state = AsyncData(await _processPath(path, source));
    } catch (_) {
      state = const AsyncData(
        SmartScanState(
          message:
              'Kamera atau galeri tidak dapat dibuka. Periksa izin aplikasi.',
        ),
      );
    }
  }

  Future<SmartScanState> _processPath(String path, ScanSource source) async {
    final result = await ref
        .read(smartScanServiceProvider)
        .processImage(imagePath: path, source: source);
    return switch (result) {
      Success(:final value) => SmartScanState(draft: value),
      Failure(:final failure) => SmartScanState(message: failure.message),
    };
  }

  Future<bool> confirm(SmartScanConfirmInput input) async {
    final current = state.value;
    if (current == null || current.isProcessing || current.draft == null) {
      return false;
    }
    state = AsyncData(current.copyWith(isProcessing: true, clearMessage: true));
    final result = await ref.read(smartScanServiceProvider).confirm(input);
    if (result case Failure(:final failure)) {
      state = AsyncData(
        current.copyWith(isProcessing: false, message: failure.message),
      );
      return false;
    }
    ref.invalidate(financeControllerProvider);
    state = const AsyncData(SmartScanState());
    return true;
  }

  Future<void> cancel() async {
    final draft = state.value?.draft;
    if (draft != null) {
      await ref.read(smartScanServiceProvider).cancel(draft.id);
    }
    state = const AsyncData(SmartScanState());
  }
}
