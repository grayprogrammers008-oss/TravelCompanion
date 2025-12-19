import '../../../../shared/models/itinerary_model.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_remote_datasource.dart';

/// Implementation of itinerary repository using remote Supabase datasource
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryRemoteDataSource _remoteDataSource;

  ItineraryRepositoryImpl(this._remoteDataSource);

  @override
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    return await _remoteDataSource.createItem(
      tripId: tripId,
      title: title,
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
    );
  }

  @override
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) async {
    return await _remoteDataSource.getTripItinerary(tripId);
  }

  @override
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) async {
    return await _remoteDataSource.getDayItinerary(
      tripId: tripId,
      dayNumber: dayNumber,
    );
  }

  @override
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) async {
    return await _remoteDataSource.getItineraryByDays(tripId);
  }

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) async {
    return await _remoteDataSource.getItem(itemId);
  }

  @override
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    return await _remoteDataSource.updateItem(
      itemId: itemId,
      title: title,
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
    );
  }

  @override
  Future<void> deleteItineraryItem(String itemId) async {
    return await _remoteDataSource.deleteItem(itemId);
  }

  @override
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    return await _remoteDataSource.reorderItems(
      tripId: tripId,
      dayNumber: dayNumber,
      itemIds: itemIds,
    );
  }

  @override
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) async {
    return await _remoteDataSource.moveItemToDay(
      itemId: itemId,
      newDayNumber: newDayNumber,
    );
  }

  @override
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId) {
    try {
      return _remoteDataSource.watchTripItinerary(tripId);
    } catch (e) {
      throw Exception('Failed to watch trip itinerary: $e');
    }
  }

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) {
    try {
      return _remoteDataSource.watchItineraryByDays(tripId);
    } catch (e) {
      throw Exception('Failed to watch itinerary by days: $e');
    }
  }
}
