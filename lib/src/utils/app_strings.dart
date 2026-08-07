// lib/src/utils/app_strings.dart

// All user-facing strings in Romanian.
// When i18n is added later, replace this with ARB/gen_l10n — do not hardcode
// strings in widget files.
class S {
  // App
  static const appName = 'Via Mioritica';

  // Navigation (5-tab bottom nav, Faza 8)
  static const navDespreNoi = 'Despre Noi';
  static const navHartaTraseu = 'Hartă traseu';
  static const navRecomandari = 'Recomandări';
  static const navGhid = 'Ghidul Călătorului';
  static const navAlbum = 'Album foto';

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
  static const noPois = 'Nu sunt puncte de interes pentru această categorie.';

  // Map
  static const mapFollowMe = 'Urmărire';
  static const mapLocationDenied =
      'Permisiunea de localizare a fost refuzată. '
      'Activați din Setări pentru a vedea poziția curentă.';
  static const mapOfflineNote =
      'Harta funcționează offline dacă zona a fost descărcată anterior.';

  // Offline map download
  static const offlineSectionTitle = 'Hartă offline';
  static const offlineNotDownloaded =
      'Traseul nu este descărcat pentru offline.';
  static const offlineEstimating = 'Se calculează dimensiunea descărcării…';
  static const offlineDownloading = 'Se descarcă harta offline…';
  static const offlinePaused = 'Descărcare pauzată.';
  static const offlineComplete = 'Hartă disponibilă offline.';
  static const offlineError = 'Eroare la descărcarea hărții offline.';
  static const offlineDownloadButton = 'Descarcă pentru offline';
  static const offlinePauseButton = 'Pauză';
  static const offlineResumeButton = 'Reia';
  static const offlineCancelButton = 'Anulează';
  static const offlineDeleteButton = 'Șterge harta offline';
  static const offlineRetryButton = 'Încearcă din nou';

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

  // Despre Noi
  static const aboutFooterFallback = 'stag-line.com';

  // Recomandări practice
  static const recommendationsTitle = 'Recomandări practice';
  static const recommendationsEmpty = 'Nu sunt recomandări disponibile.';

  // Album foto
  static const albumTitle = 'Album foto';
  static const albumEmpty =
      'Nu sunt poze disponibile încă — vor fi adăugate curând.';
  static const albumFilterAll = 'Toate etapele';

  // Hartă traseu (full route map)
  static const fullMapTitle = 'Hartă traseu';
  static const fullMapLegendTitle = 'Etape';

  // Force update (Faza 14 — Remote Config)
  static const forceUpdateTitle = 'Actualizare necesară';
  static const forceUpdateButton = 'Actualizează acum';
  static const forceUpdateStoreError =
      'Nu s-a putut deschide magazinul de aplicații.';

  // Progress tracking (Faza 15 — local, no account)
  static const progressMarkCompleted = 'Marchează etapa ca finalizată';
  static const progressCompletedLabel = 'Etapă finalizată';
  static const progressSummary = 'etape finalizate';
}

