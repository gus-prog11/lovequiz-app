import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class PhotoService {
  static final _picker = ImagePicker();
  //Sube una imagen local a Cloudinary y devuelve la URL de la imagen subida.
  static Future<UploadResult?> uploadImageFile(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final publicId = '${uid}_mem_${DateTime.now().millisecondsSinceEpoch}';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(CloudinaryConfig.uploadUrl),
      body: {
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': CloudinaryConfig.folder,
        'public_id': publicId,
        'file': 'data:image/jpeg;base64,$base64Image',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al subir foto: ${response.body}');
    }
    final json = jsonDecode(response.body);
    return UploadResult(url: json['secure_url'], publicId: publicId);
  }

  // Selecciona una foto de la galería y la sube a Cloudinary.
  static Future<UploadResult?> pickAndUploadPhoto(BuildContext context) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final publicId = '${uid}_${DateTime.now().millisecondsSinceEpoch}';

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(CloudinaryConfig.uploadUrl),
      body: {
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': CloudinaryConfig.folder,
        'public_id': publicId,
        'file': 'data:image/jpeg;base64,$base64Image',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al subir foto: ${response.body}');
    }

    final json = jsonDecode(response.body);
    return UploadResult(url: json['secure_url'], publicId: publicId);
  }
}

class UploadResult {
  final String url;
  final String publicId;

  UploadResult({required this.url, required this.publicId});
}
