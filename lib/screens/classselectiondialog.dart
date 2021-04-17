import "package:flutter/material.dart";

import 'package:yo_image_labeler/models/labelmodel.dart';

class ClassSelectionDialog extends StatefulWidget {
  final List<LabelModel> labels;
  final String? currentClass;
  ClassSelectionDialog(this.labels, this.currentClass);
  @override
  State<StatefulWidget> createState() =>
      _ClassSelectionDialogState(labels, currentClass);
}

class _ClassSelectionDialogState extends State<ClassSelectionDialog> {
  List<LabelModel> labels = [];
  String? currentClass;
  _ClassSelectionDialogState(this.labels, this.currentClass);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(context) {
    return ConstrainedBox(
        constraints: new BoxConstraints(
          minHeight: 100.0,
          maxHeight: 300.0,
        ),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.labels.map((LabelModel lm) {
              return RadioListTile<String>(
                  title: Text(lm.name),
                  value: lm.name,
                  groupValue: currentClass,
                  onChanged: (value) {
                    setState(() {
                      currentClass = value!;
                      debugPrint(currentClass);
                      Navigator.pop(context, value);
                    });
                  });
            }).toList(),
          )),
        ));
  }
}
