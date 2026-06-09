class Booking {
  Booking({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.bookingDate,
    required this.bookingTime,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.serviceId,
    this.serviceName,
    this.serviceImageUrl,
    this.clientPhone,
    this.clientName,
    this.shopName,
    this.workerId,
    this.workerName,
    this.qrCheckinToken,
    this.qrCheckoutToken,
    this.checkedInAt,
    this.checkedOutAt,
  });

  final int id;
  final String userId;
  final String providerId;
  final DateTime bookingDate;
  final DateTime bookingTime;
  final int paymentStatus;
  final int bookingStatus;
  final String serviceId;
  final String? serviceName;
  final String? serviceImageUrl;
  final String? clientPhone;
  final String? clientName;
  final String? shopName;
  final String? workerId;
  final String? workerName;
  final String? qrCheckinToken;
  final String? qrCheckoutToken;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Flat fields from backend enrichBooking
    String? serviceName = json['service_name'] != null ? '${json['service_name']}' : null;
    String? serviceImageUrl = json['service_image_url'] != null ? '${json['service_image_url']}' : null;
    String? clientPhone = json['client_phone'] != null ? '${json['client_phone']}' : null;
    String? clientName = json['client_name'] != null ? '${json['client_name']}' : null;
    String? shopName = json['shop_name'] != null ? '${json['shop_name']}' : null;
    String? workerId = json['worker_id'] != null ? '${json['worker_id']}' : null;
    String? workerName = json['worker_name'] != null ? '${json['worker_name']}' : null;

    // Fallback: parse nested objects if flat fields missing
    if (serviceName == null) {
      final svc = json['service'];
      if (svc is Map<String, dynamic>) {
        serviceName = svc['name']?.toString();
        serviceImageUrl ??= svc['imageurl']?.toString();
      }
    }
    if (clientName == null || clientPhone == null) {
      final usr = json['user'];
      if (usr is Map<String, dynamic>) {
        clientPhone ??= usr['phone']?.toString();
        final fn = usr['firstname']?.toString() ?? '';
        final ln = usr['lastname']?.toString() ?? '';
        clientName ??= '$fn $ln'.trim();
      }
    }
    if (shopName == null) {
      final shp = json['shop'];
      if (shp is Map<String, dynamic>) {
        shopName = shp['name']?.toString();
      }
    }

    return Booking(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      userId: '${json['user_id']}',
      providerId: '${json['provider_id']}',
      bookingDate: DateTime.tryParse('${json['booking_date']}') ?? DateTime.now(),
      bookingTime: DateTime.tryParse('${json['booking_time']}') ?? DateTime.now(),
      paymentStatus: json['payement_status'] is int
          ? json['payement_status'] as int
          : int.tryParse('${json['payement_status'] ?? 0}') ?? 0,
      bookingStatus: json['booking_status'] is int
          ? json['booking_status'] as int
          : int.tryParse('${json['booking_status']}') ?? 0,
      serviceId: '${json['service_id']}',
      serviceName: serviceName?.isNotEmpty == true ? serviceName : null,
      serviceImageUrl: serviceImageUrl?.isNotEmpty == true ? serviceImageUrl : null,
      clientPhone: clientPhone?.isNotEmpty == true ? clientPhone : null,
      clientName: clientName?.isNotEmpty == true ? clientName : null,
      shopName: shopName?.isNotEmpty == true ? shopName : null,
      workerId: workerId?.isNotEmpty == true ? workerId : null,
      workerName: workerName?.isNotEmpty == true ? workerName : null,
      qrCheckinToken: json['qr_checkin_token']?.toString(),
      qrCheckoutToken: json['qr_checkout_token']?.toString(),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse('${json['checked_in_at']}')
          : null,
      checkedOutAt: json['checked_out_at'] != null
          ? DateTime.tryParse('${json['checked_out_at']}')
          : null,
    );
  }

  String get statusLabel {
    switch (bookingStatus) {
      case 0:
        return 'En attente';
      case 1:
        return 'Confirmé';
      case 2:
        return 'Annulé';
      case 3:
        return 'Paiement échoué';
      case 4:
        return 'En cours';
      case 5:
        return 'Effectué';
      case 6:
        return 'Passée sans action';
      default:
        return 'Inconnu';
    }
  }
}
