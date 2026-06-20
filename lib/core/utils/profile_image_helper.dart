// lib/core/utils/profile_image_helper.dart
//
// PURPOSE: Worker profile photos are now stored as a base64 string directly
// in the Firestore document

import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider? profileImageProvider(String? imageData) {
  if (imageData == null || imageData.isEmpty) return null;

  if (imageData.startsWith('http')) {
    return NetworkImage(imageData);
  }

  try {
    return MemoryImage(base64Decode(imageData));
  } catch (_) {
    return null;
  }
}