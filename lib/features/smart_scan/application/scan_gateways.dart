import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

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
  Future<String> recognize(String imagePath);
}

class MlKitScanOcrEngine implements ScanOcrEngine {
  @override
  Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
