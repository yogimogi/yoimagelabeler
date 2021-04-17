import "package:sqflite/sqflite.dart";
import "package:yo_image_labeler/utils/apputils.dart";
import "package:yo_image_labeler/models/imagemodel.dart";
import "package:yo_image_labeler/models/labelmodel.dart";

class DatabaseHelper {
  static final DatabaseHelper _instanz = DatabaseHelper._internal();
  final Future<Database> _database;
  DatabaseHelper._internal() : _database = DatabaseHelper._initDatabase();
  factory DatabaseHelper() {
    return _instanz;
  }

  static Future<Database> _initDatabase() async {
    String dbFile = await AppUtils.dbFile;
    var database = await openDatabase(
      dbFile,
      onConfigure: (db) async {
        // One has to enable foreign key support in Sqlite explicitly
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(LabelModel.qCreateTable);
        await db.execute(ImageModel.qCreateTable);
        await _insertSampleData(db);
      },
      version: 1,
    );
    return database;
  }

  static Future<void> _insertSampleData(Database db) async {
    String class1 = AppUtils.yoLocalizations.positive_class;
    String class2 = AppUtils.yoLocalizations.negative_class;

    int class1Id =
        await db.insert(LabelModel.TABLE_NAME, LabelModel(class1).toMap());
    int class2Id =
        await db.insert(LabelModel.TABLE_NAME, LabelModel(class2).toMap());

    await _insertImages(db, AppUtils.pigeonImages, class1Id);
    await _insertImages(db, AppUtils.nonPigeonImages, class2Id);
  }

  static Future<void> _insertImages(
      Database db, List<String> images, int? labelId) async {
    for (int i = 0; i < images.length; ++i) {
      String fileName = images[i];
      int fileSize = await AppUtils.imageFileSize(fileName);
      await db.insert(ImageModel.TABLE_NAME,
          ImageModel.withRef(fileName, fileSize, labelId).toMap());
    }
  }

  Future<List> getLabels() async {
    final db = await _database;
    var result = await db.rawQuery(LabelModel.qGetAll);
    return result;
  }

  Future<List> getImageCountByLabelId() async {
    final db = await _database;
    var result = await db.rawQuery(ImageModel.qCountByLabelId);
    return result;
  }

  Future<int> getImageCountWithLabelId(int labelId) async {
    final db = await _database;
    var result = Sqflite.firstIntValue(
        await db.rawQuery(ImageModel.qGetImageCountWithLabel(labelId)));
    return result!;
  }

  Future<List> getImages() async {
    final db = await _database;
    var result = await db.rawQuery(ImageModel.qGetAll);
    return result;
  }

  Future<int> deleteImage(int imageId) async {
    final db = await _database;
    return db.delete(ImageModel.TABLE_NAME,
        where: "${ImageModel.idColumn} = ?", whereArgs: [imageId]);
  }

  Future<int> deleteLabel(int labelId) async {
    final db = await _database;
    return db.delete(LabelModel.TABLE_NAME,
        where: "${LabelModel.idColumn} = ?", whereArgs: [labelId]);
  }

  Future<int> insertLabel(LabelModel lm) async {
    try {
      final db = await _database;
      var result = await db.insert(LabelModel.TABLE_NAME, lm.toMap());
      return result;
    } on DatabaseException catch (de) {
      AppUtils.logMessage(
          AppUtils.yoLocalizations.db_class_insert_error(lm.name),
          de.toString(),
          "error");

      return -1;
    }
  }

  Future<int> insertImage(ImageModel im) async {
    try {
      final db = await _database;
      var result = await db.insert(ImageModel.TABLE_NAME, im.toMap());
      return result;
    } on DatabaseException catch (de) {
      AppUtils.logMessage(
          AppUtils.yoLocalizations.error_add_image, de.toString(), "error");
      return -1;
    }
  }

  Future<int> updateImage(ImageModel im) async {
    try {
      final db = await _database;
      var result = await db.update(ImageModel.TABLE_NAME, im.toMap(),
          where: "${ImageModel.idColumn} = ?", whereArgs: [im.id]);
      return result;
    } on DatabaseException catch (de) {
      AppUtils.logMessage(
          AppUtils.yoLocalizations.error_update_image, de.toString(), "error");

      return -1;
    }
  }

  Future<int> updateLabel(LabelModel lm) async {
    try {
      final db = await _database;
      var result = await db.update(LabelModel.TABLE_NAME, lm.toMap(),
          where: "${LabelModel.idColumn} = ?", whereArgs: [lm.id]);
      return result;
    } on DatabaseException catch (de) {
      AppUtils.logMessage(
          AppUtils.yoLocalizations.db_class_update_error(lm.name),
          de.toString(),
          "error");

      return -1;
    }
  }
}
