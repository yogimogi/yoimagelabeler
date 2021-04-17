import 'dart:async';
import 'dart:io';
import 'package:yo_image_labeler/models/labelmodel.dart';
import 'package:yo_image_labeler/models/imagemodel.dart';

import 'package:flutter/material.dart';
import "package:yo_image_labeler/utils/dbutils.dart";
import "package:yo_image_labeler/utils/apputils.dart";

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class TableRow {
  String label;
  int count;
  TableRow(this.label, this.count);
}

class _StatsScreenState extends State<StatsScreen> {
  int rowCount = 0;
  List<TableRow> tableRows = [];
  TextStyle? headlineStyle;
  int imagesSize = 0;
  int dbSize = 0;
  @override
  void initState() {
    super.initState();
    getDataFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    headlineStyle = Theme.of(context).textTheme.headline6;
    return Scaffold(
        appBar: AppBar(
          title: Text(AppUtils.yoLocalizations.stats_title),
        ),
        body: getBody());
  }

  int getImageCount(List<ImageCountByLabelId> imageList, int? labelId) {
    for (int i = 0; i < imageList.length; ++i) {
      if (imageList[i].labelId == labelId) return imageList[i].count;
    }
    return 0;
  }

  Future<void> getDataFromDatabase() async {
    DatabaseHelper d = DatabaseHelper();
    var values = await d.getLabels();

    List<LabelModel> labelList = [];
    for (int i = 0; i < values.length; ++i) {
      labelList.add(LabelModel.fromObject(values[i]));
    }

    values = await d.getImageCountByLabelId();
    List<ImageCountByLabelId> imageCountList = [];
    for (int i = 0; i < values.length; ++i) {
      imageCountList.add(ImageCountByLabelId.fromObject(values[i]));
    }

    List<TableRow> rows = [];
    for (int i = 0; i < labelList.length; ++i) {
      rows.add(TableRow(
          labelList[i].name, getImageCount(imageCountList, labelList[i].id!)));
    }
    rows.add(TableRow(AppUtils.yoLocalizations.not_labelled,
        getImageCount(imageCountList, null)));

    int iSize = await AppUtils.imagesSize;
    int dSize = await File(await AppUtils.dbFile).length();

    setState(() {
      rowCount = labelList.length + 1;
      tableRows = rows;
      imagesSize = iSize;
      dbSize = dSize;
    });
  }

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

  Widget sizesTable() {
    double w1 = MediaQuery.of(context).size.width * 0.4;

    int sizeRowCount = 2;
    List<String> names = [
      AppUtils.yoLocalizations.images,
      AppUtils.yoLocalizations.database
    ];
    List<int> sizes = [imagesSize ~/ 1000, dbSize ~/ 1000];

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
            showBottomBorder: true,
            columns: <DataColumn>[
              DataColumn(label: getTitleRowText(AppUtils.yoLocalizations.type)),
              DataColumn(
                  label: getTitleRowText(AppUtils.yoLocalizations.kbytes))
            ],
            rows: List<DataRow>.generate(
                sizeRowCount,
                (int index) => DataRow(cells: <DataCell>[
                      DataCell(Container(
                          width: w1, child: getRowText(names[index]))),
                      DataCell(
                        Container(
                            child: getRowText(
                                AppUtils.getLocaleInteger(sizes[index]),
                                ellipsis: true)),
                      )
                    ]))));
  }

  Widget labelsTable() {
    double w1 = MediaQuery.of(context).size.width * 0.6;

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
            showBottomBorder: true,
            columns: <DataColumn>[
              DataColumn(
                  label: getTitleRowText(AppUtils.yoLocalizations.class_name)),
              DataColumn(label: getTitleRowText("#"))
            ],
            rows: List<DataRow>.generate(
                rowCount,
                (int index) => DataRow(cells: <DataCell>[
                      DataCell(Container(
                          width: w1,
                          child: getRowText(tableRows[index].label))),
                      DataCell(
                        Container(
                            child: getRowText(tableRows[index].count.toString(),
                                ellipsis: true)),
                      )
                    ]))));
  }

  Widget getBody() {
    if (dbSize == 0) {
      return Center(child: CircularProgressIndicator());
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Text(AppUtils.yoLocalizations.size_on_disk,
              style: TextStyle(fontSize: headlineStyle!.fontSize))),
      sizesTable(),
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Divider(
            color: Colors.lightBlue,
            height: 10,
            thickness: 2,
            indent: 10,
            endIndent: 10,
          )),
      Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Text(AppUtils.yoLocalizations.images_per_class,
              style: TextStyle(fontSize: headlineStyle!.fontSize))),
      labelsTable(),
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Divider(
            color: Colors.lightBlue,
            height: 10,
            thickness: 2,
            indent: 10,
            endIndent: 10,
          )),
    ]);
  }
}
