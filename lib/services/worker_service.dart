import 'package:dio/dio.dart';
import 'package:ikigai_provider_app/core/constants/api_constants.dart';

class WorkerModel {
  WorkerModel({
    required this.id,
    required this.shopId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.speciality,
    this.bufferMinutes,
    this.isActive,
    this.schedules,
  });

  final int id;
  final int shopId;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? speciality;
  final int? bufferMinutes;
  final bool? isActive;
  final List<WorkerScheduleModel>? schedules;

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      shopId: json['shop_id'] is int ? json['shop_id'] as int : int.parse('${json['shop_id']}'),
      firstName: '${json['first_name'] ?? ''}',
      lastName: '${json['last_name'] ?? ''}',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      speciality: json['speciality']?.toString(),
      bufferMinutes: json['buffer_minutes'] != null
          ? (json['buffer_minutes'] is int ? json['buffer_minutes'] as int : int.tryParse('${json['buffer_minutes']}'))
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      schedules: (json['schedules'] as List<dynamic>?)
          ?.map((e) => WorkerScheduleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  String get displayName => '$firstName $lastName'.trim();
}

class WorkerScheduleModel {
  WorkerScheduleModel({
    required this.id,
    required this.workerId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive,
  });

  final int id;
  final int workerId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool? isActive;

  factory WorkerScheduleModel.fromJson(Map<String, dynamic> json) {
    return WorkerScheduleModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      workerId: json['worker_id'] is int ? json['worker_id'] as int : int.parse('${json['worker_id']}'),
      dayOfWeek: json['day_of_week'] is int ? json['day_of_week'] as int : int.parse('${json['day_of_week']}'),
      startTime: '${json['start_time'] ?? ''}',
      endTime: '${json['end_time'] ?? ''}',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class WorkerService {
  WorkerService({required String? Function() tokenProvider}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 25),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  late final Dio _dio;

  Future<List<WorkerModel>> fetchByShop(int shopId) async {
    final res = await _dio.get<List<dynamic>>('/workers/shop/$shopId');
    return (res.data ?? [])
        .map((e) => WorkerModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<WorkerModel> create({
    required int shopId,
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? speciality,
    int? bufferMinutes,
    List<Map<String, dynamic>>? schedules,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/workers',
      data: {
        'shop_id': shopId,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        if (speciality != null && speciality.isNotEmpty) 'speciality': speciality,
        if (bufferMinutes != null) 'buffer_minutes': bufferMinutes,
        if (schedules != null && schedules.isNotEmpty) 'schedules': schedules,
      },
    );
    final data = res.data;
    if (data == null) throw DioException(requestOptions: res.requestOptions, message: 'Create worker failed');
    return WorkerModel.fromJson(data);
  }

  Future<WorkerModel> update({
    required int id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? speciality,
    int? bufferMinutes,
    bool? isActive,
    List<Map<String, dynamic>>? schedules,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/workers/$id',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (speciality != null) 'speciality': speciality,
        if (bufferMinutes != null) 'buffer_minutes': bufferMinutes,
        if (isActive != null) 'is_active': isActive,
        if (schedules != null) 'schedules': schedules,
      },
    );
    final data = res.data;
    if (data == null) throw DioException(requestOptions: res.requestOptions, message: 'Update worker failed');
    return WorkerModel.fromJson(data);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/workers/$id');
  }

  Future<List<Map<String, dynamic>>> getWorkerBookings(int workerId) async {
    final res = await _dio.get<List<dynamic>>('/workers/$workerId/bookings');
    return (res.data ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<String> uploadImage(String path) async {
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
}
