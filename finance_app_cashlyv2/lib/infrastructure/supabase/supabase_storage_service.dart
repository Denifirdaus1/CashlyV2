import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseStorageService {
  SupabaseStorageService(this.client);

  final SupabaseClient client;
  final _uuid = const Uuid();
  final String bucket = 'avatars';

  Future<String?> uploadAvatar(File originalFile) async {
    final compressed = await _compressImage(originalFile);
    final filePath = 'members/${_uuid.v4()}.jpg';

    await client.storage.from(bucket).upload(
          filePath,
          compressed,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return client.storage.from(bucket).getPublicUrl(filePath);
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 512,
      minHeight: 512,
      format: CompressFormat.jpeg,
    );
    if (result == null) return file;
    return File(result.path);
  }
}
