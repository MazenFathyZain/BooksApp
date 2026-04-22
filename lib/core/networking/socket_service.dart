import 'dart:async';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';

class SocketService {
  IO.Socket? _socket;
  Timer? _timer;
  bool _isTracking = false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      log('Socket already connected');
      return;
    }

    _socket = IO.io(
      'https://webtest.odoofuture.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setQuery({
        'token': token, // Send token as query param
      })
          .setExtraHeaders({
        'Authorization': 'Bearer $token',
      })
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      log('✅ Socket connected');
      // If tracking was requested before connection, start it now
      if (_isTracking) {
        _startLocationTracking();
      }
    });

    _socket!.onDisconnect((_) => log('❌ Socket disconnected'));
    _socket!.onError((e) => log('⚠️ Socket error: $e'));
    _socket!.onConnectError((e) => log('🔴 Connection error: $e'));
  }

  Future<void> startTracking({
    Duration interval = const Duration(seconds: 10),
  }) async {
    _isTracking = true;

    if (_socket == null || !_socket!.connected) {
      log('⚠️ Socket not connected. Tracking will start after connection.');
      return;
    }

    _startLocationTracking(interval: interval);
  }

  void _startLocationTracking({
    Duration interval = const Duration(seconds: 10),
  }) {
    _timer?.cancel();

    log('🚀 Starting location tracking with ${interval.inSeconds}s interval');

    _timer = Timer.periodic(interval, (_) async {
      try {
        if (_socket == null || !_socket!.connected) {
          log('⚠️ Socket disconnected, skipping location update');
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final data = {
          'lat': position.latitude,
          'lng': position.longitude,
          'speed': position.speed,
        };

        _socket!.emit('map_tracking', data);
        log('📍 Location sent: lat=${position.latitude}, lng=${position.longitude}');
      } catch (e) {
        log('❌ Error getting location: $e');
      }
    });
  }

  void stopTracking() {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    log('🛑 Location tracking stopped');
  }

  void disconnect() {
    stopTracking();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    log('🔌 Socket disconnected and disposed');
  }

  bool get isConnected => _socket?.connected ?? false;
  bool get isTracking => _isTracking && _timer != null;
}