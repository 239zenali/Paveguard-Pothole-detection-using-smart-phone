import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class CsvHelper {
  /// rows: list of rows, each row a list of dynamic values
  static Future<String> saveCsv(
    List<List<dynamic>> rows,
    String filenameWithoutExt,
  ) async {
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filenameWithoutExt.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}
