import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// TODO: replace with your RevenueCat API key from the dashboard
const _rcApiKey = 'appl_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

const _watchEntitlement = 'watch_access';

Future<void> initPurchases() async {
  if (!Platform.isIOS) return;
  await Purchases.setLogLevel(LogLevel.warn);
  await Purchases.configure(PurchasesConfiguration(_rcApiKey));
}

final watchUnlockedProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isIOS) return false;
  try {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(_watchEntitlement);
  } catch (e) {
    debugPrint('RevenueCat error: $e');
    return false;
  }
});
