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

    // XFile.readAsBytes() fonctionne sur toutes les plateformes (mobile, desktop
    // ET web). L'ancien code utilisait File(picked.path) de dart:io, qui n'existe
    // pas sur Flutter Web : picked.path y est une URL blob, pas un chemin disque,
    // donc File() plantait immédiatement et l'upload n'était même jamais envoyé
    // au backend.
    final bytes = await picked.readAsBytes();
    final data = await _api.uploadImage('/uploads/image', bytes: bytes, fileName: picked.name);
    return data['url'] as String?;
  }
}
