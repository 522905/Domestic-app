# LPG Distribution Management System - Flutter App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.0+-blue)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.0+-blue)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

## Overview

This is a comprehensive mobile application for digitizing domestic LPG distribution operations. The app handles complex multi-account transactions, inventory management, four-eye approval workflows, and real-time synchronization with Django backend and ERPNext systems.

**Warning**: This is not a simple CRUD app. The business logic is intricate with multiple account types, complex validation rules, temporal assignments, and strict compliance requirements. Expect significant development time and thorough testing needs.

## Business Context

The app serves a domestic LPG distribution business with multiple stakeholders:
- **Delivery Boys/CSEs**: Order creation, inventory collection/deposits
- **Cashiers**: SV/TV approvals, payment processing
- **Warehouse Managers**: Refill/NFR approvals, inventory management
- **General Managers**: Override capabilities, escalation handling

### Core Business Entities
- **SV/TV Account**: Subscription Vouchers (new connections) and Termination Vouchers
- **Refill Account**: Filled cylinder sales with dynamic limits and cooldown periods
- **NFR Account**: Non-fuel items (pipes, regulators, consumables)

## Architecture

### Pattern
- **MVVM** with Repository Pattern
- **BLoC** for state management
- **Clean Architecture** principles
- **Offline-first** approach with synchronization

### Key Technical Challenges
1. **Multi-Account Transaction Logic**: Complex financial flows across SV/TV, Refill, and NFR accounts
2. **Four-Eye Approval Workflows**: Role-based approval chains with escalation and amendment flows
3. **Real-time Synchronization**: WebSocket notifications + batch ERP sync + RPA triggers
4. **Temporal Business Rules**: 7-day rolling averages, 2.5h cooldowns, vehicle-warehouse mappings
5. **Offline Capability**: Queue management with conflict resolution
6. **Document Management**: Attachment workflows with verification requirements

## Features

### Order Management
- **Refill Orders**: Subject to rolling average limits (7-day × 1.10/1.20 multipliers)
- **NFR Orders**: One-way add-on items with warehouse-specific stock
- **SV/TV Orders**: Created via DCA/ERP integration, appear as read-only SOs
- **Manual Returns**: Time-bounded with escalation on overdue

### Inventory Operations
- **Collect**: Aggregate items from multiple SOs into single transaction
- **Deposit**: Link to Refill SOs or Material Requests, FIFO for unlinked
- **Transfer**: Inter-warehouse movements with gatepass generation
- **Stock Visibility**: Role-based, account-filtered real-time views

### Approval Workflows
- **Four-Eye Principle**: Creator ≠ Approver with role-based routing
- **Amendment Flow**: Reject → Amend → Resubmit (excludes SV amendments)
- **Manager Override**: Bypass limits and cooldown with audit logging
- **Escalation**: Configurable thresholds with auto-cancellation

### Financial Management
- **Virtual Code System**: Payment allocation to specific accounts/SOs
- **Multi-Account Tracking**: Separate balances and transaction histories
- **Partial Payments**: Supported with allocation tracking

## Project Structure

```
lib/
├── app/
│   ├── app.dart                 # MaterialApp configuration
│   └── theme.dart               # Global theme (Brand Blue #0E5CA8, Orange #F7941D)
├── core/
│   ├── constants/               # API endpoints, business rules
│   ├── errors/                  # Error handling models
│   ├── network/                 # Dio client, interceptors, JWT handling
│   ├── services/                # WebSocket, notifications, file management
│   └── utils/                   # Date helpers, validators, formatters
├── data/
│   ├── datasources/
│   │   ├── remote/              # API clients, WebSocket handlers
│   │   └── local/               # SQLite, Hive, SharedPreferences
│   ├── models/                  # JSON serializable data models
│   └── repositories/            # Repository implementations
├── domain/
│   ├── entities/                # Business objects (Order, Inventory, Approval)
│   ├── repositories/            # Repository interfaces
│   └── usecases/                # Business logic (CreateOrder, ProcessApproval)
├── presentation/
│   ├── blocs/                   # State management
│   │   ├── auth/
│   │   ├── orders/
│   │   ├── inventory/
│   │   ├── approvals/
│   │   └── notifications/
│   ├── pages/                   # Screen widgets
│   ├── widgets/                 # Reusable UI components
│   └── routes/                  # Navigation configuration
└── main.dart
```

## Setup & Installation

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK (API 21+) / Xcode 13+

### Environment Configuration
```bash
# Clone repository
git clone [repository-url]
cd lpg-distribution-app

# Install dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build

# Set up environments
cp .env.example .env.dev
cp .env.example .env.staging  
cp .env.example .env.prod
```

### Required Environment Variables
```env
# API Configuration
API_BASE_URL=https://api.example.com
WS_URL=wss://api.example.com/ws
API_TIMEOUT=30000

# Authentication
JWT_SECRET_KEY=your-secret-key

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FCM_SENDER_ID=your-sender-id

# App Configuration
APP_NAME=LPG Distribution
APP_VERSION=1.0.0
```

## Key Dependencies

### Core
```yaml
# State Management
flutter_bloc: ^8.1.3
provider: ^6.1.1

# Navigation
go_router: ^13.2.0

# Network
dio: ^5.4.0
web_socket_channel: ^2.4.0

# Local Storage
sqflite: ^2.3.0
hive: ^2.2.3
shared_preferences: ^2.2.2
flutter_secure_storage: ^9.0.0

# UI Components
flutter_form_builder: ^9.1.1
table_calendar: ^3.0.9
file_picker: ^6.1.1

# Utils
intl: ^0.19.0
collection: ^1.18.0
rxdart: ^0.27.7

# Firebase
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
firebase_analytics: ^10.8.0
firebase_crashlytics: ^3.4.8
```

## Business Rules Implementation

### Order Limits & Validation
```dart
class RefillOrderValidator {
  static bool validateOrder(Order order, List<Order> recentOrders) {
    // 7-day rolling average with multipliers
    final sevenDayAvg = calculateSevenDayAverage(recentOrders);
    final limit = sevenDayAvg * getMultiplier(order.deliveryBoyTier);
    
    // 2.5 hour cooldown check
    final lastOrder = getLastOrderForVehicle(order.vehicleId);
    if (lastOrder != null && 
        DateTime.now().difference(lastOrder.createdAt).inHours < 2.5) {
      throw CooldownViolationException();
    }
    
    // One active SO per vehicle
    if (hasActiveOrder(order.vehicleId)) {
      throw ActiveOrderExistsException();
    }
    
    return order.quantity <= limit;
  }
}
```

### Four-Eye Approval Flow
```dart
class ApprovalWorkflow {
  static bool canApprove(User approver, Order order) {
    // Creator cannot approve their own order
    if (approver.id == order.createdBy) return false;
    
    // Role-based approval rights
    switch (order.type) {
      case OrderType.sv:
      case OrderType.tv:
        return approver.role == Role.cashier;
      case OrderType.refill:
      case OrderType.nfr:
        return approver.role == Role.warehouseManager;
      default:
        return false;
    }
  }
}
```

## API Integration

### Authentication
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer ${getAccessToken()}';
    options.headers['Content-Type'] = 'application/json';
    super.onRequest(options, handler);
  }
}
```

### WebSocket for Real-time Updates
```dart
class WebSocketService {
  late IOWebSocketChannel _channel;
  
  void connect() {
    _channel = IOWebSocketChannel.connect(wsUrl);
    _channel.stream.listen(
      (message) => _handleMessage(jsonDecode(message)),
      onError: (error) => _handleError(error),
      onDone: () => _reconnect(),
    );
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'order_status_update':
        OrdersBloc.instance.add(OrderStatusUpdated(message['data']));
        break;
      case 'stock_update':
        InventoryBloc.instance.add(StockUpdated(message['data']));
        break;
      case 'approval_required':
        ApprovalBloc.instance.add(NewApprovalRequired(message['data']));
        break;
    }
  }
}
```

## Testing Strategy

### Coverage Requirements
- **Unit Tests**: 80%+ coverage for domain and data layers
- **Widget Tests**: All custom widgets and critical user flows
- **Integration Tests**: End-to-end approval workflows
- **Golden Tests**: UI consistency across screen sizes

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Development Guidelines

### Code Quality
- Strict lint rules with `flutter_lints`
- Mandatory documentation for public APIs
- Pre-commit hooks for formatting and analysis

### BLoC Pattern
```dart
// Event
abstract class OrderEvent extends Equatable {}

class CreateOrderRequested extends OrderEvent {
  final OrderRequest request;
  CreateOrderRequested(this.request);
}

// State  
abstract class OrderState extends Equatable {}

class OrderSubmitted extends OrderState {
  final String orderId;
  OrderSubmitted(this.orderId);
}

// BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc(this._createOrderUseCase) : super(OrderInitial()) {
    on<CreateOrderRequested>(_onCreateOrderRequested);
  }
  
  Future<void> _onCreateOrderRequested(
    CreateOrderRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      emit(OrderSubmitting());
      final result = await _createOrderUseCase(event.request);
      emit(OrderSubmitted(result.orderId));
    } catch (e) {
      emit(OrderSubmissionFailed(e.toString()));
    }
  }
}
```

## Known Complexities & Gotchas

### Business Logic Challenges
1. **Temporal Vehicle Assignments**: Valid-until dates with overlap detection
2. **Amendment Restrictions**: SV amendments removed, only Refill/NFR amendable
3. **Account Offset Calculations**: CSE/delivery boy balances affect limits
4. **Escalation Timing**: EOD thresholds with configurable delays
5. **RPA Integration**: TV In/Out processing with auto-SO/MR creation

### Technical Challenges
1. **Offline-Online Sync**: Conflict resolution for concurrent edits
2. **Real-time Push Rules**: Selective stock updates vs. universal SO updates
3. **Multi-Item Selection**: Complex UI state management
4. **Gatepass Generation**: PDF creation with QR codes
5. **Role-based UI**: Dynamic widget composition based on permissions

### Performance Considerations
- Large order lists require pagination and virtual scrolling
- Image attachments need compression and caching strategies
- Real-time updates can overwhelm UI if not throttled
- Offline queue can grow large and needs periodic cleanup

## Deployment

### Build Variants
```bash
# Development
flutter build apk --flavor dev -t lib/main_dev.dart

# Staging  
flutter build apk --flavor staging -t lib/main_staging.dart

# Production
flutter build apk --release --flavor prod -t lib/main_prod.dart
```

### Release Checklist
- [ ] All tests passing
- [ ] Code coverage ≥80%
- [ ] Security audit completed
- [ ] Performance testing done
- [ ] Accessibility testing completed
- [ ] Backend API compatibility verified
- [ ] Offline synchronization tested
- [ ] Role-based access control verified

## Monitoring & Analytics

### Error Tracking
- Firebase Crashlytics for crash reporting
- Custom error tracking for business logic failures
- Performance monitoring for critical user journeys

### Analytics Events
- Order creation/completion rates
- Approval workflow bottlenecks
- Feature usage by role
- Offline usage patterns

## Contributing

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch
- `feature/*`: Feature development
- `hotfix/*`: Production fixes

### Pull Request Requirements
- All tests passing
- Code review by senior developer
- Business logic review for complex features
- UI/UX review for user-facing changes

## Support & Documentation

- **API Documentation**: [Backend API Docs URL]
- **Business Rules**: See `docs/business-rules.md`
- **UI Guidelines**: See `docs/design-guidelines.md`
- **Troubleshooting**: See `docs/troubleshooting.md`

## License

Proprietary - All rights reserved. This software is confidential and proprietary information.

---

**Reality Check**: This app implements complex business processes with multiple stakeholders, temporal rules, financial reconciliation, and real-time synchronization. Budget appropriately for development time, testing, and ongoing maintenance. The offline-first approach with conflict resolution adds significant complexity. Plan for extensive business user testing and iterative refinement.