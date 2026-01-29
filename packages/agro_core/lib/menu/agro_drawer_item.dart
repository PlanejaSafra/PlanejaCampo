import 'package:flutter/material.dart';

/// Route keys for standard drawer navigation.
class AgroRouteKeys {
  AgroRouteKeys._();

  static const String home = 'home';
  static const String properties = 'properties';
  static const String settings = 'settings';
  static const String privacy = 'privacy';
  static const String about = 'about';
  static const String heatmap = 'heatmap';
  static const String farmMembers = 'farmMembers';
  static const String farmInvite = 'farmInvite';
  static const String farmJoin = 'farmJoin';
}

/// Model for a drawer menu item.
class AgroDrawerItem {
  /// Unique key for navigation routing.
  final String key;

  /// Icon to display.
  final IconData icon;

  /// Title text (already localized).
  final String title;

  const AgroDrawerItem({
    required this.key,
    required this.icon,
    required this.title,
  });
}
