import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  bool _hasInternet = true;
  bool _isChecking = true;
  bool _initialized = false;

  bool get hasInternet => _hasInternet;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _isChecking = true;
    notifyListeners();

    await _updateConnectionStatus(showLoading: true);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasNetwork = !results.contains(ConnectivityResult.none);

      if (!hasNetwork) {
        _hasInternet = false;
        _isChecking = false;
        notifyListeners();
        return;
      }

      await _updateConnectionStatus(showLoading: false);
    });

    _internetSubscription = InternetConnection().onStatusChange.listen((
      status,
    ) {
      _hasInternet = status == InternetStatus.connected;
      _isChecking = false;
      notifyListeners();
    });
  }

  Future<void> _updateConnectionStatus({bool showLoading = false}) async {
    if (showLoading) {
      _isChecking = true;
      notifyListeners();
    }

    final connectivityResults = await _connectivity.checkConnectivity();
    final hasNetwork = !connectivityResults.contains(ConnectivityResult.none);

    if (!hasNetwork) {
      _hasInternet = false;
      _isChecking = false;
      notifyListeners();
      return;
    }

    _hasInternet = await InternetConnection().hasInternetAccess;
    _isChecking = false;
    notifyListeners();
  }

  Future<void> recheck() async {
    await _updateConnectionStatus(showLoading: true);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
