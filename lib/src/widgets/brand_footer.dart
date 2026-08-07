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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UI/UX polish: Stagline deer-head logo instead of a generic
            // link icon. The source SVG has a broken `fill="#"` on every
            // path (invalid hex), so a fixed `colorFilter` is applied to
            // override it — this ignores the embedded (broken) fill
            // entirely and guarantees a consistent brand color regardless.
            SvgPicture.asset(
              'assets/images/stagline-logo.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                AppColors.textMuted,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
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
