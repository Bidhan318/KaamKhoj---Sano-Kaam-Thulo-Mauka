import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Picks an image from the gallery, heavily compresses it, and uploads to Firebase Storage.
  /// Returns the download URL if successful, or null if it fails or user cancels.
  Future<String?> pickAndUploadProfileImage(String userId) async {
    try {
      // 1. Pick and Compress Logic
      // We use maxWidth, maxHeight, and imageQuality to compress the image
      // BEFORE it even leaves the device. This avoids the need for Base64 entirely.
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Caps resolution (Perfect for profile pics & map pins)
        maxHeight: 800,
        imageQuality: 75, // 75% quality offers best balance of size and visual fidelity
      );

      if (image == null) {
        debugPrint('User cancelled image selection.');
        return null; 
      }

      File file = File(image.path);

      // (Optional) You can check the file size here before uploading if you want strict limits
      // final bytes = await file.length();
      // if (bytes > 1048576) { throw Exception("Image too large"); }

      // 2. Upload to Firebase Storage
      // We store it in a 'profile_images' folder, named by the user's ID
      final Reference ref = _storage.ref().child('profile_images').child('$userId.jpg');
      
      // We can add metadata to force it to be recognized as an image
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      // 3. Execute the upload
      final UploadTask uploadTask = ref.putFile(file, metadata);

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // 4. Get the URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;

    } on FirebaseException catch (e) {
      // Backup error catch for Firebase specific issues (e.g., no internet, rules blocked)
      debugPrint('Firebase Storage Error during upload: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Backup error catch for any other issues (e.g., file system permissions)
      debugPrint('General Error during image upload: $e');
      return null;
    }
  }

  /// Uploads a pre-picked File to Firebase Storage.
  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      final Reference ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = ref.putFile(file, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error during upload: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('General Error during image upload: $e');
      return null;
    }
  }
}
