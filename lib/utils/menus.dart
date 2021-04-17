import 'dart:collection';

import 'package:flutter/material.dart';
import "package:yo_image_labeler/utils/apputils.dart";

class Menus {
  static const String _SEPARATOR = "-";

  static const String ITEM_LABELS = "menuitem_labels";
  static const String ITEM_EXPORT = "menuitem_export";
  static const String ITEM_STATS = "menuitem_stats";
  static const String ITEM_LOGS = "menuitem_logs";

  static List<PopupMenuEntry<String>> menuItems(BuildContext context) {
    final List<String> items = [
      ITEM_LABELS,
      ITEM_EXPORT,
      ITEM_STATS,
      _SEPARATOR,
      ITEM_LOGS
    ];

    Map<String, String> itemToValue = HashMap<String, String>();
    itemToValue[ITEM_LABELS] = AppUtils.yoLocalizations.menuitem_labels;
    itemToValue[ITEM_EXPORT] = AppUtils.yoLocalizations.menuitem_export;
    itemToValue[ITEM_STATS] = AppUtils.yoLocalizations.menuitem_stats;
    itemToValue[ITEM_LOGS] = AppUtils.yoLocalizations.menuitem_logs;

    List<IconData?> iconData = [
      Icons.label,
      Icons.file_download,
      Icons.info,
      // To account for the Divider
      null,
      Icons.table_rows
    ];

    TextStyle? headlineStyle = Theme.of(context).textTheme.headline6;
    List<PopupMenuEntry<String>> x = [];
    for (int i = 0; i < items.length; ++i) {
      if (items[i] == _SEPARATOR) {
        x.add(PopupMenuDivider());
      } else {
        String? v = itemToValue[items[i]];
        x.add(PopupMenuItem<String>(
            value: items[i],
            child: Row(children: [
              Icon(iconData[i], color: Colors.blue),
              Text(v!,
                  style: TextStyle(
                      color: Colors.blue, fontSize: headlineStyle!.fontSize))
            ])));
      }
    }
    return x;
  }
}
