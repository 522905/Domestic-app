import 'package:equatable/equatable.dart';

abstract class ActiveExtensionsEvent extends Equatable {
  const ActiveExtensionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveExtensions extends ActiveExtensionsEvent {
  const LoadActiveExtensions();
}

class RefreshActiveExtensions extends ActiveExtensionsEvent {
  const RefreshActiveExtensions();
}
