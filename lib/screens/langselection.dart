import "package:flutter/material.dart";

class LanguageSelectionDialog extends StatefulWidget {
  final String currentLanguage;
  LanguageSelectionDialog(this.currentLanguage);
  @override
  State<StatefulWidget> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  _LanguageSelectionDialogState();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(context) {
    Map<String, String> langCodes = Map<String, String>();
    langCodes["English"] = "en";
    langCodes["Englisch"] = "en";
    langCodes["German"] = "de";
    langCodes["Deutsch"] = "de";

    List<String> languages = ["English", "German"];
    if (widget.currentLanguage.toLowerCase() == "de") {
      languages = ["Deutsch", "Englisch"];
    }
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
            children: languages.map((String l) {
              return RadioListTile<String>(
                  title: Text(l),
                  value: langCodes[l]!,
                  groupValue: widget.currentLanguage,
                  onChanged: (value) {
                    setState(() {
                      Navigator.pop(context, value);
                    });
                  });
            }).toList(),
          )),
        ));
  }
}
