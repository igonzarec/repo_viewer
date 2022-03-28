import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class SembastDatabase {
  late Database _instance; //this says: hey this object is not nullable but
  //initially it is not going to contain any value. But as soon as it gets
  //a value, treat it as a not nullable field.

  Database get instance => _instance;

  bool _hasBeenInitialized = false;

  Future<void> init() async {
    if(_hasBeenInitialized){
      return;
    }
    _hasBeenInitialized = true;
    //specify database directory and file
    //we need to get the path to the persistent directory
    final dbDirectory =
        await getApplicationDocumentsDirectory(); //this points to the proper directory for the operating system which can store data persistently.
    dbDirectory.create(
        recursive:
            true); //if we have a directory that not exists, all the paths of the directory will be created. This does not destroys data.

    final dbPath = join(dbDirectory.path, 'db.sembast');

    _instance = await databaseFactoryIo.openDatabase(
        dbPath); //we want to use input output. Useful to store data persistently.
  }
}
