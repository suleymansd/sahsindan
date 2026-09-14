import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/listing.dart';

class ListingsRepository {
  ListingsRepository(this._dio);

  final Dio _dio;

  Future<List<Listing>> list({
    String? q,
    String? city,
    String? district,
    String? brand,
    String? model,
    String? transmission,
    String? fuel,
    String? color,
    double? minPrice,
    double? maxPrice,
    int? yearMin,
    int? yearMax,
    int? mileageMin,
    int? mileageMax,
    String sort = 'newest',
    int offset = 0,
    bool mine = false,
    bool includeInactive = false,
  }) async {
    final res = await _dio.get(
      '/listings',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (district != null && district.trim().isNotEmpty) 'district': district.trim(),
        if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
        if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
        if (transmission != null && transmission.trim().isNotEmpty) 'transmission': transmission.trim(),
        if (fuel != null && fuel.trim().isNotEmpty) 'fuel': fuel.trim(),
        if (color != null && color.trim().isNotEmpty) 'color': color.trim(),
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (yearMin != null) 'year_min': yearMin,
        if (yearMax != null) 'year_max': yearMax,
        if (mileageMin != null) 'mileage_min': mileageMin,
        if (mileageMax != null) 'mileage_max': mileageMax,
        'sort': sort,
        'limit': 50,
        'offset': offset,
        'mine': mine,
        'include_inactive': includeInactive,
      },
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) {
      return (obj as List<dynamic>).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    });

    return env.data;
  }

  Future<Listing> get(int id) async {
    final res = await _dio.get('/listings/$id');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Listing.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Listing> create({
    required String title,
    required String description,
    required double price,
    required String city,
    required String district,
    required String brand,
    required String model,
    required int year,
    required int mileage,
    required String transmission,
    required String fuel,
    required String color,
  }) async {
    final res = await _dio.post(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'city': city,
        'district': district,
        'car_details': {
          'brand': brand,
          'model': model,
          'year': year,
          'mileage': mileage,
          'transmission': transmission,
          'fuel': fuel,
          'color': color,
          'vin_optional': null,
        },
      },
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Listing.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Listing> update({
    required int id,
    String? title,
    String? description,
    double? price,
    String? district,
  }) async {
    final res = await _dio.put(
      '/listings/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (district != null) 'district': district,
      },
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Listing.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<void> publish(int id) async {
    await _dio.post('/listings/$id/publish');
  }

  Future<void> markSold(int id) async {
    await _dio.post('/listings/$id/mark-sold');
  }

  Future<void> confirmActive(int id) async {
    await _dio.post('/listings/$id/confirm-active');
  }

  Future<bool> favorite(int id) async {
    final res = await _dio.post('/listings/$id/favorite');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => obj as Map<String, dynamic>);
    return env.data['favorited'] == true;
  }

  Future<bool> unfavorite(int id) async {
    final res = await _dio.delete('/listings/$id/favorite');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => obj as Map<String, dynamic>);
    return env.data['favorited'] == true;
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required int listingId,
    required String filename,
    required List<int> bytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    });

    final res = await _dio.post(
      '/listings/$listingId/photos',
      data: form,
      onSendProgress: onProgress,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => obj as Map<String, dynamic>);
    return env.data;
  }

  Future<void> deletePhoto({required int listingId, required int photoId}) async {
    await _dio.delete('/listings/$listingId/photos/$photoId');
  }

  Future<void> reorderPhotos({required int listingId, required List<int> photoIds}) async {
    await _dio.post('/listings/$listingId/photos/reorder', data: {'photo_ids': photoIds});
  }

  Future<List<int>> favoriteIds() async {
    final res = await _dio.get("/favorites/ids");
    return (res.data["data"] as List).cast<int>();
  }

  Future<List<Listing>> favorites({int offset = 0}) async {
    final res = await _dio.get('/favorites', queryParameters: {'limit': 50, 'offset': offset});
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) {
      return (obj as List<dynamic>).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    });
    return env.data;
  }

  Future<List<Listing>> mine({bool includeInactive = true}) async {
    return list(mine: true, includeInactive: includeInactive);
  }
}
