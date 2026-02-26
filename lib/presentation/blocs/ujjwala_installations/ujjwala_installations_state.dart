import 'package:equatable/equatable.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../../../domain/entities/ujjwala/ujjwala_photo_upload.dart';
import '../../../domain/entities/ujjwala/ujjwala_location.dart';

abstract class UjjwalaInstallationsState extends Equatable {
  const UjjwalaInstallationsState();

  @override
  List<Object?> get props => [];
}

class UjjwalaInstallationsInitial extends UjjwalaInstallationsState {
  const UjjwalaInstallationsInitial();
}

// List screen states
class PendingInstallationsLoading extends UjjwalaInstallationsState {
  const PendingInstallationsLoading();
}

class PendingInstallationsLoaded extends UjjwalaInstallationsState {
  final List<UjjwalaInstallation> installations;
  final int totalCount;

  const PendingInstallationsLoaded({
    required this.installations,
    int? totalCount,
  }) : totalCount = totalCount ?? 0;

  @override
  List<Object?> get props => [installations, totalCount];

  PendingInstallationsLoaded copyWith({
    List<UjjwalaInstallation>? installations,
    int? totalCount,
  }) {
    return PendingInstallationsLoaded(
      installations: installations ?? this.installations,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class PendingInstallationsEmpty extends UjjwalaInstallationsState {
  const PendingInstallationsEmpty();
}

class PendingInstallationsError extends UjjwalaInstallationsState {
  final String message;

  const PendingInstallationsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Submit screen state
class InstallationSubmitState extends UjjwalaInstallationsState {
  final UjjwalaInstallation installation;
  final Map<PhotoType, UjjwalaPhotoUpload> photos;
  final UjjwalaLocation? location;
  final bool isLocationLoading;
  final String? locationError;
  final bool isSubmitting;
  final bool submitSuccess;
  final String? submitError;

  const InstallationSubmitState({
    required this.installation,
    required this.photos,
    this.location,
    this.isLocationLoading = false,
    this.locationError,
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.submitError,
  });

  @override
  List<Object?> get props => [
        installation,
        photos,
        location,
        isLocationLoading,
        locationError,
        isSubmitting,
        submitSuccess,
        submitError,
      ];

  InstallationSubmitState copyWith({
    UjjwalaInstallation? installation,
    Map<PhotoType, UjjwalaPhotoUpload>? photos,
    UjjwalaLocation? location,
    bool? isLocationLoading,
    String? locationError,
    bool? isSubmitting,
    bool? submitSuccess,
    String? submitError,
  }) {
    return InstallationSubmitState(
      installation: installation ?? this.installation,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      locationError: locationError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      submitError: submitError,
    );
  }

  bool get canSubmit {
    // Check if all photos are uploaded
    final kitchenPhoto = photos[PhotoType.kitchen];
    final gatePhoto = photos[PhotoType.gate];
    final stovePhoto = photos[PhotoType.stove];

    final allPhotosUploaded = kitchenPhoto?.isUploaded == true &&
        gatePhoto?.isUploaded == true &&
        stovePhoto?.isUploaded == true;

    // Check if location is available
    final hasLocation = location != null;

    // Can't submit if already submitting
    if (isSubmitting) return false;

    return allPhotosUploaded && hasLocation;
  }

  bool get hasAnyPhoto {
    return photos.values.any((photo) => photo.hasFile);
  }

  bool get isAnyPhotoUploading {
    return photos.values.any((photo) => photo.isUploading);
  }
}
