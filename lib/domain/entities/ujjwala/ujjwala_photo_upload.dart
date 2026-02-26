import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoUploadStatus {
  idle,
  uploading,
  success,
  error,
}

enum PhotoType {
  kitchen,
  gate,
  stove,
}

class UjjwalaPhotoUpload extends Equatable {
  final XFile? file;
  final String? uploadedUrl;
  final double uploadProgress;
  final PhotoUploadStatus status;
  final String? errorMessage;

  const UjjwalaPhotoUpload({
    this.file,
    this.uploadedUrl,
    this.uploadProgress = 0.0,
    this.status = PhotoUploadStatus.idle,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        file,
        uploadedUrl,
        uploadProgress,
        status,
        errorMessage,
      ];

  UjjwalaPhotoUpload copyWith({
    XFile? file,
    String? uploadedUrl,
    double? uploadProgress,
    PhotoUploadStatus? status,
    String? errorMessage,
  }) {
    return UjjwalaPhotoUpload(
      file: file ?? this.file,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory UjjwalaPhotoUpload.empty() => const UjjwalaPhotoUpload();

  bool get isUploaded => status == PhotoUploadStatus.success && uploadedUrl != null;
  bool get isUploading => status == PhotoUploadStatus.uploading;
  bool get hasError => status == PhotoUploadStatus.error;
  bool get hasFile => file != null;
}
