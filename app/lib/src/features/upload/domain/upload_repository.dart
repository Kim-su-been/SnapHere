import 'package:snap_here/src/features/upload/domain/upload_models.dart';

abstract interface class UploadRepository {
  Future<List<UploadPhoto>> fetchGallery();

  Future<List<UploadPhoto>> fetchDraftGallery();

  Future<void> openMediaSettings();

  Future<List<UploadPlace>> matchPlaces(UploadPhoto photo);

  Future<List<UploadPlace>> searchPlaces(String keyword);

  Future<UploadResult> createPost(UploadDraft draft);
}
