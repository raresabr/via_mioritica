// lib/src/widgets/brand_footer.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

/// Reusable branding footer with a tappable link, shown on the "Despre Noi"
/// screen (Faza 10) and the privacy policy screen. Text/URL come from
/// [AboutContentModel] so they stay API-ready rather than hardcoded — only
/// the fallback in [AboutScreen]/[PrivacyPolicyScreen] is hardcoded, used
/// if content fails to load.
class BrandFooter extends StatelessWidget {
  final String text;
  final String url;

  const BrandFooter({
    super.key,
    required this.text,
    required this.url,
  });

  Future<void> _openLink() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UI/UX polish: Stagline deer-head logo — enlarged (was
            // 16x16, hard to see) and rendered fully black. The source
            // SVG has a broken `fill="#"` on every path (invalid hex),
            // so a fixed `colorFilter` is applied to override it — this
            // ignores the embedded (broken) fill entirely and guarantees
            // a consistent brand color regardless. Stacked as its own
            // row above the text (rather than side-by-side) so the logo
            // can be large without cramping the text on one line.
            SvgPicture.asset(
              'assets/images/stagline-logo.svg',
              width: 48,
              height: 48,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
