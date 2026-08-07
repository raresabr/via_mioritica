// lib/src/utils/app_strings.dart

// All user-facing strings in Romanian.
// When i18n is added later, replace this with ARB/gen_l10n — do not hardcode
// strings in widget files.
class S {
  // App
  static const appName = 'Via Mioritica';

  // Navigation
  static const navEtape = 'Etape';
  static const navHarta = 'Hartă';

  // Stage list
  static const stageTitleHint = 'Traseu';
  static const stageDistance = 'Distanță';
  static const stageGain = 'Urcare';
  static const stageLoss = 'Coborâre';
  static const stageDifficulty = 'Dificultate';
  static const stageDuration = 'Durata estimată';
  static const stageKm = 'km';
  static const stageM = 'm';

  // Detail
  static const sectionDescription = 'Descriere';
  static const sectionCazare = 'Cazare';
  static const sectionPopas = 'Popas';
  static const sectionObiective = 'Obiective turistice';
  static const sectionRecomandari = 'Recomandări';
  static const sectionElevation = 'Profil altitudinal';
  static const elevationAxisKm = 'km';
  static const elevationAxisM = 'm';
  static const noPois = 'Nu sunt puncte de interes pentru această categorie.';

  // Map
  static const mapFollowMe = 'Urmărire';
  static const mapLocationDenied =
      'Permisiunea de localizare a fost refuzată. '
      'Activați din Setări pentru a vedea poziția curentă.';
  static const mapOfflineNote =
      'Harta funcționează offline dacă zona a fost descărcată anterior.';

  // GPS
  static const permissionTitle = 'Localizare GPS';
  static const permissionBody =
      'Via Mioritica folosește GPS-ul pentru a afișa poziția ta pe hartă. '
      'Localizarea este folosită doar cât timp aplicația este deschisă.';

  // Errors
  static const errorLoad = 'Eroare la încărcarea datelor.';
  static const errorGpx = 'Traseul GPX nu a putut fi încărcat.';
  static const retry = 'Încearcă din nou';

  // Placeholder
  static const contentInProgress = 'Conținut în lucru — în curând.';

  // Home screen
  static const homeIntro =
      'Via Mioritica este un traseu de lungă distanță care '
      'traversează munții României, urmând coloana vertebrală a '
      'Carpaților. Inspirat de miorița, simbolul pastoral românesc, '
      'traseul conectează peisaje alpine, sate tradiționale și '
      'obiective naturale de o frumusețe rară.\n\n'
      'Parcurge etapele pe jos sau cu bicicleta gravel, descoperă '
      'cabane autentice și trăiește România dintr-o perspectivă unică.';
  static const homeButtonSegmente = 'Segmente traseu';
  static const homeTagline = 'Descoperă România pas cu pas';
}

