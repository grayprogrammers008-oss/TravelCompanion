import '../../../../shared/models/itinerary_model.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_local_datasource.dart';

/// Implementation of itinerary repository using local datasource
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryLocalDataSource localDataSource;

  ItineraryRepositoryImpl(this.localDataSource);

  @override
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    return await localDataSource.createItem(
      tripId: tripId,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
    );
  }

  @override
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) async {
    return await localDataSource.getTripItinerary(tripId);
  }

  @override
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) async {
    return await localDataSource.getDayItinerary(
      tripId: tripId,
      dayNumber: dayNumber,
    );
  }

  @override
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) async {
    return await localDataSource.getItineraryByDays(tripId);
  }

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) async {
    return await localDataSource.getItem(itemId);
  }

  @override
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    return await localDataSource.updateItem(
      itemId: itemId,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
    );
  }

  @override
  Future<void> deleteItineraryItem(String itemId) async {
    return await localDataSource.deleteItem(itemId);
  }

  @override
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    return await localDataSource.reorderItems(
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
    return await localDataSource.moveItemToDay(
      itemId: itemId,
      newDayNumber: newDayNumber,
    );
  }
}
