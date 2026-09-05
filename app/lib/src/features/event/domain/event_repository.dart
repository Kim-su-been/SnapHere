import 'package:snap_here/src/features/event/domain/event_models.dart';

abstract interface class EventRepository {
  Future<List<EventRegionSummary>> fetchRegionSummary();

  Future<List<EventSummary>> fetchEvents({int? areaCode});

  Future<EventDetail> fetchEvent(String eventId);

  Future<List<EventPost>> fetchEventPosts(String eventId);

  Future<EventUploadContext> fetchUploadContext(String eventId);
}

class EventFailure implements Exception {
  const EventFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
