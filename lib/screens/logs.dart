import "package:flutter/material.dart";
import "package:yo_image_labeler/utils/apputils.dart";

class LogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppUtils.yoLocalizations.logs_title)),
        body: diagnosticsListItems());
  }

  String getTitle(DiagnosticMessage m) {
    String dateString = AppUtils.getLocaleDateTimeString(m.epochTime);
    return "[" + dateString + "] " + m.title;
  }

  ListView diagnosticsListItems() {
    List<DiagnosticMessage> messages = AppUtils.logMessages;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int position) {
        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: messages[position].messageType == "info"
                    ? Colors.green
                    : Colors.red,
                child: Text((messages.length - position).toString())),
            title: Text(getTitle(messages[position])),
            subtitle: Text(messages[position].message == null
                ? ""
                : messages[position].message!),
            onTap: () {},
          ),
        );
      },
    );
  }
}
