// lib/src/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_theme.dart';
import '../widgets/brand_footer.dart';

/// Faza 18 — privacy policy screen.
///
/// Static text, hardcoded in-app (not fetched from the hosted JSON, unlike
/// the rest of the "Despre Noi" content — a legal document shouldn't change
/// silently via a background cache revalidation without an app update/
/// review, unlike marketing copy). Reachable from [AboutScreen].
///
/// Written to accurately describe what the app *actually* does as of Faza
/// 16 (Crashlytics + Analytics): no account/login (Faza 15), no PII
/// collected, GPS used only live on-device (never transmitted/stored),
/// crash reports + anonymous usage events sent to Firebase (Google) with
/// no personal identifiers, and everything else (progress, cache, offline
/// maps) stored only locally on the device.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(S.privacyPolicyTitle),
        titleTextStyle: displayStyle(22),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Section(
              title: 'Fără cont, fără date personale',
              body:
                  'Via Mioritica nu necesită crearea unui cont și nu îți '
                  'solicită nume, e-mail sau alte date de identificare '
                  'personală pentru a fi folosită. Progresul tău pe trasee '
                  '(etape marcate ca finalizate) este stocat exclusiv local, '
                  'pe telefonul tău, și nu este transmis nicăieri.',
            ),
            _Section(
              title: 'Localizare GPS',
              body:
                  'Aplicația folosește GPS-ul doar pentru a-ți afișa poziția '
                  'curentă ("punctul albastru") pe hartă, cât timp aplicația '
                  'este deschisă și doar dacă permiți accesul la localizare. '
                  'Poziția ta nu este stocată, salvată în istoric sau '
                  'transmisă către niciun server.',
            ),
            _Section(
              title: 'Rapoarte de eroare (Firebase Crashlytics)',
              body:
                  'Dacă aplicația întâmpină o eroare neașteptată, un raport '
                  'tehnic (mesajul erorii, modelul telefonului, versiunea de '
                  'sistem de operare și versiunea aplicației) este trimis '
                  'automat către Firebase Crashlytics (serviciu Google), '
                  'pentru a ne ajuta să identificăm și să reparăm '
                  'problemele. Aceste rapoarte nu conțin nume, e-mail sau '
                  'alte date personale — sunt asociate unui identificator '
                  'tehnic anonim generat de dispozitiv, nu de o persoană.',
            ),
            _Section(
              title: 'Statistici de utilizare anonime (Firebase Analytics)',
              body:
                  'Colectăm evenimente de utilizare anonime și agregate — '
                  'de exemplu, ce ecrane sunt vizitate sau dacă o etapă a '
                  'fost marcată ca finalizată — pentru a înțelege cum este '
                  'folosită aplicația și a o îmbunătăți. Aceste evenimente '
                  'nu includ nume, e-mail, poziție GPS sau orice altă '
                  'informație care te-ar putea identifica direct.',
            ),
            _Section(
              title: 'Conținut și hărți offline',
              body:
                  'Conținutul traseelor (descrieri, recomandări, fotografii) '
                  'și hărțile offline pe care le descarci sunt stocate '
                  'exclusiv local, pe telefonul tău, pentru a permite '
                  'folosirea aplicației fără conexiune la internet. Poți '
                  'șterge oricând aceste date descărcate din secțiunea '
                  'hărții offline a fiecărei etape.',
            ),
            _Section(
              title: 'Servicii terțe folosite',
              body:
                  '• Firebase (Google) — Crashlytics, Analytics și Remote '
                  'Config (verificare versiune aplicație).\n'
                  '• MapTiler — furnizor de hărți (tile-uri), folosit pentru '
                  'afișarea hărților în aplicație.\n\n'
                  'Aceste servicii pot procesa adrese IP tehnice ca parte a '
                  'funcționării standard a internetului, dar aplicația nu le '
                  'transmite nume, e-mail sau alte date de identificare '
                  'directă introduse de tine.',
            ),
            _Section(
              title: 'Contact',
              body:
                  'Pentru întrebări legate de confidențialitate sau despre '
                  'acest proiect, ne poți contacta prin site-ul Stagline '
                  '(stag-line.com).',
            ),
            SizedBox(height: 8),
            BrandFooter(
              text: S.aboutFooterFallback,
              url: 'https://stag-line.com/',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.earth.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: displayStyle(19, height: 1.2)),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
