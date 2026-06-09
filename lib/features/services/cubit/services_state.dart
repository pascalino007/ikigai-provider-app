part of 'services_cubit.dart';

sealed class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

final class ServicesInitial extends ServicesState {
  const ServicesInitial();
}

final class ServicesLoading extends ServicesState {
  const ServicesLoading();
}

final class ServicesLoaded extends ServicesState {
  const ServicesLoaded({required this.items});

  final List<ServiceItem> items;

  @override
  List<Object?> get props => [items];
}

final class ServicesError extends ServicesState {
  const ServicesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
