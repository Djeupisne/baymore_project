import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

/// Envoie une image choisie sur l'appareil vers le backend, qui la relaie
/// à UploadThing et renvoie l'URL publique du fichier hébergé.
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final ApiClient _api = ApiClient();

  Future<String?> pickAndUpload({required ImageSource source}) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (picked == null) return null;

    final bytes = await File(picked.path).readAsBytes();
    final data = await _api.uploadImage('/uploads/image', bytes: bytes, fileName: picked.name);
    return data['url'] as String?;
  }
}
