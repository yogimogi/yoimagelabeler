import "package:flutter/material.dart";
import "package:camera/camera.dart";

import "package:yo_image_labeler/utils/globals.dart" as globals;

import "package:yo_image_labeler/screens/images.dart";
import "package:yo_image_labeler/utils/apputils.dart";
import 'package:yo_image_labeler/utils/dbutils.dart';

import 'package:devicelocale/devicelocale.dart';

List<CameraDescription> _cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Locale? deviceLocale = await Devicelocale.currentAsLocale;
  AppUtils.setAppLocalization(deviceLocale);
  try {
    await AppUtils.deleteAppData();
    bool dirCreated = await AppUtils.createImagesDirectory();
    if (dirCreated) AppUtils.copySampleImages();
    // When app runs the first time, below call ends up creating the
    // db and adding sample data, does othing otherwise.
    DatabaseHelper();
    _cameras = await availableCameras();
    globals.firstCamera = _cameras.first;

    int cct = _cameras.length;
    // MaterialApp and hence the 'context' is still not available.
    // Can't use 'context' based localization approach to localize
    // below strings as is done in rest of the application.
    if (cct == 0) {
      AppUtils.logMessage(AppUtils.yoLocalizations.camera,
          AppUtils.yoLocalizations.no_cameras_found, "error");
    } else {
      AppUtils.logMessage(
          AppUtils.yoLocalizations.camera,
          AppUtils.yoLocalizations
              .cameras_found(cct, globals.firstCamera.toString()),
          "info");
    }
  } on CameraException catch (ce) {
    AppUtils.logException(ce.code, ce.description);
    globals.cameraAvailable = false;
  } on Exception catch (e) {
    // In the plans; at the moment Camera support for Chrome in not available.
    // If you run this program with 'Chrome (web-javascript)' as the device, you
    // will get MissingPluginException as runtimeType and
    // No implementation found for method availableCameras on
    // channel plugins.flutter.io/camera
    AppUtils.logException(e.runtimeType.toString(), e.toString());
    globals.cameraAvailable = false;
  } on Error catch (e) {
    AppUtils.logException(e.runtimeType.toString(), e.toString());
    globals.cameraAvailable = false;
  }
  runApp(YoImageLabeler());
}

class YoImageLabeler extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) async {
    if (newLocale == AppUtils.appLocale) return;
    AppUtils.setAppLocalization(newLocale);
    _YoImageLabelerState state =
        context.findAncestorStateOfType<_YoImageLabelerState>()!;
    state.changeLanguage(newLocale);
  }

  @override
  State<StatefulWidget> createState() => _YoImageLabelerState();
}

class _YoImageLabelerState extends State<YoImageLabeler> {
  changeLanguage(Locale locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        onGenerateTitle: (context) => AppUtils.yoLocalizations.app_title,
        // Completely done away with setting localization arguments
        // localizationsDelegates, supportedLocales and localeResolutionCallback
        // App ignores phone locale change while it's running
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: ImagesScreen());
  }
}
