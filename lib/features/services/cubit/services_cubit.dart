import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ikigai_provider_app/domain/entities/service_item.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';

part 'services_state.dart';

class ServicesCubit extends Cubit<ServicesState> {
  ServicesCubit(this._partnerRepository) : super(const ServicesInitial());

  final PartnerRepository _partnerRepository;

  Future<void> load(int shopId) async {
    if (shopId <= 0) {
      emit(const ServicesLoaded(items: []));
      return;
    }
    emit(const ServicesLoading());
    try {
      final list = await _partnerRepository.fetchServicesForShop(shopId);
      emit(ServicesLoaded(items: list));
    } catch (e) {
      emit(ServicesError('$e'));
    }
  }

  Future<void> create({
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    required String price,
    required String duration,
    String tags = '',
    String imageUrl = '',
    required String providerDisplayName,
  }) async {
    try {
      await _partnerRepository.createService(
        shopId: shopId,
        name: name,
        description: description,
        categoryName: categoryName,
        price: price,
        duration: duration,
        tags: tags,
        imageUrl: imageUrl,
        providerDisplayName: providerDisplayName,
      );
      await load(shopId);
    } catch (e) {
      emit(ServicesError('$e'));
    }
  }

  Future<void> update({
    required int id,
    required int shopId,
    required String name,
    required String description,
    required String categoryName,
    required String price,
    required String duration,
    String tags = '',
    String imageUrl = '',
    required String providerDisplayName,
  }) async {
    try {
      await _partnerRepository.updateService(
        id: id,
        shopId: shopId,
        name: name,
        description: description,
        categoryName: categoryName,
        price: price,
        duration: duration,
        tags: tags,
        imageUrl: imageUrl,
        providerDisplayName: providerDisplayName,
      );
      await load(shopId);
    } catch (e) {
      emit(ServicesError('$e'));
    }
  }

  Future<void> delete(int id, int shopId) async {
    try {
      await _partnerRepository.deleteService(id);
      await load(shopId);
    } catch (e) {
      emit(ServicesError('$e'));
    }
  }
}
