import 'dart:io';

import 'package:nara/core/errors/app_failure.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/smart_scan/application/document_classifier.dart';
import 'package:nara/features/smart_scan/application/receipt_parser.dart';
import 'package:nara/features/smart_scan/application/scan_gateways.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';
import 'package:nara/features/smart_scan/domain/repositories/smart_scan_repository.dart';
import 'package:uuid/uuid.dart';

class SmartScanConfirmInput {
  const SmartScanConfirmInput({
    required this.scanId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.merchant,
    this.description,
  });
  final String scanId;
  final String accountId;
  final String categoryId;
  final FinanceTransactionType type;
  final int amount;
  final DateTime date;
  final String? merchant;
  final String? description;
}

class SmartScanService {
  SmartScanService(
    this._repository,
    this._preprocessor,
    this._ocrEngine,
    this._classifier,
    this._parser,
    this._financeService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final SmartScanRepository _repository;
  final ScanImagePreprocessor _preprocessor;
  final ScanOcrEngine _ocrEngine;
  final LocalDocumentClassifier _classifier;
  final LocalReceiptParser _parser;
  final FinanceService _financeService;
  final Uuid _uuid;

  Future<Result<SmartScanDraft>> processImage({
    required String imagePath,
    required ScanSource source,
  }) async {
    final id = _uuid.v4();
    ProcessedScanImage? processed;
    try {
      processed = await _preprocessor.process(imagePath);
      final ocr = await _ocrEngine.recognize(processed.path);
      final rawText = ocr.text;
      if (rawText.trim().isEmpty) {
        await _saveFailure(id, source, ScanDocumentType.nonFinancial);
        return Failure(
          const OcrFailure(
            code: 'scan.no_text',
            message:
                'Teks tidak terbaca. Gunakan foto yang terang dan tidak buram.',
          ),
        );
      }
      final classification = _classifier.classify(rawText);
      final parsed = _parser.parseOcr(ocr, classification);
      final draft = SmartScanDraft(
        id: id,
        source: source,
        imagePath: imagePath,
        documentType: classification.type,
        confidence: parsed.confidence,
        rawText: rawText,
        amount: parsed.amount,
        date: parsed.date,
        merchant: parsed.merchant,
        suggestedTransactionType: parsed.suggestedTransactionType,
        categorySuggestion: parsed.category,
        warnings: parsed.warnings,
      );
      await _repository.saveRecord(
        SmartScanRecord(
          id: id,
          source: source,
          documentType: classification.type,
          confidence: parsed.confidence,
          status: 'pending',
          extractedAmount: parsed.amount,
          merchant: parsed.merchant,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return Success(draft);
    } catch (error) {
      await _saveFailure(id, source, ScanDocumentType.nonFinancial);
      return Failure(
        OcrFailure(
          code: 'scan.process_failed',
          message: 'Gambar belum dapat diproses. Coba foto lain.',
          cause: error,
        ),
      );
    } finally {
      if (processed?.isTemporary ?? false) {
        try {
          await File(processed!.path).delete();
        } catch (_) {
          // Temporary files are also cleaned by the operating system.
        }
      }
    }
  }

  Future<Result<void>> confirm(SmartScanConfirmInput input) async {
    if (input.amount <= 0 ||
        input.accountId.isEmpty ||
        input.categoryId.isEmpty ||
        input.type.isTransfer) {
      return Failure(
        const ValidationFailure(
          code: 'scan.confirm_invalid',
          message: 'Periksa akun, kategori, jenis, nominal, dan tanggal.',
        ),
      );
    }
    final status = await _repository.getStatus(input.scanId);
    if (status != 'pending') {
      return Failure(
        const ValidationFailure(
          code: 'scan.not_pending',
          message: 'Draft ini sudah diproses atau dibatalkan.',
        ),
      );
    }
    final result = await _financeService.saveTransaction(
      TransactionInput(
        accountId: input.accountId,
        categoryId: input.categoryId,
        type: input.type,
        amount: input.amount,
        date: input.date,
        merchant: input.merchant,
        description: input.description,
        source: 'smart_scan',
        scanId: input.scanId,
      ),
    );
    if (result case Failure(:final failure)) return Failure(failure);
    await _repository.markConfirmed(input.scanId);
    return const Success(null);
  }

  Future<void> cancel(String id) => _repository.markCancelled(id);

  Future<void> _saveFailure(
    String id,
    ScanSource source,
    ScanDocumentType type,
  ) => _repository.saveRecord(
    SmartScanRecord(
      id: id,
      source: source,
      documentType: type,
      confidence: 0,
      status: 'failed',
      createdAt: DateTime.now().toUtc(),
    ),
  );
}
