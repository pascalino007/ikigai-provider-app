import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/entities/category.dart';
import 'package:ikigai_provider_app/domain/entities/geoville.dart';
import 'package:ikigai_provider_app/domain/entities/service_item.dart';
import 'package:ikigai_provider_app/domain/entities/shop.dart';
import 'package:ikigai_provider_app/domain/entities/shop_payload.dart';

abstract class PartnerRepository {
  Future<List<Category>> fetchCategories();
  Future<List<Geoville>> fetchGeovilles();

  Future<Shop> fetchShopById(int id);
  Future<Shop> updateShopStatus(int shopId, String status);

  Future<int> createShop(ShopPayload payload, {String? bearer});

  Future<String> uploadImage(String path, {String? bearer});
  Future<List<String>> uploadImages(List<String> paths, {String? bearer});

  Future<List<ServiceItem>> fetchServicesForShop(int shopId);
  Future<ServiceItem> createService({
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    String sousCategory,
    required String price,
    required String duration,
    String tags,
    String imageUrl,
    required String providerDisplayName,
    String? bearer,
  });

  Future<ServiceItem> updateService({
    required int id,
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    String sousCategory,
    required String price,
    required String duration,
    String tags,
    String imageUrl,
    required String providerDisplayName,
    String? bearer,
  });

  Future<void> deleteService(int id);

  Future<List<Booking>> fetchBookingsForProvider(String providerUserId);

  /// Provider scans client QR → start service (CONFIRMED → IN_SERVICE)
  Future<Booking> qrCheckin(String token);

  /// Client scans provider QR → end service (IN_SERVICE → DONE)
  Future<Booking> qrCheckout(String token);

  Future<Map<String, dynamic>> fetchWalletSummary(int userId);
  Future<List<dynamic>> fetchWalletTransactions(int userId);
  Future<void> requestWithdrawal(int userId, int amount, String phone);
  Future<Map<String, dynamic>?> fetchSubscription(int userId);

  Future<Map<String, dynamic>> fetchShopWalletSummary(int shopId);
  Future<List<dynamic>> fetchShopWalletTransactions(int shopId);
  Future<void> requestShopWithdrawal(int shopId, int amount, String phone);
  Future<Map<String, dynamic>?> fetchShopSubscription(int shopId);
}
