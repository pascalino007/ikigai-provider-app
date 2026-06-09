import 'package:dio/dio.dart';
import 'package:ikigai_provider_app/data/dio/app_dio.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/entities/category.dart';
import 'package:ikigai_provider_app/domain/entities/geoville.dart';
import 'package:ikigai_provider_app/domain/entities/service_item.dart';
import 'package:ikigai_provider_app/domain/entities/shop.dart';
import 'package:ikigai_provider_app/domain/entities/shop_payload.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  PartnerRepositoryImpl({required String? Function() tokenProvider}) {
    _dio = AppDio(tokenProvider: tokenProvider).create();
  }

  late final Dio _dio;

  @override
  Future<List<Category>> fetchCategories() async {
    final res = await _dio.get<List<dynamic>>('/categories/');
    return (res.data ?? [])
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Geoville>> fetchGeovilles() async {
    final res = await _dio.get<List<dynamic>>('/geoville');
    return (res.data ?? [])
        .map((e) => Geoville.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Shop> fetchShopById(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/shops/$id');
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Shop not found');
    }
    return Shop.fromJson(data);
  }

  @override
  Future<Shop> updateShopStatus(int shopId, String status) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/shops/$shopId/status',
      data: {'status': status},
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Update status failed');
    }
    return Shop.fromJson(data);
  }

  @override
  Future<int> createShop(ShopPayload payload, {String? bearer}) async {
    final client = _dio;
    final res = await client.post<dynamic>('/shops', data: payload.toJson());
    final data = res.data;
    if (data is Map && data['id'] != null) {
      return data['id'] is int ? data['id'] as int : int.parse('${data['id']}');
    }
    throw DioException(requestOptions: res.requestOptions, message: 'Shop create failed');
  }

  @override
  Future<String> uploadImage(String path, {String? bearer}) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/upload',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final url = res.data?['imageUrl'] ?? res.data?['image_url'];
    if (url == null) throw DioException(requestOptions: res.requestOptions, message: 'Upload failed');
    return '$url';
  }

  @override
  Future<List<String>> uploadImages(List<String> paths, {String? bearer}) async {
    final files = <MultipartFile>[];
    for (final p in paths) {
      files.add(await MultipartFile.fromFile(p));
    }
    final form = FormData.fromMap({'images': files});
    final res = await _dio.post<Map<String, dynamic>>(
      '/upload/multiple',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final list = res.data?['imageUrls'] ?? res.data?['image_urls'];
    if (list is List) return list.map((e) => '$e').toList();
    throw DioException(requestOptions: res.requestOptions, message: 'Bulk upload failed');
  }

  @override
  Future<List<ServiceItem>> fetchServicesForShop(int shopId) async {
    final res = await _dio.get<List<dynamic>>('/services/shop/$shopId');
    return (res.data ?? [])
        .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<ServiceItem> createService({
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    String sousCategory = '',
    required String price,
    required String duration,
    String tags = '',
    String imageUrl = '',
    required String providerDisplayName,
    String? bearer,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/services',
      data: {
        'name': name,
        'description': description,
        'Category': categoryName,
        'sous_category': sousCategory,
        'price': price,
        'duration': duration,
        'tags': tags,
        'imageurl': imageUrl,
        'provider_id': shopId,
        'provider_name': providerDisplayName,
      },
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Create service failed');
    }
    return ServiceItem.fromJson(data);
  }

  @override
  Future<ServiceItem> updateService({
    required int id,
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    String sousCategory = '',
    required String price,
    required String duration,
    String tags = '',
    String imageUrl = '',
    required String providerDisplayName,
    String? bearer,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/services/$id',
      data: {
        'name': name,
        'description': description,
        'Category': categoryName,
        'sous_category': sousCategory,
        'price': price,
        'duration': duration,
        'tags': tags,
        'imageurl': imageUrl,
        'provider_id': shopId,
        'provider_name': providerDisplayName,
      },
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'Update service failed');
    }
    return ServiceItem.fromJson(data);
  }

  @override
  Future<void> deleteService(int id) async {
    await _dio.delete('/services/$id');
  }

  @override
  Future<List<Booking>> fetchBookingsForProvider(String providerUserId) async {
    final res = await _dio.get<List<dynamic>>('/bookings/provider/$providerUserId');
    return (res.data ?? [])
        .map((e) => Booking.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Booking> qrCheckin(String token) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/bookings/qr/checkin',
      data: {'token': token},
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'QR check-in failed');
    }
    return Booking.fromJson(data);
  }

  @override
  Future<Booking> qrCheckout(String token) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/bookings/qr/checkout',
      data: {'token': token},
    );
    final data = res.data;
    if (data == null) {
      throw DioException(requestOptions: res.requestOptions, message: 'QR check-out failed');
    }
    return Booking.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> fetchWalletSummary(int userId) async {
    final res = await _dio.get<Map<String, dynamic>>('/client-wallet/user/$userId/summary');
    return res.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchWalletTransactions(int userId) async {
    final res = await _dio.get<List<dynamic>>('/client-wallet/user/$userId/transactions');
    return res.data ?? [];
  }

  @override
  Future<void> requestWithdrawal(int userId, int amount, String phone) async {
    await _dio.post('/transactions/withdrawal/request', data: {
      'userId': userId,
      'amount': amount,
      'phone': phone,
    });
  }

  @override
  Future<Map<String, dynamic>?> fetchSubscription(int userId) async {
    final res = await _dio.get<Map<String, dynamic>>('/subscriptions/user/$userId');
    return res.data;
  }

  @override
  Future<Map<String, dynamic>> fetchShopWalletSummary(int shopId) async {
    final res = await _dio.get<Map<String, dynamic>>('/pro-wallet/shop/$shopId');
    return res.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchShopWalletTransactions(int shopId) async {
    final res = await _dio.get<List<dynamic>>('/pro-wallet/shop/$shopId/transactions');
    return res.data ?? [];
  }

  @override
  Future<void> requestShopWithdrawal(int shopId, int amount, String phone) async {
    await _dio.post('/pro-wallet/shop/$shopId/withdraw', data: {
      'amount': amount,
      'phone': phone,
    });
  }

  @override
  Future<Map<String, dynamic>?> fetchShopSubscription(int shopId) async {
    final res = await _dio.get<Map<String, dynamic>>('/subscriptions/shop/$shopId');
    return res.data;
  }
}
