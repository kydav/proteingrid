import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _rcApiKey = 'appl_eKcZZfLlgnahqtlqmStzzaqJLYc';

const _watchEntitlement = 'ProteinGrid Pro';

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
