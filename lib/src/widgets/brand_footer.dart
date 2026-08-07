// lib/src/widgets/brand_footer.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

/// Reusable branding footer with a tappable link, shown on the "Despre Noi"
/// screen (Faza 10). Text/URL come from [AboutContentModel] so they stay
/// API-ready rather than hardcoded — only the fallback below is hardcoded,
/// used if content fails to load.
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
            const Icon(Icons.link, size: 14, color: AppColors.textMuted),
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
