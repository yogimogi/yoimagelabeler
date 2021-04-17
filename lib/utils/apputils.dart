import "dart:io";

import 'package:intl/intl.dart';
import "package:path_provider/path_provider.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import 'package:image_editor/image_editor.dart';
import "package:flutter/services.dart" show rootBundle;
import 'package:intl/date_symbol_data_local.dart';

class DiagnosticMessage {
  int epochTime;
  String messageType;
  String title;
  String? message;
  DiagnosticMessage(this.title, this.message, this.messageType)
      : epochTime = DateTime(2020, 3, 1).millisecondsSinceEpoch;
}

class AppUtils {
  // We need to get locale specific messages possibly even before
  // MaterialApp and so the 'context' is created.
  // Package devicelocale gives a way to get locale without the 'context'.
  // {
  //    We do get below warning during build.
  //    Note: /Users/yogimogi/tools/flutter/flutter/.pub-cache/hosted/pub.dartlang.org/devicelocale-0.4.1/android/src/main/java/com/example/devicelocale/DevicelocalePlugin.java
  //    uses or overrides a deprecated API.Note: Recompile with -Xlint:deprecation for details.
  // }
  // We still use generated AppLocalizations class, but instead of
  // letting Flutter manage AppLocalizations.delegate.load(), we manage
  // it explicitly.
  // What it means is, instead of using say
  //      AppLocalizations.of(context)!.app_title, we use
  //      AppUtils.yoLocalizations.app_title
  // throughout the code
  // We just make call to setAppLocalization() initially and
  // when locale is explicitly changed through the UI
  static late Locale _locale;
  static Locale get appLocale => _locale;

  static late AppLocalizations yoLocalizations;
  static void setAppLocalization(Locale? l) async {
    // App only supports "de" and "en" as languages
    if (l == null) {
      _setLocale(Locale("en", "US"));
    } else {
      switch (l.languageCode) {
        case "de":
          _setLocale(Locale("de", l.countryCode));
          break;
        default:
          _setLocale(Locale("en", l.countryCode));
      }
    }
  }

  static void _setLocale(Locale l) async {
    _locale = l;
    yoLocalizations =
        await AppLocalizations.delegate.load(Locale(l.languageCode));
    await initializeDateFormatting(l.toString(), null);
  }

  static List<DiagnosticMessage> _logs = [];
  static List<DiagnosticMessage> get logMessages => _logs;
  static void logMessage(String title, String? message, String messageType) {
    _logs.insert(0, DiagnosticMessage(title, message, messageType));
  }

  static void logException(String title, String? message) {
    logMessage(title, message, "error");
  }

  // Should be called only you want to clean up everything
  // and start afresh. Needed only during development.
  static Future<void> deleteAppData() async {
    debugPrint("Deleting App files [ Database and Images ] ...");
    await AppUtils.deleteAppDirectories();
    debugPrint("Deleted App files.");
  }

  static String getLocaleInteger(int x) {
    var f = NumberFormat("###,###,###", "en_US");
    String r = f.format(x);
    String lang = appLocale.languageCode;
    if (lang == "de") {
      r = r.replaceAll(",", ".");
    }
    return r;
  }

  static String getLocaleDateTimeString(int millisecondsSinceEpoch) {
    // BuildContext context = appKey.currentContext!;
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    String lang = appLocale.languageCode;
    // String? country = Localizations.localeOf(context).countryCode;
    if (lang == "de") {
      // For some reason, even if "Deutsch (Deutschland)" is selected as
      // Language on the phone when the app starts, value of Intl.defaultLocale
      // is NULL and as a result month strings are returned in English
      // (for example: Mar instead of Mär, May instead of Mai etc.)
      Intl.defaultLocale = "de_DE";
      DateFormat df = DateFormat("dd-MMM-yyyy HH:mm:ss");
      return df.format(dt);
    } else if (lang == "en" &&
        appLocale.countryCode != null &&
        appLocale.countryCode!.toLowerCase() == "in") {
      Intl.defaultLocale = "en_IN";
      DateFormat df = DateFormat("dd-MMM-yyyy hh:mm:ss a");
      return df.format(dt);
    } else {
      DateFormat df = DateFormat("MMM-dd-yyyy hh:mm:ss a");
      return df.format(dt);
    }
  }

  static String _imgFileExtension = "jpg";
  static String get uniqueFileName =>
      "img_${DateTime.now().millisecondsSinceEpoch}.$_imgFileExtension";

  static String _dbDirectory = "db";
  static Future<String> get dbFile async {
    Directory? dir = await getExternalStorageDirectory();
    return dir!.path + "/$_dbDirectory/yo_labeler.db";
  }

  static Future<String> get dbDirectory async {
    Directory? dir = await getExternalStorageDirectory();
    return dir!.path + "/$_dbDirectory/";
  }

  static Future<bool> createImagesDirectory() async {
    String imDirPath = await imagesDirectory;
    Directory d = Directory(imDirPath);
    if (await d.exists()) {
      logMessage(yoLocalizations.images_dir_exists(imDirPath), "", "info");
      return false;
    } else {
      await d.create();
      logMessage(yoLocalizations.images_dir_created(imDirPath), "", "info");
      return true;
    }
  }

  static Future<Directory> deleteNCreateDirectory(String path) async {
    Directory d = Directory(path);
    if (await d.exists()) {
      await d.delete(recursive: true);
      await d.create();
    } else {
      await d.create();
    }
    return d;
  }

  static Future<Directory> createDownloadDirectory(String n) async {
    // Possibly Android specific Implementation
    String ddPath = "/storage/emulated/0/$n";
    Directory d = Directory(ddPath);
    if (!await d.exists()) {
      await d.create();
    }
    return d;
  }

  static final List<String> pigeonImages = [
    "pigeon0.jpg",
    "pigeon1.jpg",
    "pigeon2.jpg",
  ];
  static final List<String> nonPigeonImages = [
    "not-pigeon0.jpg",
    "not-pigeon1.jpg",
    "not-pigeon2.jpg",
  ];

  static Future<void> copySampleImages() async {
    await _copySampleImages(pigeonImages);
    await _copySampleImages(nonPigeonImages);
  }

  static Future<void> _copySampleImages(images) async {
    String imDirPath = await imagesDirectory;
    for (int i = 0; i < images.length; ++i) {
      var imageData = await rootBundle.load("assets/" + images[i]);
      var bytes = imageData.buffer.asUint8List();
      await File(imDirPath + "/" + images[i]).writeAsBytes(bytes);
    }
  }

  static String _imagesDirectory = "images";
  static Future<String> get imagesDirectory async {
    Directory? dir = await getExternalStorageDirectory();
    return dir!.path + "/$_imagesDirectory";
  }

  static Future<void> deleteAppDirectories() async {
    Directory dbDir = Directory(await dbDirectory);
    if (dbDir.existsSync()) {
      await dbDir.delete(recursive: true);
    }
    Directory imagesDir = Directory(await imagesDirectory);
    if (imagesDir.existsSync()) {
      await imagesDir.delete(recursive: true);
    }
  }

  static Future<int> fileSize(String path) async {
    try {
      File f = File(path);
      return await f.length();
    } on Exception catch (e) {
      logException(
          AppUtils.yoLocalizations.error_file_size(path), e.toString());
      return -1;
    }
  }

  static Future<File> clipImage(File originalImage) async {
    // We are initializing CameraController with ResolutionPreset.high.
    // This preset captures images with 1280x720 resolution.
    // Image captured also has 'Exif Image Orientation' tag which is
    // always 'Rotated 90 CW' as Flutter CameraController assumes
    // Portrait as Phone orientation which is as good as Camera being
    // rotated 90 degrees clockwise
    final int presetHIGHWidth = 1280;
    final int presetHIGHHeight = 720;

    // ImageEditor.editFileImage not only clips/crops the
    // image, it also removes all Exif tags from the image
    // So that there is no orientation issue in the save images
    // Libray honors though the 'Rotated 90 CW' flag before
    // applying the clip operation and hence image actually
    // gets treated as 720x1280 and that's why we crop square
    // of size 720 along the new height at the center
    final editorOption = ImageEditorOption();
    editorOption.addOption(ClipOption(
        x: 0,
        y: presetHIGHWidth / 2 - presetHIGHHeight / 2,
        width: presetHIGHHeight,
        height: presetHIGHHeight));
    var bytes = await ImageEditor.editFileImage(
        file: originalImage, imageEditorOption: editorOption);

    String fileName = AppUtils.uniqueFileName;
    String newImagePath = await AppUtils.imagesDirectory + "/" + fileName;
    return File(newImagePath).writeAsBytes(bytes!);
  }

  static Future<int> imageFileSize(String fileName) async {
    String imageFilePath = await imagesDirectory + "/" + fileName;
    return fileSize(imageFilePath);
  }

  static Future<int> _directorySize(String path) async {
    Directory? d = Directory(path);
    bool dExists = await d.exists();
    if (dExists) {
      int size = 0;
      await d.list().forEach((FileSystemEntity f) async {
        if (f is File) {
          size = size + await f.length();
        }
      });
      return size;
    } else {
      return 0;
    }
  }

  static Future<int> get imagesSize async {
    return _directorySize(await AppUtils.imagesDirectory);
  }

  static Future<int> get dbSize async {
    return _directorySize(await AppUtils.dbDirectory);
  }

  static void showInSnackBar(BuildContext context, String m,
      {bool info = true, Widget? screen, int duration: 1}) {
    TextStyle? headlineStyle = Theme.of(context).textTheme.headline6;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: info ? Colors.green.shade400 : Colors.black87,
        duration: info ? Duration(seconds: duration) : Duration(seconds: 5),
        action: screen == null
            ? null
            : SnackBarAction(
                label: AppUtils.yoLocalizations.details,
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => screen));
                }),
        content: Text(m,
            style: TextStyle(
                color: Colors.white, fontSize: headlineStyle!.fontSize))));
  }
}
