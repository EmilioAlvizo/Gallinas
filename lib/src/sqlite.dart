import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';

import 'comida.dart';
import 'gallinas.dart';
import 'huevos.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final Map<String, Database> _databases = {};

  DatabaseHelper._init();

  Future<Database> getDatabase(String userId) async {
    if (!_databases.containsKey(userId)) {
      final db = await _initDB('$userId.db');
      _databases[userId] = db;
    }
    return _databases[userId]!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) =>
          _onUpgrade(db, oldVersion, newVersion, filePath),
    );
  }

  Future _createDB(Database db, int version) async {
    // Aquí van las mismas sentencias CREATE TABLE que en ejemplos anteriores
    await db.execute('''
      CREATE TABLE sumas(
        id TEXT PRIMARY KEY,
        adquisicion REAL,
        ave TEXT,
        avesNuevas INTEGER,
        costo REAL,
        fecha TEXT,
        nombre TEXT,
        proposito TEXT
      )
    ''');
    await db.execute('''
CREATE TABLE restas(
  id TEXT PRIMARY KEY,
  ave TEXT,
  avesMuertas INTEGER,
  fecha TEXT,
  ingreso REAL,
  nombre TEXT,
  razon TEXT
)
''');

    await db.execute('''
CREATE TABLE sumasH(
  id TEXT PRIMARY KEY,
  ave TEXT,
  buenos INTEGER,
  fecha TEXT,
  nombre TEXT,
  rotos INTEGER
)
''');

    await db.execute('''
CREATE TABLE restasH(
  id TEXT PRIMARY KEY,
  ave TEXT,
  fecha TEXT,
  huevosMenos INTEGER,
  ingreso REAL,
  nombre TEXT,
  razon TEXT
)
''');

    await db.execute('''
CREATE TABLE sumasC(
  id TEXT PRIMARY KEY,
  ave TEXT,
  cantidad INTEGER,
  fecha TEXT,
  fechaTermino TEXT,
  nombre TEXT,
  precio REAL,
  precioUnitario REAL
)
''');
    // Agrega la nueva tabla sync_status
    await db.execute('''
      CREATE TABLE sync_status(
        id TEXT PRIMARY KEY,
        table_name TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(
      Database db, int oldVersion, int newVersion, String filePath) async {
    if (oldVersion < 2) {
      // Crear la nueva tabla sync_status si no existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_status(
          id TEXT PRIMARY KEY,
          table_name TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');

      // Llenar sync_status con datos existentes
      for (var table in ['sumas', 'restas', 'sumasH', 'restasH', 'sumasC']) {
        var rows = await db.query(table);
        for (var row in rows) {
          await db.insert('sync_status',
              {'id': row['id'], 'table_name': table, 'synced': 0},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }

  // Modifica los métodos de inserción y consulta para que acepten el userId
  Future<void> insertSuma(String userId, Map<String, dynamic> suma) async {
    final db = await getDatabase(userId);
    await db.insert('sumas', suma,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(
        'sync_status', {'id': suma['id'], 'table_name': 'sumas', 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertResta(String userId, Map<String, dynamic> resta) async {
    final db = await getDatabase(userId);
    await db.insert('restas', resta,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(
        'sync_status', {'id': resta['id'], 'table_name': 'restas', 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSumaH(String userId, Map<String, dynamic> sumaH) async {
    final db = await getDatabase(userId);
    await db.insert('sumasH', sumaH,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(
        'sync_status', {'id': sumaH['id'], 'table_name': 'sumasH', 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertRestaH(String userId, Map<String, dynamic> restaH) async {
    final db = await getDatabase(userId);
    await db.insert('restasH', restaH,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('sync_status',
        {'id': restaH['id'], 'table_name': 'restasH', 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSumaC(String userId, Map<String, dynamic> sumaC) async {
    final db = await getDatabase(userId);
    await db.insert('sumasC', sumaC,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(
        'sync_status', {'id': sumaC['id'], 'table_name': 'sumasC', 'synced': 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Metodo para obtener datos
  Future<List<Map<String, dynamic>>> getSumas(String userId) async {
    final db = await getDatabase(userId);
    return db.query('sumas');
  }

  Future<List<Map<String, dynamic>>> getRestas(String userId) async {
    final db = await getDatabase(userId);
    return db.query('restas');
  }

  Future<List<Map<String, dynamic>>> getSumasH(String userId) async {
    final db = await getDatabase(userId);
    return db.query('sumasH');
  }

  Future<List<Map<String, dynamic>>> getRestasH(String userId) async {
    final db = await getDatabase(userId);
    return db.query('restasH');
  }

  Future<List<Map<String, dynamic>>> getSumasC(String userId) async {
    final db = await getDatabase(userId);
    return db.query('sumasC');
  }

  Future<void> insertSumasBatch(
      String userId, List<Map<String, dynamic>> batch) async {
    final db = await getDatabase(userId);
    await db.transaction((txn) async {
      for (var data in batch) {
        await txn.insert(
          'sumas',
          {
            'id': data['id'],
            'adquisicion': data['adquisicion'],
            'ave': data['ave'],
            'avesNuevas': data['avesNuevas'],
            'costo': data['costo'],
            'fecha': data['fecha'],
            'nombre': data['nombre'],
            'proposito': data['proposito'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insertRestasBatch(
      String userId, List<Map<String, dynamic>> batch) async {
    final db = await getDatabase(userId);
    await db.transaction((txn) async {
      for (var data in batch) {
        await txn.insert(
          'restas',
          {
            'id': data['id'],
            'ave': data['ave'],
            'avesMuertas': data['avesMuertas'],
            'fecha': data['fecha'],
            'ingreso': data['ingreso'],
            'nombre': data['nombre'],
            'razon': data['razon'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insertSumasHBatch(
      String userId, List<Map<String, dynamic>> batch) async {
    final db = await getDatabase(userId);
    await db.transaction((txn) async {
      for (var data in batch) {
        await txn.insert(
          'sumasH',
          {
            'id': data['id'],
            'ave': data['ave'],
            'buenos': data['buenos'],
            'fecha': data['fecha'],
            'nombre': data['nombre'],
            'rotos': data['rotos'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insertRestasHBatch(
      String userId, List<Map<String, dynamic>> batch) async {
    final db = await getDatabase(userId);
    await db.transaction((txn) async {
      for (var data in batch) {
        await txn.insert(
          'restasH',
          {
            'id': data['id'],
            'ave': data['ave'],
            'fecha': data['fecha'],
            'huevosMenos': data['huevosMenos'],
            'ingreso': data['ingreso'],
            'nombre': data['nombre'],
            'razon': data['razon'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insertSumasCBatch(
      String userId, List<Map<String, dynamic>> batch) async {
    final db = await getDatabase(userId);
    await db.transaction((txn) async {
      for (var data in batch) {
        await txn.insert(
          'sumasC',
          {
            'id': data['id'],
            'ave': data['ave'],
            'cantidad': data['cantidad'],
            'fecha': data['fecha'],
            'fechaTermino': data['fechaTermino'],
            'nombre': data['nombre'],
            'precio': data['precio'],
            'precioUnitario': data['precioUnitario'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Map<String, Map<String, int>>> obtenerResumenSincronizacion(
      String userId) async {
    final db = await getDatabase(userId);
    final tablas = ['sumas', 'restas', 'sumasH', 'restasH', 'sumasC'];
    Map<String, Map<String, int>> resumen = {};

    for (var tabla in tablas) {
      int totalRegistros = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tabla')) ??
          0;
      int registrosSincronizados = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM sync_status WHERE table_name = ? AND synced = 1',
              [tabla])) ??
          0;
      int registrosNoSincronizados = totalRegistros - registrosSincronizados;

      resumen[tabla] = {
        'total': totalRegistros,
        'sincronizados': registrosSincronizados,
        'noSincronizados': registrosNoSincronizados,
      };
    }

    // Agregar un resumen total de todas las tablas
    int totalGeneral = 0;
    int sincronizadosGeneral = 0;
    int noSincronizadosGeneral = 0;

    resumen.values.forEach((resumenTabla) {
      totalGeneral += resumenTabla['total']!;
      sincronizadosGeneral += resumenTabla['sincronizados']!;
      noSincronizadosGeneral += resumenTabla['noSincronizados']!;
    });

    resumen['total'] = {
      'total': totalGeneral,
      'sincronizados': sincronizadosGeneral,
      'noSincronizados': noSincronizadosGeneral,
    };

    return resumen;
  }

  // Método para obtener datos no sincronizados
  Future<List<Map<String, dynamic>>> getDatosNoSincronizados(
      String userId, String nombreTabla) async {
    final db = await getDatabase(userId);
    final List<Map<String, dynamic>> unsyncedIds = await db.query('sync_status',
        where: 'table_name = ? AND synced = ?', whereArgs: [nombreTabla, 0]);

    return Future.wait(unsyncedIds.map((record) async {
      final data = await db
          .query(nombreTabla, where: 'id = ?', whereArgs: [record['id']]);
      return data.first;
    }));
  }

  // Método para actualizar el estado de sincronización
  Future<void> actualizarEstadoSincronizacion(
      String userId, String nombreTabla, String id) async {
    final db = await getDatabase(userId);
    await db.update('sync_status', {'synced': 1},
        where: 'id = ? AND table_name = ?', whereArgs: [id, nombreTabla]);
  }

  // Método para cerrar y eliminar una base de datos
  Future<void> deleteDatabase(String userId) async {
    if (_databases.containsKey(userId)) {
      await _databases[userId]!.close();
      _databases.remove(userId);
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, '$userId.db');
    await File(path).delete();
  }

  // Método para obtener la lista de usuarios con bases de datos
  Future<List<String>> getDatabaseUsers() async {
    final dbPath = await getDatabasesPath();
    final dir = Directory(dbPath);
    final List<FileSystemEntity> entities = await dir.list().toList();
    return entities
        .where((e) => e is File && e.path.endsWith('.db'))
        .map((e) => basename(e.path).split('.').first)
        .toList();
  }

  // ... (resto de los métodos de la clase)
}

// Función para iniciar la migración de todas las bases de datos de usuario
Future<void> initializeDatabases() async {
  final userIds = await DatabaseHelper.instance.getDatabaseUsers();
  for (var userId in userIds) {
    await DatabaseHelper.instance.getDatabase(userId);
  }
  print('Bases de datos de usuario inicializadas y migradas si era necesario');
}

/*class UserSession extends GetxController {
  static String? currentUserId;

  Rx<String?> usuarioSeleccionado = currentUserId.obs;

  UserSession() {
    // Agrega un observador al usuarioSeleccionado
    ever(usuarioSeleccionado, (String? userId) async {
      if (userId != null) {
        print('cambio user a $userId');
        await syncDataFromFirebase(userId);
      }
    });
  }

  static Future<void> initializeForCurrentUser(User? user) async {
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    currentUserId = user.uid;

    await DatabaseHelper.instance.getDatabase(currentUserId!);
  }

  static Future<void> logout() async {
    currentUserId = null;
  }
}*/

class UserSession extends GetxController {
  static String? currentUserId;
  final _storage = GetStorage();

  Rx<String?> usuarioSeleccionado = Rx<String?>(null);

  UserSession() {
    // Cargar el usuario guardado al iniciar
    usuarioSeleccionado.value = _storage.read('usuarioSeleccionado');
    // Agrega un observador al usuarioSeleccionado
    ever(usuarioSeleccionado, (String? userId) async {
      if (userId != null) {
        print('cambio user a $userId');
        await syncDataFromFirebase(userId);
        // Guardar el usuario seleccionado
        _storage.write('usuarioSeleccionado', userId);
      }
    });
  }

  static Future<void> initializeForCurrentUser(User? user) async {
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    currentUserId = user.uid;
    await DatabaseHelper.instance.getDatabase(currentUserId!);

    // Actualizar usuarioSeleccionado
    final userSession = Get.find<UserSession>();
    userSession.usuarioSeleccionado.value = currentUserId;
  }

  static Future<void> logout() async {
    currentUserId = null;
  }
}

Future<void> addNewUser(String userId) async {
  await DatabaseHelper.instance.getDatabase(userId);
  //await syncDataFromFirebase(userId);
}

//LIMPIAR BASE DE DATOS NO RELEVANTE
Future<void> cleanupDatabases(List<String> relevantUserIds) async {
  final dbHelper = DatabaseHelper.instance;
  final allUsers = await dbHelper.getDatabaseUsers();

  for (var userId in allUsers) {
    if (!relevantUserIds.contains(userId)) {
      await dbHelper.deleteDatabase(userId);
      print('Base de datos eliminada para el usuario no relevante: $userId');
    }
  }
}

Future<void> subirDatosConFirestore(String userId) async {
  final db = DatabaseHelper.instance;
  final firestore = FirebaseFirestore.instance;

  final tablas = ['sumas', 'restas', 'sumasH', 'restasH', 'sumasC'];

  for (var nombreTabla in tablas) {
    final datosNoSincronizados =
        await db.getDatosNoSincronizados(userId, nombreTabla);

    for (var datos in datosNoSincronizados) {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection(nombreTabla)
          .doc(datos['id']);
      await docRef.set(datos);
      await db.actualizarEstadoSincronizacion(userId, nombreTabla, datos['id']);
    }
  }
}

Future<void> syncDataFromFirebase(String userId) async {
  final firestore = FirebaseFirestore.instance;
  final db = DatabaseHelper.instance;

  // Lista de colecciones a sincronizar
  final collections = ['sumas', 'restas', 'sumasH', 'restasH', 'sumasC'];

  try {
    // Obtener todos los datos en paralelo
    List<QuerySnapshot> snapshots = await Future.wait(collections.map(
        (collection) => firestore
            .collection('users')
            .doc(userId)
            .collection(collection)
            .get()));

    // Procesar los resultados
    for (int i = 0; i < collections.length; i++) {
      String collection = collections[i];
      QuerySnapshot snapshot = snapshots[i];

      // Preparar los datos para inserción en lote
      List<Map<String, dynamic>> batchData = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        // Asegurarse de que el id del documento se incluya en los datos
        return {...data, 'id': doc.id};
      }).toList();

      // Insertar datos en lote
      switch (collection) {
        case 'sumas':
          await db.insertSumasBatch(userId, batchData);
          break;
        case 'restas':
          await db.insertRestasBatch(userId, batchData);
          break;
        case 'sumasH':
          await db.insertSumasHBatch(userId, batchData);
          break;
        case 'restasH':
          await db.insertRestasHBatch(userId, batchData);
          break;
        case 'sumasC':
          await db.insertSumasCBatch(userId, batchData);
          break;
      }
      // Actualizar el estado de sincronización en lote
      final syncStatusUpdates = batchData.map((data) =>
          db.actualizarEstadoSincronizacion(userId, collection, data['id']));
      await Future.wait(syncStatusUpdates);
    }

    print('Sincronización completada con éxito');
  } catch (e) {
    print('Error durante la sincronización: $e');
  }
}

/*Future<void> syncDataFromFirebase_original(String userId) async {
  final firestore = FirebaseFirestore.instance;
  final db = DatabaseHelper.instance;

  // Sync sumas
  final sumasSnapshot =
      await firestore.collection('users').doc(userId).collection('sumas').get();
  for (var doc in sumasSnapshot.docs) {
    await db.insertSuma(userId, doc.data());
  }

  // Sync restas
  final restasSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('restas')
      .get();
  for (var doc in restasSnapshot.docs) {
    await db.insertResta(userId, doc.data());
  }

  // Sync sumasH
  final sumasHSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('sumasH')
      .get();
  for (var doc in sumasHSnapshot.docs) {
    await db.insertSumaH(userId, doc.data());
  }

  // Sync restasH
  final restasHSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('restasH')
      .get();
  for (var doc in restasHSnapshot.docs) {
    await db.insertRestaH(userId, doc.data());
  }

  // Sync sumasC
  final sumasCSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('sumasC')
      .get();
  for (var doc in sumasCSnapshot.docs) {
    await db.insertSumaC(userId, doc.data());
  }
}*/

Future<void> syncData(dynamic object) async {
  final UserSession userSession = Get.find();
  final db = DatabaseHelper.instance;
  String userId = userSession.usuarioSeleccionado.value!;

  if (object is Suma) {
    await db.insertSuma(userId, object.toJson());
  } else if (object is Resta) {
    await db.insertResta(userId, object.toJson());
  } else if (object is SumaH) {
    await db.insertSumaH(userId, object.toJson());
  } else if (object is RestaH) {
    await db.insertRestaH(userId, object.toJson());
  } else if (object is SumaC) {
    await db.insertSumaC(userId, object.toJson());
  } else {
    throw ArgumentError('Tipo de objeto no soportado');
  }
}

Future<void> deleteObject(dynamic object) async {
  final UserSession userSession = Get.find();
  //final db = DatabaseHelper.instance;
  final String userId = userSession.usuarioSeleccionado.value!;
  final db = await DatabaseHelper.instance.getDatabase(userId);

  String tableName;
  String objectId;

  if (object is Suma) {
    tableName = 'sumas';
  } else if (object is Resta) {
    tableName = 'restas';
  } else if (object is SumaH) {
    tableName = 'sumasH';
  } else if (object is RestaH) {
    tableName = 'restasH';
  } else if (object is SumaC) {
    tableName = 'sumasC';
  } else {
    throw ArgumentError('Tipo de objeto no soportado');
  }

  objectId = object.id;

  await db.delete(tableName, where: 'id = ?', whereArgs: [objectId]);
}

/*Future<void> deleteObject2(String tableName,String objectId) async {
  final UserSession userSession = Get.find();
  //final db = DatabaseHelper.instance;
  final String userId = userSession.usuarioSeleccionado.value!;
  final db = await DatabaseHelper.instance.getDatabase(userId);

  await db.delete(tableName, where: 'id = ?', whereArgs: [objectId]);
}*/

class DatabaseViewer extends StatelessWidget {
  final String userId;

  DatabaseViewer({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Base de datos de $userId'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Sumas'),
              Tab(text: 'Restas'),
              Tab(text: 'SumasH'),
              Tab(text: 'RestasH'),
              Tab(text: 'SumasC'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTableView('sumas'),
            _buildTableView('restas'),
            _buildTableView('sumasH'),
            _buildTableView('restasH'),
            _buildTableView('sumasC'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(String tableName) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getData(tableName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay datos'));
        }

        List<Map<String, dynamic>> data = snapshot.data!;
        List<String> columns = data[0].keys.toList();

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: Text('Documento ${index + 1}'),
              children: [
                for (var column in columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('$column:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${data[index][column]}'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getData(String tableName) async {
    switch (tableName) {
      case 'sumas':
        return await DatabaseHelper.instance.getSumas(userId);
      case 'restas':
        return await DatabaseHelper.instance.getRestas(userId);
      case 'sumasH':
        return await DatabaseHelper.instance.getSumasH(userId);
      case 'restasH':
        return await DatabaseHelper.instance.getRestasH(userId);
      case 'sumasC':
        return await DatabaseHelper.instance.getSumasC(userId);
      default:
        throw Exception('Tabla no reconocida');
    }
  }
}
