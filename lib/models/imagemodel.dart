import "package:yo_image_labeler/models/labelmodel.dart";

class ImageCountByLabelId {
  int? labelId;
  int count;
  ImageCountByLabelId(this.labelId, this.count);
  static ImageCountByLabelId fromObject(dynamic o) {
    return ImageCountByLabelId(
        o[ImageModel._COLUMN_LABEL_ID], o[ImageModel._AGGR_COL_NAME]);
  }
}

class ImageModel {
  int? id;
  String fileName;
  int created;
  int updated;
  int? labelId;
  int sizeInBytes;
  String? completeFilePath;

  static const String TABLE_NAME = "yo_image";
  static const String _COLUMN_ID = "id";
  static const String _COLUMN_FILE_NAME = "file_name";
  static const String _COLUMN_CREATED = "created";
  static const String _COLUMN_UPDATED = "updated";
  static const String _COLUMN_LABEL_ID = "label_id";
  static const String _COLUMN_SIZE_IN_BYTES = "size_in_bytes";
  static const String _AGGR_COL_NAME = "count";

  static get idColumn => _COLUMN_ID;

  static String qCreateTable =
      "CREATE TABLE $TABLE_NAME($_COLUMN_ID INTEGER PRIMARY KEY, $_COLUMN_FILE_NAME TEXT, " +
          "$_COLUMN_CREATED INT, $_COLUMN_UPDATED INT, $_COLUMN_LABEL_ID INT, $_COLUMN_SIZE_IN_BYTES INT, " +
          "CONSTRAINT fk_on_labels FOREIGN KEY($_COLUMN_LABEL_ID) " +
          "REFERENCES ${LabelModel.TABLE_NAME}($_COLUMN_ID) ON DELETE SET NULL)";

  static String qGetAll = "SELECT * from $TABLE_NAME ORDER BY $_COLUMN_ID ASC";

  static String qCountByLabelId =
      "SELECT $_COLUMN_LABEL_ID, COUNT($_COLUMN_ID) as $_AGGR_COL_NAME from $TABLE_NAME GROUP BY $_COLUMN_LABEL_ID";

  static String qGetImageCountWithLabel(int labelId) {
    return "SELECT COUNT(*) from $TABLE_NAME WHERE $_COLUMN_LABEL_ID = $labelId";
  }

  ImageModel(this.fileName, this.sizeInBytes)
      : created = DateTime.now().millisecondsSinceEpoch,
        updated = DateTime.now().millisecondsSinceEpoch;
  ImageModel.withRef(this.fileName, this.sizeInBytes, this.labelId)
      : created = DateTime.now().millisecondsSinceEpoch,
        updated = DateTime.now().millisecondsSinceEpoch;
  ImageModel.withId(this.id, this.fileName, this.sizeInBytes)
      : created = DateTime.now().millisecondsSinceEpoch,
        updated = DateTime.now().millisecondsSinceEpoch;
  ImageModel.withAll(this.id, this.fileName, this.sizeInBytes, this.created,
      this.updated, this.labelId);

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map[_COLUMN_ID] = id;
    map[_COLUMN_FILE_NAME] = fileName;
    map[_COLUMN_CREATED] = created;
    map[_COLUMN_UPDATED] = updated;
    map[_COLUMN_LABEL_ID] = labelId;
    map[_COLUMN_SIZE_IN_BYTES] = sizeInBytes;

    return map;
  }

  static ImageModel fromObject(dynamic o) {
    return ImageModel.withAll(
        o[_COLUMN_ID],
        o[_COLUMN_FILE_NAME],
        o[_COLUMN_SIZE_IN_BYTES],
        o[_COLUMN_CREATED],
        o[_COLUMN_UPDATED],
        o[_COLUMN_LABEL_ID]);
  }
}
