import "package:flutter/material.dart";

import "package:yo_image_labeler/screens/labels.dart";
// Dart deals with circular references.
// 'images.dart' imports 'main.dart' and vice versa
// 'main.dart' import needed for YoImageLabeler.setLocale() call
import "package:yo_image_labeler/main.dart";
import 'package:yo_image_labeler/models/labelmodel.dart';
import "package:yo_image_labeler/utils/menus.dart";
import 'package:yo_image_labeler/models/imagemodel.dart';
import "package:yo_image_labeler/utils/dbutils.dart";
import "package:yo_image_labeler/utils/apputils.dart";
import "package:yo_image_labeler/screens/stats.dart";
import "package:yo_image_labeler/screens/logs.dart";
import "package:yo_image_labeler/screens/addcamerapicture.dart";
import "package:yo_image_labeler/screens/labelpicture.dart";
import "package:yo_image_labeler/screens/exportdialog.dart";
import "package:yo_image_labeler/screens/langselection.dart";
import "package:yo_image_labeler/utils/globals.dart" as globals;

import "dart:io";

class ImagesAndLabels {
  List<ImageModel> images;
  List<LabelModel> labels;
  ImagesAndLabels(this.images, this.labels);
}

class ImagesScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  List<ImageModel> images = [];
  List<LabelModel> labels = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: getBody(),
        floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 20, right: 30),
            child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddCameraPicture()));
                  setState(() {});
                },
                tooltip:
                    AppUtils.yoLocalizations.add_picture_from_camera_tooltip,
                child: new Icon(Icons.camera))),
        appBar: AppBar(
            automaticallyImplyLeading: true,
            title: Row(children: [
              IconButton(
                  icon: Icon(Icons.language),
                  onPressed: () async {
                    var value = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return LanguageSelectionDialog(
                              AppUtils.appLocale.languageCode);
                        });
                    if (value != null) {
                      YoImageLabeler.setLocale(
                          context,
                          Locale(value,
                              Localizations.localeOf(context).countryCode));
                    }
                  }),
              Text(AppUtils.yoLocalizations.app_title)
            ]),
            actions: [
              PopupMenuButton(
                  onSelected: _jumpToScreen,
                  itemBuilder: (context) {
                    return Menus.menuItems(context);
                  })
            ]));
  }

  Widget getEmptyHomeScreen() {
    String message = AppUtils.yoLocalizations.empty_images_screen_message;

    return Container(
        margin: const EdgeInsets.all(30.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent, width: 3.0)),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.black,
            fontSize: 25.0,
          ),
        ));
  }

  Widget getBody() {
    return Center(
      child: FutureBuilder<ImagesAndLabels>(
          future: getImagesAndLabelsFromDatabase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              images = snapshot.data!.images;
              labels = snapshot.data!.labels;
              Map<int?, String> labelMap = Map();
              labelMap[null] =
                  "<${AppUtils.yoLocalizations.unlabeled_directory}>";
              for (int i = 0; i < labels.length; ++i) {
                labelMap[labels[i].id!] = labels[i].name;
              }

              if (images.length == 0) {
                return getEmptyHomeScreen();
              }

              return GridView.builder(
                  itemCount: images.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemBuilder: (context, index) {
                    return Padding(
                        padding: EdgeInsets.all(2),
                        child: Stack(children: [
                          Material(
                              child: Ink.image(
                                  child: InkWell(onTap: () {
                                    _goToLabelPictureScreen(images[index]);
                                  }),
                                  fit: BoxFit.fill,
                                  image: FileImage(
                                      File(images[index].completeFilePath!)))),
                          Positioned(
                              top: 5,
                              left: 5,
                              width: 200,
                              child: Text(labelMap[images[index].labelId]!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      backgroundColor: Colors.white)))
                        ]));
                  });
            }

            return Center(child: CircularProgressIndicator());
          }),
    );
  }

  Future<ImagesAndLabels> getImagesAndLabelsFromDatabase() async {
    String imagesDir = await AppUtils.imagesDirectory;
    DatabaseHelper d = DatabaseHelper();
    List<dynamic> values = await d.getImages();
    List<ImageModel> imageList = [];
    for (int i = 0; i < values.length; ++i) {
      ImageModel im = ImageModel.fromObject(values[i]);
      im.completeFilePath = imagesDir + "/" + im.fileName;
      imageList.add(im);
    }

    values = await d.getLabels();
    List<LabelModel> labelList = [];
    for (int i = 0; i < values.length; ++i) {
      LabelModel lm = LabelModel.fromObject(values[i]);
      labelList.add(lm);
    }

    return ImagesAndLabels(imageList, labelList);
  }

  Future<void> _exportImages() async {
    if (images.length == 0) {
      AppUtils.showInSnackBar(
          context, AppUtils.yoLocalizations.nothing_to_export);
    } else {
      ExportDetails ed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return WillPopScope(
                onWillPop: () async => false,
                child: ExportDialog(images, labels));
          });
      if (ed.success) {
        AppUtils.showInSnackBar(context,
            AppUtils.yoLocalizations.collection_exported_to_file(ed.exportFile),
            duration: 2);
      } else {
        AppUtils.showInSnackBar(
            context, AppUtils.yoLocalizations.error_during_export(ed.message),
            info: false);
      }
    }
  }

  void _jumpToScreen(String value) async {
    globals.imagesScreenChange = false;
    switch (value) {
      case Menus.ITEM_LABELS:
        await Navigator.push(
            context, MaterialPageRoute(builder: (context) => LabelsScreen()));
        break;
      case Menus.ITEM_LOGS:
        await Navigator.push(
            context, MaterialPageRoute(builder: (context) => LogsScreen()));
        break;
      case Menus.ITEM_EXPORT:
        await _exportImages();
        break;
      case Menus.ITEM_STATS:
        await Navigator.push(
            context, MaterialPageRoute(builder: (context) => StatsScreen()));
        break;
    }
    if (globals.imagesScreenChange) {
      setState(() {});
    }
  }

  void _goToLabelPictureScreen(ImageModel im) async {
    globals.imagesScreenChange = false;
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LabelPictureScreen(
                imagePath: im.completeFilePath!, imageModel: im)));

    // Delete Picture from collection
    if (result is DeletePicture) {
      DeletePicture dp = result;
      DatabaseHelper d = DatabaseHelper();
      await d.deleteImage(dp.imageId);
      AppUtils.showInSnackBar(
          context, AppUtils.yoLocalizations.picture_deleted_from_collection);
      globals.imagesScreenChange = true;
    }

    if (globals.imagesScreenChange) {
      setState(() {});
    }
  }
}
