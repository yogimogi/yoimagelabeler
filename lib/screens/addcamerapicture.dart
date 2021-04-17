import "package:flutter/material.dart";
import 'package:camera/camera.dart';
import 'package:yo_image_labeler/models/imagemodel.dart';
import 'package:yo_image_labeler/screens/logs.dart';
import 'package:yo_image_labeler/screens/labelpicture.dart';
import 'package:yo_image_labeler/utils/dbutils.dart';

import "package:yo_image_labeler/utils/globals.dart" as globals;

import "package:yo_image_labeler/utils/apputils.dart";

import 'dart:async';

// Most of the code from https://pub.dev/packages/camera/example
class AddCameraPicture extends StatefulWidget {
  @override
  _AddCameraPictureState createState() => _AddCameraPictureState();
}

class _AddCameraPictureState extends State<AddCameraPicture>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _cameraInitDone = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _imageBeingCaptured = false;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  void _showCameraException(CameraException e) {
    AppUtils.logException(e.code, e.description);
    String error = AppUtils.yoLocalizations.error;
    AppUtils.showInSnackBar(context, "$error: ${e.code}: ${e.description}");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    if (!globals.cameraAvailable) {
      return;
    }
    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    initCameraController();
  }

  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  void initCameraController() async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(globals.firstCamera!, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);

    _initializeControllerFuture = _controller!.initialize();
    _initializeControllerFuture.whenComplete(() {
      this._cameraInitDone = true;
    });
    _initializeControllerFuture.catchError((e) {
      AppUtils.logMessage(e.code, e.description, "error");
      globals.cameraPermission = false;
      if (mounted) {
        setState(() {});
      }
    });
    _initializeControllerFuture.then((value) async {
      _minAvailableExposureOffset = await _controller!.getMinExposureOffset();
      _maxAvailableExposureOffset = await _controller!.getMaxExposureOffset();
      _maxAvailableZoom = await _controller!.getMaxZoomLevel();
      _minAvailableZoom = await _controller!.getMinZoomLevel();
      globals.cameraPermission = true;

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimationController.dispose();
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCameraController();
    }
  }

  GlobalKey stickyKey = GlobalKey();
  Widget getCameraPreview() {
    return Stack(children: [
      Column(children: [
        Expanded(
            child: Container(
                key: stickyKey,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: Colors.redAccent,
                    width: 0.0,
                  ),
                ),
                child: Center(
                  child: Listener(
                      onPointerDown: (_) => _pointers++,
                      onPointerUp: (_) => _pointers--,
                      child: CameraPreview(
                        _controller!,
                        child: LayoutBuilder(builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            onTapDown: (details) =>
                                onViewFinderTap(details, constraints),
                          );
                        }),
                      )),
                ))),
        _flashExposureFocusRowWidget(),
      ]),
      CustomPaint(
          foregroundPainter: new CameraSquarePainter(context, stickyKey))
    ]);
  }

  Widget _flashExposureFocusRowWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.flash_on),
              color: Colors.blue,
              onPressed: _controller != null ? onFlashModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(Icons.exposure),
              color: Colors.blue,
              onPressed:
                  _controller != null ? onExposureModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(Icons.filter_center_focus),
              color: Colors.blue,
              onPressed: _controller != null ? onFocusModeButtonPressed : null,
            ),
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        _focusModeControlRowWidget(),
      ],
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.flash_off),
              color: _controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_auto),
              color: _controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_on),
              color: _controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.highlight),
              color: _controller?.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.blue,
              onPressed: _controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: _controller?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: _controller?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Center(
                child: Text(AppUtils.yoLocalizations.exposure_mode),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    child: Text(AppUtils.yoLocalizations.auto),
                    style: styleAuto,
                    onPressed: _controller != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (_controller != null) {
                        _controller!.setExposurePoint(null);
                        AppUtils.showInSnackBar(context,
                            AppUtils.yoLocalizations.reset_exposure_point,
                            duration: 1);
                      }
                    },
                  ),
                  TextButton(
                    child: Text(AppUtils.yoLocalizations.locked),
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                  ),
                ],
              ),
              Center(
                child: Text(AppUtils.yoLocalizations.exposure_offset),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: _controller?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: _controller?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Center(
                child: Text(AppUtils.yoLocalizations.focus_mode),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    child: Text(AppUtils.yoLocalizations.auto),
                    style: styleAuto,
                    onPressed: _controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (_controller != null) _controller!.setFocusPoint(null);
                      AppUtils.showInSnackBar(
                          context, AppUtils.yoLocalizations.reset_focus_point,
                          duration: 1);
                    },
                  ),
                  TextButton(
                    child: Text(AppUtils.yoLocalizations.locked),
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      AppUtils.showInSnackBar(
          context,
          AppUtils.yoLocalizations
              .flash_mode_set(mode.toString().split('.').last),
          duration: 1);
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
      AppUtils.showInSnackBar(
          context,
          AppUtils.yoLocalizations
              .exposure_mode_set(mode.toString().split('.').last),
          duration: 1);
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) setState(() {});
      AppUtils.showInSnackBar(
          context,
          AppUtils.yoLocalizations
              .focus_mode_set(mode.toString().split('.').last),
          duration: 1);
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null) {
      return;
    }

    try {
      await _controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller == null) {
      return;
    }

    try {
      await _controller!.setExposureMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (_controller == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await _controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (_controller == null) {
      return;
    }

    try {
      await _controller!.setFocusMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller!.setZoomLevel(_currentScale);
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller!.setExposurePoint(offset);
    _controller!.setFocusPoint(offset);
  }

  Widget getCameraErrorScreen() {
    String error = AppUtils.yoLocalizations.big_camera_error_message;

    return Container(
        margin: const EdgeInsets.all(30.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent, width: 3.0)),
        child: Text(
          error,
          style: TextStyle(
            color: Colors.black,
            fontSize: 25.0,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppUtils.yoLocalizations.add_camera_picture_title)),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: !_cameraInitDone
          ? Center(child: CircularProgressIndicator())
          : globals.cameraAvailable && globals.cameraPermission
              ? getCameraPreview()
              : getCameraErrorScreen(),
      floatingActionButton: _cameraInitDone && globals.cameraAvailable
          ? Padding(
              padding: EdgeInsets.only(bottom: 50, right: 30),
              child: FloatingActionButton(
                child: Icon(Icons.camera_alt),
                onPressed: () async {
                  try {
                    if (_imageBeingCaptured) return;
                    _imageBeingCaptured = true;
                    await _initializeControllerFuture;
                    _controller!.takePicture().then((XFile file) {
                      // Picture was taken, display it on a new screen.
                      _goToLabelPictureScreen(context, file.path);
                      _imageBeingCaptured = false;
                    }).catchError((Object e) {
                      _imageBeingCaptured = false;
                    });
                  } catch (e) {
                    _imageBeingCaptured = false;
                    AppUtils.logException(
                        e.runtimeType.toString(), e.toString());
                    AppUtils.showInSnackBar(context,
                        AppUtils.yoLocalizations.image_could_not_be_captured,
                        info: false, screen: LogsScreen());
                    print(e);
                  }
                },
              ))
          : null,
    );
  }
}

void _goToLabelPictureScreen(BuildContext context, String path) async {
  var result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              LabelPictureScreen(imagePath: path, imageModel: null)));
  // Nothing needs to be done
  if (result == null) return;

  // Add Picture to collection
  PictureEditDetails ed = result;
  DatabaseHelper d = DatabaseHelper();
  int success = await d.insertImage(ImageModel.withRef(
      ed.fileName, await AppUtils.imageFileSize(ed.fileName), ed.labelId));
  if (success != -1) {
    AppUtils.logMessage(
        AppUtils.yoLocalizations.image_added_to_collection,
        AppUtils.yoLocalizations.added_image_path(ed.completeFilePath!),
        "info");
    AppUtils.showInSnackBar(
        context, AppUtils.yoLocalizations.image_added_to_collection);
    globals.imagesScreenChange = true;
  }
}

class CameraSquarePainter extends CustomPainter {
  final BuildContext context;
  final GlobalKey stickyKey;
  CameraSquarePainter(this.context, this.stickyKey);
  @override
  void paint(Canvas canvas, Size size) {
    double w = MediaQuery.of(context).size.width;
    double h = 400;

    final keyContext = stickyKey.currentContext;
    if (keyContext != null) {
      // widget is visible
      final box = keyContext.findRenderObject() as RenderBox;
      w = box.size.width;
      h = box.size.height;
    }

    Paint paint = new Paint()
      ..strokeWidth = 2
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset(0, h / 2 - w / 2) & Size(w, w), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
