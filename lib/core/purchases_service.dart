import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _rcAppleKey = 'appl_eKcZZfLlgnahqtlqmStzzaqJLYc';

/// RevenueCat's Google Play public key (starts `goog_`). Empty until the Play
/// products exist; until then Android has no store to buy from, so Pro is
/// simply on there rather than locked behind a purchase that can't happen.
const _rcGoogleKey = '';

/// The entitlement Pro unlocks (RevenueCat).
const kProEntitlement = 'ProteinGrid Pro';

String get _rcKey => Platform.isIOS ? _rcAppleKey : _rcGoogleKey;

/// Whether in-app purchases work on this platform.
bool get purchasesAvailable =>
    (Platform.isIOS || Platform.isAndroid) && _rcKey.isNotEmpty;

Future<void> initPurchases() async {
  if (!purchasesAvailable) return;
  await Purchases.setLogLevel(LogLevel.warn);
  await Purchases.configure(PurchasesConfiguration(_rcKey));
}

/// Whether this user has Pro. Updates by itself when a purchase or restore
/// completes, on this screen or any other.
final isProProvider = AsyncNotifierProvider<ProNotifier, bool>(ProNotifier.new);

class ProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    if (!purchasesAvailable) return true;
    void listener(CustomerInfo info) => state = AsyncData(_has(info));
    Purchases.addCustomerInfoUpdateListener(listener);
    ref.onDispose(() => Purchases.removeCustomerInfoUpdateListener(listener));
    try {
      return _has(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('RevenueCat error: $e');
      return false;
    }
  }

  static bool _has(CustomerInfo info) =>
      info.entitlements.active.containsKey(kProEntitlement);
}

/// Pro, or false while it's still being checked (never flashes Pro features
/// open and then shut).
final isProNowProvider = Provider<bool>(
  (ref) => ref.watch(isProProvider).valueOrNull ?? false,
);
