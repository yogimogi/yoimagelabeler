import "package:flutter/material.dart";
import 'dart:io';

import 'package:yo_image_labeler/models/labelmodel.dart';
import 'package:yo_image_labeler/models/imagemodel.dart';
import "package:yo_image_labeler/screens/classselectiondialog.dart";
import "package:yo_image_labeler/utils/dbutils.dart";
import "package:yo_image_labeler/utils/apputils.dart";
import "package:yo_image_labeler/utils/globals.dart" as globals;

class PictureEditDetails {
  String fileName;
  String? completeFilePath;
  int? labelId;
  PictureEditDetails(this.fileName, this.labelId, this.completeFilePath);
}

class DeletePicture {
  int imageId;
  DeletePicture(this.imageId);
}

class LabelPictureScreen extends StatefulWidget {
  final String imagePath;
  final ImageModel? imageModel;

  LabelPictureScreen(
      {Key? key, required this.imagePath, required this.imageModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _LabelPictureScreenState(imagePath, imageModel);
}

class _LabelPictureScreenState extends State<LabelPictureScreen> {
  final String imagePath;
  ImageModel? imageModel;
  String _className = "";
  int? _labelId;
  List<LabelModel> labels = [];

  _LabelPictureScreenState(this.imagePath, this.imageModel);

  void getLabelsFromDatabase() {
    DatabaseHelper d = DatabaseHelper();
    d.getLabels().then((values) {
      int count = values.length;
      List<LabelModel> labelList = [];
      for (int i = 0; i < count; ++i) {
        labelList.add(LabelModel.fromObject(values[i]));
      }
      setState(() {
        labels = labelList;
        if (imageModel != null) {
          for (int i = 0; i < labels.length; ++i) {
            if (labels[i].id == imageModel!.labelId) {
              _className = labels[i].name;
              _labelId = labels[i].id;
              break;
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getLabelsFromDatabase();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppUtils.yoLocalizations.label_picture_title),
        actions: [
          IconButton(
            icon: imageModel == null
                ? Icon(Icons.add_a_photo)
                : Icon(Icons.delete),
            onPressed: () {
              if (imageModel == null) {
                _addPictureToCollection();
              } else {
                _deletePictureFromCollection();
              }
            },
          )
        ],
      ),
      body: getBody(),
    );
  }

  Widget getBody() {
    double fontSize = Theme.of(context).textTheme.headline6!.fontSize!;
    return Column(children: [
      Container(
          height: 60.0,
          width: 250.0,
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: ElevatedButton(
              onPressed: () {
                _applyClass();
              },
              child: Text(
                  _className == ""
                      ? AppUtils.yoLocalizations.assign_class
                      : _className,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize)))),
      AspectRatio(
          aspectRatio: 1,
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.blue,
                  width: 2.0,
                ),
              ),
              child: Material(
                  child: Ink.image(
                      child: InkWell(onTap: () {
                        _applyClass();
                      }),
                      fit: BoxFit.cover,
                      image: FileImage(File(widget.imagePath)))))),
      Container(
          height: imageModel == null ? 50.0 : 0.0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
                padding: EdgeInsets.only(right: 10),
                child: ElevatedButton(
                    onPressed: () async {
                      _addPictureToCollection();
                    },
                    child: Text(AppUtils.yoLocalizations.add,
                        style: TextStyle(fontSize: fontSize)))),
          ]))
    ]);
  }

  void _addPictureToCollection() async {
    // Adding Image to the collection
    // Copy image from cache location to a permanant location
    File original = File(imagePath);
    File clippedImage = await AppUtils.clipImage(original);
    Navigator.pop(
        context,
        PictureEditDetails(
            clippedImage.path.split('/').last, _labelId, clippedImage.path));
  }

  void _deletePictureFromCollection() async {
    // Can possibly ask for delete confirmation dialog
    Navigator.pop(context, DeletePicture(imageModel!.id!));
  }

  void _applyClass() async {
    if (labels.length == 0) {
      AppUtils.showInSnackBar(context, AppUtils.yoLocalizations.no_classes);
    } else {
      var value = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return ClassSelectionDialog(labels, _className);
          });
      if (value != null) {
        setState(() {
          _className = value;
          for (int i = 0; i < labels.length; ++i) {
            if (labels[i].name == _className) {
              _labelId = labels[i].id;
              break;
            }
          }
          // If imageModel not null, update ImageModel
          if (imageModel != null) {
            if (imageModel!.labelId != _labelId) {
              imageModel!.labelId = _labelId;
            }
          }
        });
        // We would have had to make setState async if we were to make
        // below database update call inside it
        if (imageModel != null) {
          // Make db call to update label id
          DatabaseHelper d = DatabaseHelper();
          imageModel!.updated = DateTime.now().millisecondsSinceEpoch;
          int success = await d.updateImage(imageModel!);
          if (success != -1) {
            AppUtils.showInSnackBar(
                context, AppUtils.yoLocalizations.class_label_update_success);
            globals.imagesScreenChange = true;
          }
        }
      }
    }
  }
}
