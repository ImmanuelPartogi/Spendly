import 'package:flutter/services.dart';

/// Centralized haptic feedback helper.
/// Usage:
///   await HapticUtils.success();   // setelah save berhasil
///   await HapticUtils.error();     // setelah error
///   HapticUtils.selection();       // saat tap category / chip
class HapticUtils {
  HapticUtils._();

  /// Ringan — untuk tap biasa
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Sedang — untuk aksi penting
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Kuat — untuk konfirmasi penghapusan
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Notifikasi sukses
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Notifikasi error
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// Notifikasi warning
  static Future<void> warning() => HapticFeedback.mediumImpact();

  /// Tap ringan saat pilih item (category, chip, dll.)
  static Future<void> selection() => HapticFeedback.selectionClick();
}