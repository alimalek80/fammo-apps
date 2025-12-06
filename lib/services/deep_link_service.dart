import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;
  Function(Uri)? onLinkReceived;

  void initialize(Function(Uri) callback) {
    onLinkReceived = callback;

    // Handle initial link when app is launched from closed state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('Initial deep link: $uri');
        onLinkReceived?.call(uri);
      }
    }).catchError((err) {
      print('Failed to get initial URI: $err');
    });

    // Handle links when app is already running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      print('Received deep link while running: $uri');
      onLinkReceived?.call(uri);
    }, onError: (err) {
      print('Deep link stream error: $err');
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
