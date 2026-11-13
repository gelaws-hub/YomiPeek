import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final androidProvider = Provider<AndroidGateway>((ref) {
  final gateway = AndroidGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

class FloatingState {
  const FloatingState({
    this.available = false,
    this.permission = false,
    this.shortcut = false,
    this.theme = 'system',
  });
  final bool available, permission, shortcut;
  final String theme;
}

class AndroidGateway {
  AndroidGateway() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') _changes.add(null);
      if (call.method == 'selection' && call.arguments is String) {
        _selections.add(call.arguments as String);
      }
    });
  }
  final _channel = const MethodChannel('org.yomipeek/platform');
  final _selections = StreamController<String>.broadcast();
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  Stream<String> get selections => _selections.stream;
  Future<String?> initialSelection() async {
    try {
      return await _channel.invokeMethod<String>('initialSelection');
    } on MissingPluginException {
      return null;
    }
  }

  Future<FloatingState> state() async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'floatingState',
      );
      return FloatingState(
        available: true,
        permission: value?['permission'] == true,
        shortcut: value?['shortcut'] == true,
        theme: value?['theme'] as String? ?? 'system',
      );
    } on MissingPluginException {
      return const FloatingState();
    }
  }

  Future<void> setTheme(String mode) async {
    try {
      await _channel.invokeMethod('setTheme', mode);
    } on MissingPluginException {
      /* Non-Android host. */
    }
  }

  Future<void> setTypography(Map<String, dynamic> value) async {
    try {
      await _channel.invokeMethod('setTypography', value);
    } on MissingPluginException {
      /* Non-Android host. */
    }
  }

  Future<void> validateFont(String file) async {
    try {
      await _channel.invokeMethod('validateFont', file);
    } on MissingPluginException {
      /* Native validation is added on Android. */
    }
  }

  Future<Map<String, dynamic>> typography() async =>
      (await _channel.invokeMapMethod<String, dynamic>('typography')) ?? {};

  Future<void> permission() => _channel.invokeMethod('overlayPermission');
  Future<void> open(String text) => _channel.invokeMethod('openFloating', text);
  Future<void> shortcut(bool enabled) =>
      _channel.invokeMethod('shortcut', enabled);
  Future<void> speak(String text) => _channel.invokeMethod('speak', text);
  void dispose() {
    _channel.setMethodCallHandler(null);
    _selections.close();
    _changes.close();
  }
}
