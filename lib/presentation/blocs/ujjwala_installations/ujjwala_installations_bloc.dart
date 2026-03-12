import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/ujjwala_photo_cache_service.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../../../domain/entities/ujjwala/ujjwala_photo_upload.dart';
import 'ujjwala_installations_event.dart';
import 'ujjwala_installations_state.dart';

class UjjwalaInstallationsBloc
    extends Bloc<UjjwalaInstallationsEvent, UjjwalaInstallationsState> {
  final ApiServiceInterface apiService;
  final LocationService locationService;
  final ImagePicker _imagePicker = ImagePicker();

  List<UjjwalaInstallation> _cachedInstallations = [];
  final Map<PhotoType, TusClient?> _tusClients = {};
  final UjjwalaPhotoCacheService _photoCache = UjjwalaPhotoCacheService();

  UjjwalaInstallationsBloc({
    required this.apiService,
    required this.locationService,
  }) : super(const UjjwalaInstallationsInitial()) {
    on<LoadPendingInstallations>(_onLoadPendingInstallations);
    on<RefreshPendingInstallations>(_onRefreshPendingInstallations);
    on<SearchInstallations>(_onSearchInstallations);
    on<CapturePhoto>(_onCapturePhoto);
    on<UploadPhoto>(_onUploadPhoto);
    on<UpdatePhotoUploadProgress>(_onUpdatePhotoUploadProgress);
    on<PhotoUploadComplete>(_onPhotoUploadComplete);
    on<PhotoUploadError>(_onPhotoUploadError);
    on<DeletePhoto>(_onDeletePhoto);
    on<FetchLocation>(_onFetchLocation);
    on<SubmitInstallation>(_onSubmitInstallation);
    on<LoadInstallationHistory>(_onLoadInstallationHistory);
  }

  Future<void> initializeSubmitState(UjjwalaInstallation installation) async {
    print('🏗️ Initializing submit state');
    print('📍 Installation coordinates: ${installation.latitude}, ${installation.longitude}');

    // Emit empty state immediately (fast)
    emit(InstallationSubmitState(
      installation: installation,
      photos: {
        PhotoType.kitchen: UjjwalaPhotoUpload.empty(),
        PhotoType.gate: UjjwalaPhotoUpload.empty(),
        PhotoType.stove: UjjwalaPhotoUpload.empty(),
      },
    ));

    // Restore cached photos — with local file preview if still on disk
    final restored = <PhotoType, UjjwalaPhotoUpload>{};
    for (final type in PhotoType.values) {
      final entry = await _photoCache.getPhoto(installation.id, type);
      if (entry != null) {
        final fileExists = File(entry.localFilePath).existsSync();
        restored[type] = UjjwalaPhotoUpload(
          file: fileExists ? XFile(entry.localFilePath) : null,
          uploadedUrl: entry.tusUrl,
          status: PhotoUploadStatus.success,
          uploadProgress: 100.0,
        );
        print('📦 Restored cached photo for $type (file on disk: $fileExists)');
      } else {
        restored[type] = UjjwalaPhotoUpload.empty();
      }
    }

    if (state is InstallationSubmitState) {
      emit((state as InstallationSubmitState).copyWith(photos: restored));
    }

    // Auto-fetch location and history on initialization
    add(const FetchLocation());
    add(const LoadInstallationHistory());
  }

  Future<void> _onLoadPendingInstallations(
    LoadPendingInstallations event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    // Return cached data if available
    if (_cachedInstallations.isNotEmpty) {
      emit(PendingInstallationsLoaded(
        installations: _cachedInstallations,
        totalCount: _cachedInstallations.length,
      ));
      return;
    }

    emit(const PendingInstallationsLoading());
    try {
      final response = await apiService.getPendingUjjwalaInstallations();
      final installations = response
          .map((json) => UjjwalaInstallation.fromJson(json))
          .toList();

      _cachedInstallations = installations;

      if (installations.isEmpty) {
        emit(const PendingInstallationsEmpty());
      } else {
        emit(PendingInstallationsLoaded(
          installations: installations,
          totalCount: installations.length,
        ));
      }
    } catch (e) {
      emit(PendingInstallationsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshPendingInstallations(
    RefreshPendingInstallations event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    emit(const PendingInstallationsLoading());
    try {
      final response = await apiService.getPendingUjjwalaInstallations();
      final installations = response
          .map((json) => UjjwalaInstallation.fromJson(json))
          .toList();

      _cachedInstallations = installations;

      if (installations.isEmpty) {
        emit(const PendingInstallationsEmpty());
      } else {
        emit(PendingInstallationsLoaded(
          installations: installations,
          totalCount: installations.length,
        ));
      }
    } catch (e) {
      emit(PendingInstallationsError(message: e.toString()));
    }
  }

  Future<void> _onSearchInstallations(
    SearchInstallations event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    final query = event.query.trim();

    // If query is empty, show all cached installations
    if (query.isEmpty) {
      emit(PendingInstallationsLoaded(
        installations: _cachedInstallations,
        totalCount: _cachedInstallations.length,
      ));
      return;
    }

    // Show loading state while searching
    emit(const PendingInstallationsLoading());

    try {
      // Call API search endpoint
      final response = await apiService.searchUjjwalaInstallations(query);
      final installations = response
          .map((json) => UjjwalaInstallation.fromJson(json))
          .toList();

      if (installations.isEmpty) {
        emit(const PendingInstallationsEmpty());
      } else {
        emit(PendingInstallationsLoaded(
          installations: installations,
          totalCount: installations.length,
        ));
      }
    } catch (e) {
      emit(PendingInstallationsError(message: 'Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onCapturePhoto(
    CapturePhoto event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: event.source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (photo != null) {
        final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
        updatedPhotos[event.photoType] = UjjwalaPhotoUpload(
          file: photo,
          status: PhotoUploadStatus.idle,
        );

        emit(currentState.copyWith(
          photos: updatedPhotos,
          submitError: null,
        ));

        // Auto-upload after capturing
        add(UploadPhoto(photoType: event.photoType));
      }
    } catch (e) {
      emit(currentState.copyWith(
        submitError: 'Failed to capture photo: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;
    final photoUpload = currentState.photos[event.photoType];

    if (photoUpload == null || photoUpload.file == null) return;

    try {
      // Update state to uploading
      final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
      updatedPhotos[event.photoType] = photoUpload.copyWith(
        status: PhotoUploadStatus.uploading,
        uploadProgress: 0.0,
      );

      emit(currentState.copyWith(
        photos: updatedPhotos,
        submitError: null,
      ));

      // Create TUS client
      final tusClient = TusClient(photoUpload.file!);
      _tusClients[event.photoType] = tusClient;

      print('🔵 TUS: Starting upload for ${event.photoType}');
      print('🔵 TUS: Upload URL: https://tus.dca.arungas.com/files/');
      print('🔵 TUS: File path: ${photoUpload.file!.path}');

      // Upload using TUS with a 90-second timeout
      await tusClient.upload(
        uri: Uri.parse('https://tus.dca.arungas.com/files/'),
        onProgress: (double progress, Duration total) {
          final percentage = progress;
          print('🔵 TUS: Upload progress: ${percentage.toStringAsFixed(1)}%');
          add(UpdatePhotoUploadProgress(
            photoType: event.photoType,
            progress: percentage,
          ));
        },
        onComplete: () {
          print('✅ TUS: Upload complete! URL: ${tusClient.uploadUrl}');
          add(PhotoUploadComplete(
            photoType: event.photoType,
            uploadedUrl: tusClient.uploadUrl.toString(),
          ));
        },
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () =>
            throw TimeoutException('Upload timed out after 90 seconds'),
      );
    } catch (e) {
      print('❌ TUS: Upload failed!');
      print('❌ TUS: Error type: ${e.runtimeType}');
      print('❌ TUS: Error message: $e');
      add(PhotoUploadError(
        photoType: event.photoType,
        error: _parseUploadError(e),
      ));
    }
  }

  void _onUpdatePhotoUploadProgress(
    UpdatePhotoUploadProgress event,
    Emitter<UjjwalaInstallationsState> emit,
  ) {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;
    final photoUpload = currentState.photos[event.photoType];

    if (photoUpload != null) {
      final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
      updatedPhotos[event.photoType] = photoUpload.copyWith(
        uploadProgress: event.progress,
      );

      emit(currentState.copyWith(photos: updatedPhotos));
    }
  }

  void _onPhotoUploadComplete(
    PhotoUploadComplete event,
    Emitter<UjjwalaInstallationsState> emit,
  ) {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;
    final photoUpload = currentState.photos[event.photoType];

    if (photoUpload != null) {
      final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
      updatedPhotos[event.photoType] = photoUpload.copyWith(
        uploadedUrl: event.uploadedUrl,
        uploadProgress: 100.0,
        status: PhotoUploadStatus.success,
      );

      emit(currentState.copyWith(photos: updatedPhotos));

      // Clean up TUS client
      _tusClients[event.photoType] = null;

      // Fire-and-forget: persist TUS URL + local file path for cache restore on re-entry
      if (photoUpload.file != null) {
        _photoCache.savePhoto(
          currentState.installation.id,
          event.photoType,
          event.uploadedUrl,
          photoUpload.file!.path,
        );
      }
    }
  }

  void _onPhotoUploadError(
    PhotoUploadError event,
    Emitter<UjjwalaInstallationsState> emit,
  ) {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;
    final photoUpload = currentState.photos[event.photoType];

    if (photoUpload != null) {
      final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
      updatedPhotos[event.photoType] = photoUpload.copyWith(
        status: PhotoUploadStatus.error,
        errorMessage: event.error,
        uploadProgress: 0.0,
      );

      emit(currentState.copyWith(
        photos: updatedPhotos,
        submitError: 'Failed to upload ${_getPhotoTypeName(event.photoType)}: ${event.error}',
      ));

      // Clean up TUS client
      _tusClients[event.photoType] = null;
    }
  }

  void _onDeletePhoto(
    DeletePhoto event,
    Emitter<UjjwalaInstallationsState> emit,
  ) {
    if (state is! InstallationSubmitState) return;

    final currentState = state as InstallationSubmitState;
    final updatedPhotos = Map<PhotoType, UjjwalaPhotoUpload>.from(currentState.photos);
    updatedPhotos[event.photoType] = UjjwalaPhotoUpload.empty();

    // Cancel any ongoing upload
    _tusClients[event.photoType] = null;

    emit(currentState.copyWith(
      photos: updatedPhotos,
      submitError: null,
    ));

    // Fire-and-forget: remove cache entry so re-entry shows capture button
    _photoCache.clearPhoto(currentState.installation.id, event.photoType);
  }

  Future<void> _onFetchLocation(
    FetchLocation event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    if (state is! InstallationSubmitState) return;
    emit((state as InstallationSubmitState).copyWith(
      isLocationLoading: true,
      locationError: null,
    ));

    try {
      print('📍 Fetching current GPS location...');
      final location = await locationService.getCurrentLocation();
      print('✅ Current GPS location: ${location.latitude}, ${location.longitude} (accuracy: ${location.accuracy}m)');
      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        location: location,
        isLocationLoading: false,
        locationError: null,
      ));
    } catch (e) {
      print('❌ Failed to get location: $e');
      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        isLocationLoading: false,
        locationError: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitInstallation(
    SubmitInstallation event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    if (state is! InstallationSubmitState) return;
    final snap = state as InstallationSubmitState;

    if (!snap.canSubmit) {
      emit(snap.copyWith(
        submitError: 'Please complete all photos and location before submitting',
      ));
      return;
    }

    // Capture the fields we need for the API call before any await.
    final installationId = snap.installation.id;
    final kitchenUrl = snap.photos[PhotoType.kitchen]!.uploadedUrl!;
    final gateUrl = snap.photos[PhotoType.gate]!.uploadedUrl!;
    final stoveUrl = snap.photos[PhotoType.stove]!.uploadedUrl!;
    final location = snap.location!;

    emit(snap.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
    ));

    try {
      final response = await apiService.submitUjjwalaInstallation(
        installationId: installationId,
        kitchenPhotoUrl: kitchenUrl,
        gatePhotoUrl: gateUrl,
        stovePhotoUrl: stoveUrl,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      );

      // API must return success: true — otherwise treat as a business error.
      if (response['success'] != true) {
        if (state is! InstallationSubmitState) return;
        emit((state as InstallationSubmitState).copyWith(
          isSubmitting: false,
          submitError: response['message']?.toString() ??
              'Submission failed. Please try again.',
        ));
        return;
      }

      // Clear cache to refresh list on return
      _cachedInstallations = [];

      // Clear photo cache so re-entry shows fresh state
      await _photoCache.clearAllPhotos(installationId);

      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        isSubmitting: false,
        submitSuccess: true,
      ));
    } catch (e) {
      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        isSubmitting: false,
        submitError: 'Failed to submit installation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadInstallationHistory(
    LoadInstallationHistory event,
    Emitter<UjjwalaInstallationsState> emit,
  ) async {
    if (state is! InstallationSubmitState) return;
    // Save only the installation ID before any await — do NOT snapshot the
    // whole state here, as concurrent handlers will have already mutated it.
    final installationId = (state as InstallationSubmitState).installation.id;
    emit((state as InstallationSubmitState)
        .copyWith(isHistoryLoading: true, historyError: null));
    try {
      final raw =
          await apiService.getUjjwalaInstallationHistory(installationId);
      final history =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        installationHistory: history,
        isHistoryLoading: false,
      ));
    } catch (_) {
      if (state is! InstallationSubmitState) return;
      emit((state as InstallationSubmitState).copyWith(
        isHistoryLoading: false,
        historyError: 'Could not load history.',
      ));
    }
  }

  String _parseUploadError(dynamic error) {
    if (error is TimeoutException) {
      return 'Upload timed out. Please check your network and retry.';
    }
    final errorString = error.toString();
    if (errorString.contains('412')) {
      return 'Upload precondition failed. Please try again.';
    } else if (errorString.contains('404')) {
      return 'Upload server not found (404). Please check TUS server configuration.';
    } else if (errorString.contains('401') || errorString.contains('403')) {
      return 'Upload authentication failed. Please contact support.';
    } else if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Server error. TUS server may be down.';
    } else if (errorString.contains('NetworkException') ||
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out')) {
      return 'Cannot reach TUS server (https://tus.dca.arungas.com/files/). Please check network connection and server status.';
    } else if (errorString.contains('No address associated with hostname')) {
      return 'TUS server hostname (tus.dca.arungas.com) cannot be resolved. Please check DNS configuration.';
    }
    return 'Upload failed: $errorString';
  }

  String _getPhotoTypeName(PhotoType type) {
    switch (type) {
      case PhotoType.kitchen:
        return 'kitchen photo';
      case PhotoType.gate:
        return 'gate photo';
      case PhotoType.stove:
        return 'stove photo';
    }
  }

  @override
  Future<void> close() {
    // Clean up TUS clients
    _tusClients.clear();
    return super.close();
  }
}
