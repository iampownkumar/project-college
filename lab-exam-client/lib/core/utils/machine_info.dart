// ============================================================
// File: lib/core/utils/machine_info.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-15
// Location: Tamil Nadu, India
// Description: Utility to read the local machine hostname and
//              first non-loopback IPv4 address for auth + heartbeat.
// ============================================================

import 'dart:io';

class MachineInfo {
  MachineInfo._();

  static String get machineName {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown-host';
    }
  }

  /// Returns the first non-loopback IPv4 address found.
  static Future<String> getMachineIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
