class LabelModel {
  int? id;
  String name;
  // int? classId;

  static const String TABLE_NAME = "yo_label";
  static const String _COLUMN_ID = "id";
  static const String _COLUMN_NAME = "name";
  // static const String _COLUMN_CLASS_ID = "class_id";

  static get idColumn => _COLUMN_ID;

  // UNIQUE(column_name COLLATE NOCASE) makes a
  // case-insensitive unique column
  static String qCreateTable =
      "CREATE TABLE $TABLE_NAME($_COLUMN_ID INTEGER PRIMARY KEY, $_COLUMN_NAME TEXT NOT NULL, " +
          "UNIQUE($_COLUMN_NAME COLLATE NOCASE))";

  // static String qCreateTable =
  //     "CREATE TABLE $TABLE_NAME($_COLUMN_ID INTEGER PRIMARY KEY, $_COLUMN_NAME TEXT NOT NULL, " +
  //         "$_COLUMN_CLASS_ID INT, UNIQUE($_COLUMN_NAME COLLATE NOCASE))";

  static String qGetAll = "SELECT * from $TABLE_NAME ORDER BY $_COLUMN_ID ASC";

  LabelModel.withId(this.id, this.name);
  LabelModel.withName(this.name);
  LabelModel(this.name);

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map[_COLUMN_ID] = id;
    map[_COLUMN_NAME] = name;
    // map[_COLUMN_CLASS_ID] = classId;
    return map;
  }

  static LabelModel fromObject(dynamic o) {
    // return LabelModel.withId(
    //     o[_COLUMN_ID], o[_COLUMN_NAME], o[_COLUMN_CLASS_ID]);
    return LabelModel.withId(o[_COLUMN_ID], o[_COLUMN_NAME]);
  }
}
