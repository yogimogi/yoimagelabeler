import "package:flutter/material.dart";
import "dart:io";
import "package:flutter_archive/flutter_archive.dart";

import "package:path_provider/path_provider.dart";

import 'package:yo_image_labeler/models/labelmodel.dart';
import 'package:yo_image_labeler/models/imagemodel.dart';

import "package:yo_image_labeler/utils/apputils.dart";

class ExportDetails {
  bool success;
  String message;
  String exportFile;

  ExportDetails(this.success, this.exportFile, this.message);
}

class ExportDialog extends StatefulWidget {
  final List<ImageModel> images;
  final List<LabelModel> labels;
  ExportDialog(this.images, this.labels);
  @override
  State<StatefulWidget> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog>
    with TickerProviderStateMixin {
  late AnimationController controller;

  Future<void> _copyImageFile(Directory exporDir, ImageModel im,
      Map<int?, Directory> labelDirMap, String imagesDirPath) async {
    Directory labelDir = labelDirMap[im.labelId]!;

    File imageFile = File("$imagesDirPath/${im.fileName}");
    await imageFile.copy("${labelDir.path}/${im.fileName}");
  }

  // We are creating all the sub-directories even if there are no images
  // corresponding to a label
  Future<Map<int?, Directory>> _createLabelDirMap(Directory exportDir) async {
    Map<int?, Directory> labelDirMap = Map<int?, Directory>();
    // We don't allow '-' to be present in label name,
    // so there can't be label with name 'un-labeled'
    String unlabeledDirName = AppUtils.yoLocalizations.unlabeled_directory;
    labelDirMap[null] =
        await Directory("${exportDir.path}/$unlabeledDirName").create();
    for (int i = 0; i < widget.labels.length; ++i) {
      labelDirMap[widget.labels[i].id!] = await Directory(
              exportDir.path + "/${widget.labels[i].name.toLowerCase()}")
          .create();
    }

    return labelDirMap;
  }

  Future<void> _doExport() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    try {
      String ddName = "Download";
      Directory ddDirectory = await AppUtils.createDownloadDirectory(ddName);
      String exportFile =
          "export_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.zip";
      Directory exportDir = await AppUtils.deleteNCreateDirectory(
          (await getExternalStorageDirectory())!.path + "/export");

      Map<int?, Directory> labelDirMap = await _createLabelDirMap(exportDir);

      String imagesDirPath = await AppUtils.imagesDirectory;
      for (int i = 0; i < widget.images.length; ++i) {
        await _copyImageFile(
            exportDir, widget.images[i], labelDirMap, imagesDirPath);
      }
      final zipFile = File("${ddDirectory.path}/$exportFile");
      await ZipFile.createFromDirectory(
          sourceDir: exportDir,
          zipFile: zipFile,
          recurseSubDirs: true,
          includeBaseDirectory: true);
      await exportDir.delete(recursive: true);
      AppUtils.logMessage(
          AppUtils.yoLocalizations.export_successful,
          AppUtils.yoLocalizations.export_success_message(
              '$ddName/$exportFile', (stopwatch.elapsed.inMilliseconds) / 1000),
          "info");
      Navigator.pop(context, ExportDetails(true, "'$ddName/$exportFile'", ""));
    } on Exception catch (e) {
      AppUtils.logException(e.runtimeType.toString(), e.toString());
      Navigator.pop(context, ExportDetails(false, "", e.toString()));
    } on Error catch (e) {
      AppUtils.logException(e.runtimeType.toString(), e.toString());
      Navigator.pop(context, ExportDetails(false, "", e.toString()));
    }
  }

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
    _doExport();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: exportDialog(context),
    );
  }

  Widget exportDialog(context) {
    return ConstrainedBox(
        constraints: new BoxConstraints(
          minHeight: 100.0,
          maxHeight: 150.0,
        ),
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  AppUtils.yoLocalizations
                      .export_progress_message(widget.images.length),
                  style: TextStyle(fontSize: 20),
                ),
                CircularProgressIndicator(
                  value: controller.value,
                  semanticsLabel:
                      AppUtils.yoLocalizations.export_progress_indicator,
                ),
              ],
            )));
  }
}
