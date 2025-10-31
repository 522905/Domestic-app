import 'package:flutter/material.dart';
import 'package:flutter_novu/inbox.dart';
import 'package:flutter_novu/types.dart';
import '../../../core/services/User.dart';
import '../../pages/notifications/notifications.dart';

class Inbox extends StatefulWidget {
  final String backendUrl;
  final String socketUrl;
  final Widget? icon;
  final List<InboxTab> tabs;

  const Inbox({
    super.key,
    this.backendUrl = 'https://novu.arungas.com',
    this.socketUrl = 'wss://novu.arungas.com',
    this.icon,
    this.tabs = const [],
  });

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  late final HeadlessService _headless;
  int unreadCount = 0;
  int unseenCount = 0;
  bool _isInitialized = false;

  // Add state variables for novu data
  String? applicationIdentifier;
  String? subscriberId;

  @override
  void initState() {
    super.initState();
    _loadNovuDataAndInitialize();
  }

  Future<void> _loadNovuDataAndInitialize() async {
    // Load novu data from storage first
    final appId = await User().getNovuApplicationIdentifier();
    final subId = await User().getNovuSubscriberId();

    setState(() {
      applicationIdentifier = appId;
      subscriberId = subId;
    });

    // Initialize service after loading data
    if (appId != null && subId != null) {
      _initializeService(applicationIdentifier!, subscriberId!);
    }
  }

  void _initializeService(String appId, String subId) {
    try {
      _headless = HeadlessService(
        backendUrl: widget.backendUrl,
        socketUrl: widget.socketUrl,
        applicationIdentifier: appId,
        subscriberId: subId,
        onUnreadChanged: (count) {
          if (mounted) {
            setState(() {
              unreadCount = count;
            });
          }
        },
        onUnseenChanged: (count) {
          if (mounted) {
            setState(() {
              unseenCount = count;
            });
          }
        },
        tabs: widget.tabs,
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing HeadlessService: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the service if needed
    super.dispose();
  }

  void _openNotifications() {
    if (_isInitialized) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => NotificationsScreen(
            headlessService: _headless,
          ),
        ),
      );
    } else {
      // Fallback behavior if service failed to initialize
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications service unavailable'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(
      icon: widget.icon ?? const Icon(Icons.notifications, color: Colors.white),
      onPressed: _openNotifications,
      tooltip: 'Notifications',
    );

    // Only show badge if service is initialized and has unread count
    if (_isInitialized && unreadCount > 0) {
      return Badge(
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        offset: const Offset(-4, 2),
        backgroundColor: Colors.red,
        textColor: Colors.white,
        child: iconButton,
      );
    }

    return iconButton;
  }
}