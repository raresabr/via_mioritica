// lib/src/widgets/brand_footer.dart
import 'dart:ui';
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

  const BrandFooter({super.key, required this.text, required this.url});

  Future<void> _openLink() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openLink,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.6),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.night,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    'assets/images/stagline-logo.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      AppColors.night,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
