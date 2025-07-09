import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiServiceInterface apiService; // Works with both real and mock

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final userData = await apiService.login(
        event.username,
        event.password,
      );

      emit(AuthAuthenticated(userData));
    } catch (e) {
      emit(AuthError('Login failed. Please check your credentials.'));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await apiService.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError('Logout failed. Please try again.'));
    }
  }
}