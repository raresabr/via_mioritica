// lib/src/models/about_content_model.dart

/// Content for the "Despre Noi" tab (Faza 8.4) — intro text plus the
/// branding footer link (Faza 10), modeled API-ready.
class AboutContentModel {
  final String title;
  final String body;
  final String footerText;
  final String footerUrl;

  const AboutContentModel({
    required this.title,
    required this.body,
    required this.footerText,
    required this.footerUrl,
  });

  factory AboutContentModel.fromJson(Map<String, dynamic> json) {
    return AboutContentModel(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      footerText: json['footerText'] as String? ?? '',
      footerUrl: json['footerUrl'] as String? ?? '',
    );
  }
}
