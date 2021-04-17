import "package:flutter/material.dart";
import 'package:yo_image_labeler/models/labelmodel.dart';
import "package:yo_image_labeler/utils/dbutils.dart";
import "package:yo_image_labeler/utils/apputils.dart";
import "package:yo_image_labeler/screens/logs.dart";
import "package:yo_image_labeler/utils/globals.dart" as globals;

class LabelEditDetails {
  bool edited = false;
  String value = "";
  LabelEditDetails(this.edited, this.value);
}

class LabelsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  int numLabels = 0;
  List<LabelModel> labels = [];

  @override
  Widget build(BuildContext context) {
    getLabelsFromDatabase();

    return Scaffold(
      appBar: AppBar(title: Text(AppUtils.yoLocalizations.labels_screen_title)),
      body: Container(
          padding: EdgeInsets.only(top: 5, left: 5), child: labelsTable()),
      floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 100, right: 30),
          child: FloatingActionButton(
              onPressed: () {
                _editLabel(LabelModel.withName(""));
              },
              tooltip: AppUtils.yoLocalizations.new_class_tooltip,
              child: new Icon(Icons.add))),
    );
  }

  void getLabelsFromDatabase() {
    DatabaseHelper d = DatabaseHelper();
    d.getLabels().then((values) {
      int count = values.length;
      List<LabelModel> labelList = [];
      for (int i = 0; i < count; ++i) {
        labelList.add(LabelModel.fromObject(values[i]));
      }
      setState(() {
        numLabels = count;
        labels = labelList;
      });
    });
  }

  void _editLabel(LabelModel lm) async {
    TextStyle? headlineStyle = Theme.of(context).textTheme.headline6;
    TextEditingController _textController = new TextEditingController();
    _textController.text = lm.name;
    String editedLabel = "";

    var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: lm.id == null
                ? Text(AppUtils.yoLocalizations.create_class)
                : Text(AppUtils.yoLocalizations.edit_class),
            contentPadding: const EdgeInsets.all(16.0),
            content: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextField(
                      maxLength: 32,
                      onChanged: (value) => editedLabel = _textController.text,
                      controller: _textController,
                      autofocus: true,
                      style: headlineStyle,
                      decoration: new InputDecoration(
                          labelStyle:
                              TextStyle(fontSize: headlineStyle!.fontSize),
                          labelText: AppUtils.yoLocalizations.class_name)),
                ),
              ],
            ),
            actions: <Widget>[
              new TextButton(
                  child: Text(AppUtils.yoLocalizations.cancel,
                      style: TextStyle(fontSize: headlineStyle.fontSize)),
                  onPressed: () {
                    Navigator.pop(
                        context, LabelEditDetails(false, editedLabel));
                  }),
              new TextButton(
                  child: Text(AppUtils.yoLocalizations.save,
                      style: TextStyle(fontSize: headlineStyle.fontSize)),
                  onPressed: () {
                    Navigator.pop(context, LabelEditDetails(true, editedLabel));
                  })
            ],
          );
        });
    if (result != null) {
      LabelEditDetails ed = result;
      if (ed.edited) {
        if (ed.value == "") {
          AppUtils.showInSnackBar(
              context, AppUtils.yoLocalizations.class_name_empty,
              info: false, screen: LogsScreen());
        } else {
          if (ed.value != lm.name) {
            final validCharacters = RegExp(r"^[a-zA-Z0-9_öäüÖÄÜß]+$");
            if (!validCharacters.hasMatch(ed.value)) {
              AppUtils.showInSnackBar(
                  context, AppUtils.yoLocalizations.class_name_valid_chars,
                  info: false, screen: LogsScreen());
            } else {
              DatabaseHelper d = DatabaseHelper();
              int dbReturn = -1;
              if (lm.id == null) {
                dbReturn = await d.insertLabel(LabelModel.withName(ed.value));
              } else {
                lm.name = ed.value;
                dbReturn = await d.updateLabel(lm);
              }
              if (dbReturn == -1) {
                AppUtils.showInSnackBar(context,
                    AppUtils.yoLocalizations.class_name_issue(ed.value),
                    info: false, screen: LogsScreen());
              } else {
                if (lm.id == null) {
                  AppUtils.showInSnackBar(
                      context, AppUtils.yoLocalizations.class_creation_success);
                } else {
                  AppUtils.showInSnackBar(
                      context, AppUtils.yoLocalizations.class_update_success);
                  globals.imagesScreenChange = true;
                }
                getLabelsFromDatabase();
              }
            }
          }
        }
      }
    }
  }

  void _deleteLabel(LabelModel lm) async {
    DatabaseHelper d = DatabaseHelper();
    int ct = await d.getImageCountWithLabelId(lm.id!);

    TextStyle? headlineStyle = Theme.of(context).textTheme.headline6;
    var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppUtils.yoLocalizations.delete_class),
            contentPadding: const EdgeInsets.all(16.0),
            content: new Row(
              children: <Widget>[
                new Expanded(
                    child: new Text(
                        AppUtils.yoLocalizations
                            .delete_class_confirmation(ct, lm.name),
                        style: TextStyle(fontSize: headlineStyle!.fontSize)))
              ],
            ),
            actions: <Widget>[
              new TextButton(
                  child: Text(AppUtils.yoLocalizations.no,
                      style: TextStyle(fontSize: headlineStyle.fontSize)),
                  onPressed: () {
                    Navigator.pop(context, false);
                  }),
              new TextButton(
                  child: Text(AppUtils.yoLocalizations.yes,
                      style: TextStyle(fontSize: headlineStyle.fontSize)),
                  onPressed: () {
                    Navigator.pop(context, true);
                  })
            ],
          );
        });
    if (result) {
      d.deleteLabel(lm.id!);
      if (ct > 0) {
        globals.imagesScreenChange = true;
      }
      AppUtils.showInSnackBar(
          context, AppUtils.yoLocalizations.class_delete_success(lm.name));
      getLabelsFromDatabase();
    } else {}
  }

  Widget labelsTable() {
    TextStyle? headlineStyle = Theme.of(context).textTheme.headline6;
    Text getTitleRowText(String t) {
      return Text(t,
          style:
              TextStyle(fontSize: headlineStyle!.fontSize, color: Colors.blue));
    }

    Text getRowText(String t, {bool ellipsis = false}) {
      return Text(t,
          style: TextStyle(fontSize: headlineStyle!.fontSize),
          overflow: ellipsis ? TextOverflow.ellipsis : null);
    }

    double w1 = MediaQuery.of(context).size.width * 0.08;
    double w2 = MediaQuery.of(context).size.width * 0.42;

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
            showBottomBorder: true,
            columns: <DataColumn>[
              DataColumn(label: getTitleRowText("#")),
              DataColumn(
                  label: getTitleRowText(AppUtils.yoLocalizations.class_name)),
              DataColumn(label: getTitleRowText(" -")),
            ],
            rows: List<DataRow>.generate(
                numLabels,
                (int index) => DataRow(cells: <DataCell>[
                      DataCell(Container(
                          width: w1,
                          child: getRowText((index + 1).toString()))),
                      DataCell(
                          Container(
                              width: w2,
                              child: getRowText(labels[index].name + " ",
                                  ellipsis: true)),
                          showEditIcon: true, onTap: () {
                        _editLabel(labels[index]);
                      }),
                      DataCell(Icon(Icons.delete), onTap: () {
                        _deleteLabel(labels[index]);
                      })
                    ]))));
  }
}
