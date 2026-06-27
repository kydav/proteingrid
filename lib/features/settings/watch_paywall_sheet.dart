import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proteingrid/core/theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> showWatchPaywallSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      // borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    builder: (_) => const _WatchPaywallSheet(),
  );
}

class _WatchPaywallSheet extends StatefulWidget {
  const _WatchPaywallSheet();

  @override
  State<_WatchPaywallSheet> createState() => _WatchPaywallSheetState();
}

class _WatchPaywallSheetState extends State<_WatchPaywallSheet> {
  Package? _package;
  bool _loadingPackage = true;
  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.firstOrNull;
      if (mounted) {
        setState(() {
          _package = pkg;
          _loadingPackage = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading offerings: $e');
      if (mounted) setState(() => _loadingPackage = false);
    }
  }

  Future<void> _purchase() async {
    if (_purchasing) return;
    if (_package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not available yet — check back soon.'),
        ),
      );
      return;
    }
    setState(() => _purchasing = true);
    try {
      await Purchases.purchasePackage(_package!);
      await HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pop(true);
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      final info = await Purchases.restorePurchases();
      if (mounted) {
        if (info.entitlements.active.containsKey('protein_grid_pro')) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Watch purchase found to restore.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: kArcadeSurface,
        border: Border(
          top: BorderSide(color: kNeonGreen.withValues(alpha: 0.5), width: 1.5),
          left: BorderSide(color: kNeonGreen.withValues(alpha: 0.2)),
          right: BorderSide(color: kNeonGreen.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: kNeonGreen.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNeonGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Watch icon
              _GlowingWatchIcon(), // ignore: prefer_const_constructors

              const SizedBox(height: 20),

              // Headline
              Text(
                'WATCH APP',
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: kNeonGreen,
                  shadows: neonGlow(kNeonGreen, intensity: 0.9)
                      .map(
                        (s) => Shadow(color: s.color, blurRadius: s.blurRadius),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track protein from your wrist',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 24),

              // Feature list
              ..._features.map((f) => _FeatureRow(text: f)),

              const SizedBox(height: 24),

              // Price
              _PriceChip(package: _package, loading: _loadingPackage),

              const SizedBox(height: 20),

              // Unlock button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _purchasing ? null : _purchase,
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: kNeonGreen,
                        foregroundColor: kArcadeBg,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        elevation: 0,
                      ).copyWith(
                        shadowColor: WidgetStateProperty.all(kNeonGreen),
                        elevation: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.pressed) ? 0 : 0,
                        ),
                      ),
                  child: _purchasing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kArcadeBg,
                          ),
                        )
                      : Text(
                          'UNLOCK WATCH',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: kArcadeBg,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Restore
              TextButton(
                onPressed: _restoring ? null : _restore,
                child: _restoring
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore Purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _features = [
  'Quick-log 30g, 40g, 50g from your wrist',
  'Progress ring synced in real time',
  'Streak counter always on display',
  'Logs queue offline and sync when nearby',
];

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: kNeonGreen, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: const Color(0xFF00CC10),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.package, required this.loading});
  final Package? package;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final label = loading
        ? 'Loading…'
        : (package?.storeProduct.priceString ?? 'Coming Soon');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kNeonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kNeonGreen.withValues(alpha: 0.4)),
        boxShadow: neonGlow(kNeonGreen, intensity: 0.1),
      ),
      child: Text(
        label,
        style: GoogleFonts.pressStart2p(fontSize: 12, color: kNeonGreen),
      ),
    );
  }
}

class _GlowingWatchIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: kNeonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: kNeonGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: neonGlow(kNeonGreen, intensity: 0.35),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(44, 44), painter: _WatchFacePainter()),
        ],
      ),
    );
  }
}

class _WatchFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..color = kNeonGreen.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Watch case outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: c, radius: r),
        const Radius.circular(6),
      ),
      paint,
    );

    // Progress arc (~75%)
    final arcPaint = Paint()
      ..color = kNeonGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 6),
      -math.pi / 2,
      2 * math.pi * 0.75,
      false,
      arcPaint,
    );

    // Center dot
    canvas.drawCircle(c, 2, Paint()..color = kNeonGreen);
  }

  @override
  bool shouldRepaint(_) => false;
}
