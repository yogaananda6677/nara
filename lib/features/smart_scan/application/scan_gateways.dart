import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

class OcrTextElement {
  const OcrTextElement({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.elements = const [],
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final List<OcrTextElement> elements;

  double get centerY => (top + bottom) / 2;
  bool get hasBox => right > left && bottom > top;
}

class OcrTextResult {
  const OcrTextResult({
    required this.text,
    required this.lines,
    required this.hasLayout,
  });

  factory OcrTextResult.fromText(String text) {
    final lines = text
        .replaceAll('\r', '')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .indexed
        .map((item) {
          final top = item.$1 * 20.0;
          return OcrTextLine(
            text: item.$2,
            left: 0,
            top: top,
            right: item.$2.length * 8.0,
            bottom: top + 16,
          );
        })
        .toList();
    return OcrTextResult(text: text, lines: lines, hasLayout: false);
  }

  final String text;
  final List<OcrTextLine> lines;
  final bool hasLayout;
}

abstract interface class ScanImagePicker {
  Future<String?> pick(ScanSource source);
  Future<String?> retrieveLostImage();
}

class DeviceScanImagePicker implements ScanImagePicker {
  DeviceScanImagePicker({picker.ImagePicker? imagePicker})
    : _picker = imagePicker ?? picker.ImagePicker();
  final picker.ImagePicker _picker;

  @override
  Future<String?> pick(ScanSource source) async {
    final file = await _picker.pickImage(
      source: source == ScanSource.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
    );
    return file?.path;
  }

  @override
  Future<String?> retrieveLostImage() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }
    return response.files!.first.path;
  }
}

class ProcessedScanImage {
  const ProcessedScanImage({required this.path, required this.isTemporary});
  final String path;
  final bool isTemporary;
}

abstract interface class ScanImagePreprocessor {
  Future<ProcessedScanImage> process(String sourcePath);
}

class LocalScanImagePreprocessor implements ScanImagePreprocessor {
  @override
  Future<ProcessedScanImage> process(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw const FormatException('Format gambar tidak didukung.');
    }
    image = img.bakeOrientation(image);
    if (image.width > 1800) {
      image = img.copyResize(image, width: 1800);
    }
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.18);
    final target = File(
      '${Directory.systemTemp.path}/nara_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await target.writeAsBytes(img.encodeJpg(image, quality: 92), flush: true);
    return ProcessedScanImage(path: target.path, isTemporary: true);
  }
}

abstract interface class ScanOcrEngine {
  Future<OcrTextResult> recognize(String imagePath);
}

class MlKitScanOcrEngine implements ScanOcrEngine {
  @override
  Future<OcrTextResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = <OcrTextLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;
          lines.add(
            OcrTextLine(
              text: line.text,
              left: box.left,
              top: box.top,
              right: box.right,
              bottom: box.bottom,
              elements: line.elements.map((element) {
                final elementBox = element.boundingBox;
                return OcrTextElement(
                  text: element.text,
                  left: elementBox.left,
                  top: elementBox.top,
                  right: elementBox.right,
                  bottom: elementBox.bottom,
                );
              }).toList(),
            ),
          );
        }
      }
      return OcrTextResult(
        text: result.text,
        lines: lines,
        hasLayout: lines.any((line) => line.hasBox),
      );
    } finally {
      await recognizer.close();
    }
  }
}
