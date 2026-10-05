import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Camera / gallery access, behind an interface so tests don't need a device.
abstract interface class PhotoPicker {
  /// Returns the picked file's path, or null if the farmer cancelled.
  Future<String?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      // Keeps uploads small on rural connections without hurting what the farmer sees.
      maxWidth: 2048,
      imageQuality: 85,
    );
    return file?.path;
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => ImagePickerPhotoPicker());
