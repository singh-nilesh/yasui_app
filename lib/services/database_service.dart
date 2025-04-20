import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/maintenance.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'yasui_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adding new columns for maintenance details
      await db.execute('ALTER TABLE maintenance ADD COLUMN issue TEXT');
      await db.execute('ALTER TABLE maintenance ADD COLUMN fix TEXT');
      await db.execute('ALTER TABLE maintenance ADD COLUMN cost REAL');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contactPersonOwner TEXT NOT NULL,
        contactPersonProductionManager TEXT,
        contactPersonTechnicalManager TEXT,
        address TEXT NOT NULL,
        pinCode TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        phone TEXT,
        mobile TEXT NOT NULL,
        email TEXT,
        locationCoords TEXT,
        checkupInterval TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        installationDate INTEGER NOT NULL,
        nextMaintenanceDate INTEGER NOT NULL,
        maintenanceType TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        completedDate INTEGER,
        issue TEXT,
        fix TEXT,
        cost REAL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  // Customer CRUD operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Maintenance CRUD operations
  Future<int> insertMaintenance(Maintenance maintenance) async {
    final db = await database;
    return await db.insert('maintenance', maintenance.toMap());
  }

  Future<List<Maintenance>> getAllMaintenance() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('maintenance');
    return List.generate(maps.length, (i) => Maintenance.fromMap(maps[i]));
  }

  Future<List<Maintenance>> getMaintenanceForCustomer(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'customerId = ?',
      whereArgs: [customerId],
    );
    return List.generate(maps.length, (i) => Maintenance.fromMap(maps[i]));
  }

  Future<List<Maintenance>> getMaintenanceByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'nextMaintenanceDate BETWEEN ? AND ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    return List.generate(maps.length, (i) => Maintenance.fromMap(maps[i]));
  }

  Future<int> updateMaintenance(Maintenance maintenance) async {
    final db = await database;
    return await db.update(
      'maintenance',
      maintenance.toMap(),
      where: 'id = ?',
      whereArgs: [maintenance.id],
    );
  }

  Future<int> deleteMaintenance(int id) async {
    final db = await database;
    return await db.delete(
      'maintenance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<DateTime, int>> getEventCountForMonth(DateTime month) async {
    final db = await database;
    
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'nextMaintenanceDate BETWEEN ? AND ?',
      whereArgs: [
        firstDay.millisecondsSinceEpoch,
        lastDay.millisecondsSinceEpoch
      ]
    );
    
    Map<DateTime, int> eventCounts = {};
    
    for (var map in maps) {
      final maintenance = Maintenance.fromMap(map);
      final date = DateTime(
        maintenance.nextMaintenanceDate.year,
        maintenance.nextMaintenanceDate.month,
        maintenance.nextMaintenanceDate.day,
      );
      
      if (eventCounts.containsKey(date)) {
        eventCounts[date] = eventCounts[date]! + 1;
      } else {
        eventCounts[date] = 1;
      }
    }
    
    return eventCounts;
  }

  // New method to mark maintenance as done and schedule next maintenance
  Future<Maintenance> markMaintenanceAsDone(
    Maintenance maintenance, {
    String? issue,
    String? fix,
    double? cost,
  }) async {
    // 1. Update the current maintenance record as completed
    final updatedMaintenance = maintenance.copyWith(
      status: MaintenanceStatus.completed,
      completedDate: DateTime.now(),
      issue: issue,
      fix: fix,
      cost: cost,
    );
    
    await updateMaintenance(updatedMaintenance);
    
    // 2. Calculate and create the next maintenance based on maintenanceType
    int monthsToAdd = maintenance.maintenanceType == '2-month' ? 2 : 6;
    
    final nextMaintenanceDate = DateTime(
      maintenance.nextMaintenanceDate.year,
      maintenance.nextMaintenanceDate.month + monthsToAdd, 
      maintenance.nextMaintenanceDate.day,
    );
    
    final nextMaintenance = Maintenance(
      customerId: maintenance.customerId,
      installationDate: maintenance.installationDate,
      nextMaintenanceDate: nextMaintenanceDate,
      maintenanceType: maintenance.maintenanceType,
      status: MaintenanceStatus.upcoming,
      notes: 'Scheduled follow-up maintenance',
    );
    
    await insertMaintenance(nextMaintenance);
    
    return updatedMaintenance;
  }
  
  // Method to mark a maintenance as undone (revert from completed to upcoming)
  Future<Maintenance> markMaintenanceAsUndone(Maintenance maintenance) async {
    final updatedMaintenance = maintenance.copyWith(
      status: MaintenanceStatus.upcoming,
      completedDate: null,
      issue: null,
      fix: null,
      cost: null,
    );
    
    await updateMaintenance(updatedMaintenance);
    
    // Find and delete the next scheduled maintenance if it exists
    final relatedMaintenances = await getMaintenanceForCustomer(maintenance.customerId);
    for (var m in relatedMaintenances) {
      // Find the next scheduled maintenance that was created when this one was marked as done
      // It will have the same maintenanceType and a date approximately 2 or 6 months later
      if (m.id != maintenance.id && 
          m.maintenanceType == maintenance.maintenanceType &&
          m.status == MaintenanceStatus.upcoming &&
          m.nextMaintenanceDate.isAfter(maintenance.nextMaintenanceDate)) {
        // Delete the future scheduled maintenance
        await deleteMaintenance(m.id!);
        break;
      }
    }
    
    return updatedMaintenance;
  }
}