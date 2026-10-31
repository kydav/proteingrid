import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proteingrid/core/purchases_service.dart';
import 'package:proteingrid/core/theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Why the paywall opened. Shown as its headline, so it answers the tap that
/// led here ("See your whole year") rather than a generic pitch.
enum ProReason {
  grid('See your whole year', 'Every day you hit your goal, on one grid.'),
  history('Go back further', 'Your full history, every day you logged.'),
  presets('Make the buttons yours', 'Your own one-tap amounts and names.'),
  reminders('More reminders', 'Nudges through the day, not just one.'),
  general('ProteinGrid Pro', 'Everything, for as long as you use it.');

  const ProReason(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Opens the Pro paywall. True if they now have Pro.
Future<bool> showProPaywall(
  BuildContext context, {
  ProReason reason = ProReason.general,
}) async {
  if (!purchasesAvailable) return true;
  final bought = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProPaywallSheet(reason: reason),
  );
  return bought ?? false;
}

/// Opens the paywall unless they already have Pro. True if they have it
/// (already, or now). The one-line gate for every Pro feature.
Future<bool> requirePro(
  BuildContext context,
  WidgetRef ref, {
  required ProReason reason,
}) async {
  if (ref.read(isProNowProvider)) return true;
  return showProPaywall(context, reason: reason);
}

const _features = [
  'THE GRID: your whole year at a glance',
  'Full history, every day you have logged',
  'Your own quick-log buttons',
  'Up to 3 daily reminders',
  'Support a tiny indie app',
];

const _termsUrl = 'https://auaha.app/proteingrid/terms';
const _privacyUrl = 'https://auaha.app/proteingrid/privacy';

class _ProPaywallSheet extends ConsumerStatefulWidget {
  const _ProPaywallSheet({required this.reason});

  final ProReason reason;

  @override
  ConsumerState<_ProPaywallSheet> createState() => _ProPaywallSheetState();
}

class _ProPaywallSheetState extends ConsumerState<_ProPaywallSheet> {
  List<Package> _packages = const [];
  Package? _selected;
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  /// Packages from RevenueCat's current offering, best value first: yearly,
  /// lifetime, then monthly. Whatever is configured there is what shows.
  Future<void> _loadOffering() async {
    try {
      final offering = (await Purchases.getOfferings()).current;
      const order = [
        PackageType.annual,
        PackageType.lifetime,
        PackageType.monthly,
      ];
      final pkgs = [...?offering?.availablePackages]
        ..sort((a, b) {
          int rank(Package p) {
            final i = order.indexOf(p.packageType);
            return i < 0 ? order.length : i;
          }

          return rank(a).compareTo(rank(b));
        });
      if (!mounted) return;
      setState(() {
        _packages = pkgs;
        _selected = pkgs.firstOrNull;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading offerings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = "Couldn't reach the store. Check your connection.";
        });
      }
    }
  }

  Future<void> _purchase() async {
    final pkg = _selected;
    if (_purchasing || pkg == null) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final info = await Purchases.purchasePackage(pkg);
      if (info.entitlements.active.containsKey(kProEntitlement)) {
        await HapticFeedback.heavyImpact();
        if (mounted) Navigator.of(context).pop(true);
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        setState(() => _error = e.message ?? 'Purchase failed.');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      final info = await Purchases.restorePurchases();
      if (!mounted) return;
      if (info.entitlements.active.containsKey(kProEntitlement)) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'No earlier purchase found.');
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Restore failed.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final glow = neonGlow(
      kNeonGreen,
      intensity: 0.9,
    ).map((s) => Shadow(color: s.color, blurRadius: s.blurRadius)).toList();
    final selected = _selected;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNeonGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const _MiniGrid(),
              const SizedBox(height: 18),
              Text(
                widget.reason.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 13,
                  height: 1.5,
                  color: kNeonGreen,
                  shadows: glow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.reason.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              ..._features.map((f) => _FeatureRow(text: f)),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: kNeonGreen),
                )
              else
                for (final p in _packages)
                  _PackageTile(
                    package: p,
                    selected: identical(p, selected),
                    onTap: () => setState(() => _selected = p),
                  ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _purchasing || selected == null ? null : _purchase,
                  style: FilledButton.styleFrom(
                    backgroundColor: kNeonGreen,
                    foregroundColor: kArcadeBg,
                    disabledBackgroundColor: kNeonGreen.withValues(alpha: 0.3),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
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
                          selected == null ? 'UNAVAILABLE' : _cta(selected),
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: kArcadeBg,
                          ),
                        ),
                ),
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                Text(
                  _terms(selected),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _restoring ? null : _restore,
                    child: Text(_restoring ? 'Restoring…' : 'Restore'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(_termsUrl)),
                    child: const Text('Terms'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(_privacyUrl)),
                    child: const Text('Privacy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasTrial(Package p) =>
      p.storeProduct.introductoryPrice?.price == 0;

  static String _cta(Package p) => switch (p.packageType) {
    _ when _hasTrial(p) => 'START FREE TRIAL',
    PackageType.lifetime => 'UNLOCK FOREVER',
    _ => 'UNLOCK PRO',
  };

  /// The renewal terms Apple and Google want next to a subscription button.
  static String _terms(Package p) {
    final price = p.storeProduct.priceString;
    final intro = p.storeProduct.introductoryPrice;
    return switch (p.packageType) {
      PackageType.lifetime => 'One-time purchase of $price. No subscription.',
      PackageType.annual when intro?.price == 0 =>
        '${intro!.periodNumberOfUnits}-'
            '${intro.periodUnit.name.toLowerCase()} free trial, then '
            '$price/year. Cancel anytime.',
      PackageType.annual => '$price/year. Renews until cancelled.',
      PackageType.monthly => '$price/month. Renews until cancelled.',
      _ => price,
    };
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = package.storeProduct;
    final (name, note) = switch (package.packageType) {
      PackageType.annual => (
        'Yearly',
        p.introductoryPrice?.price == 0
            ? 'Free trial · best value'
            : 'Best value',
      ),
      PackageType.lifetime => ('Lifetime', 'Pay once'),
      PackageType.monthly => ('Monthly', ''),
      _ => (p.title, ''),
    };
    final color = selected ? kNeonGreen : kNeonGreen.withValues(alpha: 0.35);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kNeonGreen.withValues(alpha: selected ? 0.1 : 0.03),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: selected ? 1.5 : 1),
            boxShadow: selected ? neonGlow(kNeonGreen, intensity: 0.15) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kNeonGreen,
                      ),
                    ),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: GoogleFonts.orbitron(
                          fontSize: 9,
                          color: const Color(0xFF00CC10),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                p.priceString,
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: kNeonGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// A little lit-up grid: the product, as the paywall's icon.
class _MiniGrid extends StatelessWidget {
  const _MiniGrid();

  static const _pattern = [
    [1, 1, 0, 1, 1, 1, 1],
    [0, 1, 1, 1, 0, 1, 1],
    [1, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 1],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _pattern)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final on in row)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: on == 1
                        ? kNeonGreen
                        : kNeonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: on == 1
                        ? neonGlow(kNeonGreen, intensity: 0.3)
                        : null,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
