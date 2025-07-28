import '../services/udp_discovery_service.dart';
import '../services/tcp_file_receiver.dart';
import '../models/app_state.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  static ServiceLocator get instance => _instance;

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Unregister a service
  void unregister<T>() {
    _services.remove(T);
  }

  /// Clear all services (for testing)
  void clear() {
    _services.clear();
  }

  /// Initialize all services
  Future<void> initializeServices(AppState appState) async {
    try {
      // Initialize UDP Discovery Service
      final udpService = UdpDiscoveryService();
      register<UdpDiscoveryService>(udpService);

      // Initialize TCP File Receiver
      final tcpReceiver = TcpFileReceiver(appState);
      register<TcpFileReceiver>(tcpReceiver);
      await tcpReceiver.startListening();

      print('All services initialized successfully');
    } catch (e) {
      print('Error initializing services: $e');
      rethrow;
    }
  }

  /// Dispose all services
  Future<void> disposeServices() async {
    try {
      // Dispose UDP Discovery Service
      if (isRegistered<UdpDiscoveryService>()) {
        final udpService = get<UdpDiscoveryService>();
        udpService.dispose();
        unregister<UdpDiscoveryService>();
      }

      // Dispose TCP File Receiver (no dispose method, server cleanup happens automatically)
      if (isRegistered<TcpFileReceiver>()) {
        unregister<TcpFileReceiver>();
      }

      print('All services disposed successfully');
    } catch (e) {
      print('Error disposing services: $e');
    }
  }
}
