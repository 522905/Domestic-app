import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/ujjwala/ujjwala_photo_upload.dart';

abstract class UjjwalaInstallationsEvent extends Equatable {
  const UjjwalaInstallationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingInstallations extends UjjwalaInstallationsEvent {
  const LoadPendingInstallations();
}

class RefreshPendingInstallations extends UjjwalaInstallationsEvent {
  const RefreshPendingInstallations();
}

class CapturePhoto extends UjjwalaInstallationsEvent {
  final PhotoType photoType;
  final ImageSource source;

  const CapturePhoto({
    required this.photoType,
    this.source = ImageSource.camera,
  });

  @override
  List<Object?> get props => [photoType, source];
}

class UploadPhoto extends UjjwalaInstallationsEvent {
  final PhotoType photoType;

  const UploadPhoto({required this.photoType});

  @override
  List<Object?> get props => [photoType];
}

class UpdatePhotoUploadProgress extends UjjwalaInstallationsEvent {
  final PhotoType photoType;
  final double progress;

  const UpdatePhotoUploadProgress({
    required this.photoType,
    required this.progress,
  });

  @override
  List<Object?> get props => [photoType, progress];
}

class PhotoUploadComplete extends UjjwalaInstallationsEvent {
  final PhotoType photoType;
  final String uploadedUrl;

  const PhotoUploadComplete({
    required this.photoType,
    required this.uploadedUrl,
  });

  @override
  List<Object?> get props => [photoType, uploadedUrl];
}

class PhotoUploadError extends UjjwalaInstallationsEvent {
  final PhotoType photoType;
  final String error;

  const PhotoUploadError({
    required this.photoType,
    required this.error,
  });

  @override
  List<Object?> get props => [photoType, error];
}

class DeletePhoto extends UjjwalaInstallationsEvent {
  final PhotoType photoType;

  const DeletePhoto({required this.photoType});

  @override
  List<Object?> get props => [photoType];
}

class FetchLocation extends UjjwalaInstallationsEvent {
  const FetchLocation();
}

class SubmitInstallation extends UjjwalaInstallationsEvent {
  const SubmitInstallation();
}

class SearchInstallations extends UjjwalaInstallationsEvent {
  final String query;

  const SearchInstallations({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadInstallationHistory extends UjjwalaInstallationsEvent {
  const LoadInstallationHistory();
}
