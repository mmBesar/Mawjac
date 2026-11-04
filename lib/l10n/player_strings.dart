import 'strings.dart';

/// Strings for the in-window player, its set-top-box panels and track choices.
extension PlayerStrings on AppStrings {
  String get aspectLabel => isArabic ? 'نسبة العرض' : 'Aspect ratio';
  String aspectName(int mode) {
    switch (mode) {
      case 1:
        return '16:9';
      case 2:
        return '4:3';
      case 3:
        return '21:9';
      case 4:
        return isArabic ? 'تكبير لملء الشاشة' : 'Zoom to fill';
      default:
        return isArabic ? 'تلقائي' : 'Auto';
    }
  }

  String get deinterlaceLabel => isArabic ? 'إزالة التداخل' : 'Deinterlace';
  String get aspectTooltip => isArabic ? 'نسبة العرض (Z)' : 'Aspect ratio (Z)';
  String get audioAndSubtitles => isArabic ? 'الصوت والترجمة' : 'Audio & subtitles';
  String get audioDelayLabel => isArabic ? 'تأخير الصوت' : 'Audio delay';
  String get audioLabel => isArabic ? 'الصوت' : 'Audio';
  String get audioTracks => isArabic ? 'المسارات الصوتية' : 'Audio';
  String get channelListTooltip => isArabic ? 'قائمة القنوات (C)' : 'Channel list (C)';
  String get channelWord => isArabic ? 'القناة' : 'Channel';
  String get helpTooltip => isArabic ? 'الاختصارات (H)' : 'Shortcuts (H)';
  String get inAppRenderer => isArabic ? 'عرض الفيديو داخل التطبيق' : 'In-app video rendering';
  String get inAppRendererHelp => isArabic
      ? 'إن تجمّدت النافذة أثناء التشغيل اختر CPU. يُطبَّق عند فتح القناة التالية.'
      : 'If the window freezes while playing, choose CPU. Applies the next time you open a channel.';
  String get infoDropped => isArabic ? 'إطارات مفقودة' : 'Dropped';
  String get infoTooltip => isArabic ? 'معلومات القناة (I)' : 'Channel info (I)';
  String noChannelNumber(String number) =>
      isArabic ? 'لا توجد قناة برقم $number' : 'No channel $number';
  String get noOtherTracks => isArabic ? 'لا يوجد مسار آخر' : 'No other track';
  String get noTracks => isArabic ? 'لا توجد مسارات في هذا البث.' : 'This stream has none.';
  String get offWord => isArabic ? 'إيقاف' : 'Off';
  String get onWord => isArabic ? 'تشغيل' : 'On';
  String get preferredAudio => isArabic ? 'لغة الصوت المفضلة' : 'Preferred audio language';
  String get preferredSubtitle =>
      isArabic ? 'لغة الترجمة المفضلة' : 'Preferred subtitle language';
  String get rememberTracks =>
      isArabic ? 'تذكّر المسارات لكل قناة' : 'Remember tracks per channel';
  String get rememberTracksHelp => isArabic
      ? 'يستعيد آخر صوت وترجمة اخترتهما على كل قناة.'
      : 'Brings back the audio and subtitle you last picked on each channel.';
  String get rendererAuto => isArabic ? 'تلقائي (GPU)' : 'Automatic (GPU)';
  String get rendererCpu => isArabic ? 'CPU (الأكثر أمانًا)' : 'CPU (safest)';
  String get rendererGpu => isArabic ? 'GPU (الأسلس)' : 'GPU (smoothest)';
  String get server => isArabic ? 'الخادم' : 'Server';
  String get stbAll => isArabic ? 'الكل' : 'All';
  String get stbBrowserHint => isArabic
      ? '↑↓ اختيار · Enter مشاهدة · ←→ تغيير المجموعة · اكتب للبحث · Esc إغلاق'
      : '↑↓ select · Enter watch · ←→ change tag · type to search · Esc close';
  String get stbChannels => isArabic ? 'القنوات' : 'Channels';
  String get stbFavorites => isArabic ? 'المفضلة' : 'Favourites';
  String get stbHelpTitle => isArabic ? 'اختصارات لوحة المفاتيح' : 'Keyboard shortcuts';
  String get stbNoMatch => isArabic ? 'لا توجد قنوات مطابقة' : 'No matching channels';
  String get stbSearch => isArabic ? 'اكتب للبحث بالاسم أو الرقم' : 'Type to search by name or number';
  String get streamDefault => isArabic ? 'افتراضي البث' : 'Stream default';
  String get subtitleLabel => isArabic ? 'الترجمة' : 'Subtitles';
  String get subtitleTracks => isArabic ? 'الترجمة' : 'Subtitles';
  String get subtitlesOff => isArabic ? 'بدون ترجمة' : 'Off';
  String get subtitlesOffByDefault =>
      isArabic ? 'بدون ترجمة (افتراضي)' : 'Off by default';
  String trackNumber(int n) => isArabic ? 'مسار $n' : 'Track $n';
  String get tracksHelp => isArabic
      ? 'تظهر الأسماء من لغة المسار في البث. ترجمة DVB تُعرض بينما ترجمة التلتكست غير مدعومة بعد.'
      : 'Names come from the language each track declares. DVB subtitles are shown; teletext subtitles are not supported yet.';
  String get zapBanner => isArabic ? 'شريط القناة عند الفتح' : 'Channel banner on open';
  String get zapBannerHelp => isArabic
      ? 'يعرض شريطًا بمعلومات القناة والبرنامج عند فتح قناة (سطح المكتب). اضغط I لإظهاره أو إخفائه.'
      : 'Shows a banner with the channel and programme when one opens (desktop). Press I to pin or hide it.';

  /// Key / action pairs for the shortcuts sheet. Keys are space separated.
  List<(String, String)> get shortcutHelp => isArabic
      ? const <(String, String)>[
          ('C Enter', 'قائمة القنوات والمجموعات'),
          ('↑ ↓ PgUp PgDn', 'القناة التالية / السابقة'),
          ('0-9', 'اكتب رقم القناة (ثم Enter)'),
          ('← → + −', 'مستوى الصوت (وعجلة الفأرة)'),
          ('M', 'كتم الصوت'),
          ('Space', 'إيقاف مؤقت / تشغيل'),
          ('F F11 Esc', 'ملء الشاشة / خروج'),
          ('I', 'شريط معلومات القناة'),
          ('S', 'قائمة الصوت والترجمة'),
          ('A', 'المسار الصوتي التالي'),
          ('J', 'الترجمة التالية'),
          ('[ ]', 'تأخير الصوت −/+ 50ms'),
          ('Z', 'تغيير نسبة العرض'),
          ('T', 'إزالة التداخل'),
          ('D', 'التشخيص'),
          ('H F1', 'هذه القائمة'),
        ]
      : const <(String, String)>[
          ('C Enter', 'Channel list and tags'),
          ('↑ ↓ PgUp PgDn', 'Next / previous channel'),
          ('0-9', 'Type a channel number (then Enter)'),
          ('← → + −', 'Volume (and the mouse wheel)'),
          ('M', 'Mute'),
          ('Space', 'Pause / play'),
          ('F F11 Esc', 'Full screen / leave'),
          ('I', 'Channel info banner'),
          ('S', 'Audio & subtitles menu'),
          ('A', 'Next audio track'),
          ('J', 'Next subtitle'),
          ('[ ]', 'Audio delay −/+ 50 ms'),
          ('Z', 'Cycle aspect ratio'),
          ('T', 'Deinterlace'),
          ('D', 'Diagnostics'),
          ('H F1', 'This sheet'),
        ];
}
