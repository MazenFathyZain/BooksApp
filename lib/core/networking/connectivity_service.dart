import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Tells the app whether the device has a network connection.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  Future<bool> isOnline() async {
    try {
      return _hasConnection(await _connectivity.checkConnectivity());
    } catch (_) {
      // If the platform check fails, assume online and let requests decide.
      return true;
    }
  }

  /// Whether the internet is actually reachable, not just whether Wi-Fi or
  /// mobile data is switched on. Used to tell "no internet" apart from "our
  /// server is down".
  Future<bool> hasInternet() async {
    if (!await isOnline()) {
      return false;
    }
    for (final host in const ['google.com', 'cloudflare.com']) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 4));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Try the next host.
      }
    }
    return false;
  }

  /// Emits true when the device goes online and false when it goes offline.
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  /// Whether [error] means the server could not be reached at all, as
  /// opposed to the server answering with an error.
  static bool isConnectionError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.error is SocketException;
    }
    return error is SocketException;
  }

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
