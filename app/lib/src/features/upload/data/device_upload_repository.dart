import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:snap_here/src/features/upload/data/fake_upload_repository.dart';
import 'package:snap_here/src/features/upload/domain/upload_models.dart';
import 'package:snap_here/src/features/upload/domain/upload_repository.dart';

class UploadPermissionException implements Exception {
  const UploadPermissionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UploadLocationException implements Exception {
  const UploadLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 기기 미디어·GPS·Google Places를 사용하고, 게시 API가 준비되기 전까지는
/// 생성 요청만 [FakeUploadRepository]에 위임한다.
class DeviceUploadRepository implements UploadRepository {
  DeviceUploadRepository({http.Client? httpClient, String? googleMapsApiKey})
    : _httpClient = httpClient ?? http.Client(),
      _googleMapsApiKey = googleMapsApiKey ?? _configuredGoogleMapsApiKey();

  static const _placesHost = 'https://places.googleapis.com/v1';

  final http.Client _httpClient;
  final String _googleMapsApiKey;
  final FakeUploadRepository _fallback = FakeUploadRepository();

  static String _configuredGoogleMapsApiKey() {
    if (dotenv.isInitialized) {
      final envKey = dotenv.maybeGet('GOOGLE_MAPS_API_KEY')?.trim();
      if (envKey != null && envKey.isNotEmpty) return envKey;
    }
    return const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  }

  @override
  Future<List<UploadPhoto>> fetchGallery() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      throw const UploadPermissionException(
        '사진 보관함 권한이 필요합니다. 기기 설정에서 사진 접근을 허용해 주세요.',
      );
    }

    final entities = await PhotoManager.getAssetListPaged(
      page: 0,
      pageCount: 60,
      type: RequestType.image,
    );
    return Future.wait(entities.map(_toUploadPhoto));
  }

  Future<UploadPhoto> _toUploadPhoto(AssetEntity entity) async {
    final thumbnail = await entity.thumbnailDataWithSize(
      const ThumbnailSize.square(600),
      quality: 88,
    );
    final location = await entity.latlngAsync();
    return UploadPhoto(
      id: entity.id,
      thumbnailBytes: thumbnail,
      source: UploadPhotoSource.deviceLibrary,
      latitude: location?.latitude,
      longitude: location?.longitude,
      aspectRatio: entity.height == 0 ? null : entity.width / entity.height,
    );
  }

  @override
  Future<List<UploadPhoto>> fetchDraftGallery() async => const [];

  @override
  Future<void> openMediaSettings() => PhotoManager.openSetting();

  @override
  Future<List<UploadPlace>> matchPlaces(UploadPhoto photo) async {
    final point = photo.hasLocationMetadata
        ? Position(
            longitude: photo.longitude!,
            latitude: photo.latitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          )
        : await _currentPosition();
    _requirePlacesKey();

    final response = await _httpClient.post(
      Uri.parse('$_placesHost/places:searchNearby'),
      headers: _headers(
        'places.id,places.displayName,places.formattedAddress,places.location',
      ),
      body: jsonEncode({
        'languageCode': 'ko',
        'maxResultCount': 5,
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
            'radius': 1500.0,
          },
        },
      }),
    );
    return _parsePlaces(response, origin: point);
  }

  @override
  Future<List<UploadPlace>> searchPlaces(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    if (_googleMapsApiKey.isEmpty) {
      return _fallback.searchPlaces(keyword);
    }
    final response = await _httpClient.post(
      Uri.parse('$_placesHost/places:searchText'),
      headers: _headers('places.id,places.displayName,places.formattedAddress'),
      body: jsonEncode({
        'textQuery': keyword.trim(),
        'languageCode': 'ko',
        'pageSize': 10,
      }),
    );
    return _parsePlaces(response);
  }

  Map<String, String> _headers(String fieldMask) => {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': _googleMapsApiKey,
    'X-Goog-FieldMask': fieldMask,
  };

  List<UploadPlace> _parsePlaces(http.Response response, {Position? origin}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UploadLocationException(
        'Google Places 장소 검색에 실패했습니다. (${response.statusCode})',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final places = body['places'] as List<dynamic>? ?? const [];
    return places.map((raw) {
      final json = raw as Map<String, dynamic>;
      final location = json['location'] as Map<String, dynamic>?;
      final distance = origin == null || location == null
          ? null
          : Geolocator.distanceBetween(
              origin.latitude,
              origin.longitude,
              (location['latitude'] as num).toDouble(),
              (location['longitude'] as num).toDouble(),
            ).round();
      final displayName = json['displayName'] as Map<String, dynamic>?;
      return UploadPlace(
        id: json['id'] as String,
        name: displayName?['text'] as String? ?? '이름 없는 장소',
        address: json['formattedAddress'] as String? ?? '',
        distanceMeters: distance,
      );
    }).toList();
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UploadLocationException('기기의 위치 서비스를 켜 주세요.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const UploadLocationException(
        '위치 권한이 없어 자동 매칭할 수 없습니다. 장소를 직접 검색해 주세요.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  void _requirePlacesKey() {
    if (_googleMapsApiKey.isEmpty) {
      throw const UploadLocationException(
        'GOOGLE_MAPS_API_KEY가 설정되지 않아 자동 장소 매칭을 사용할 수 없습니다.',
      );
    }
  }

  @override
  Future<UploadResult> createPost(UploadDraft draft) async {
    final resolvedPhotos = await Future.wait(
      draft.photos.map(_resolveOriginal),
    );
    final primary = resolvedPhotos.firstWhere(
      (photo) => photo.id == draft.primaryPhoto.id,
    );
    return _fallback.createPost(
      UploadDraft(
        photos: resolvedPhotos,
        primaryPhoto: primary,
        title: draft.title,
        description: draft.description,
        place: draft.place,
      ),
    );
  }

  Future<UploadPhoto> _resolveOriginal(UploadPhoto photo) async {
    if (photo.filePath != null ||
        photo.source != UploadPhotoSource.deviceLibrary) {
      return photo;
    }
    final entity = await AssetEntity.fromId(photo.id);
    final file = await entity?.originFile;
    if (file == null) {
      throw const UploadPermissionException(
        '선택한 사진 원본을 읽지 못했습니다. 사진 접근 권한을 확인해 주세요.',
      );
    }
    return photo.copyWith(filePath: file.path);
  }
}
