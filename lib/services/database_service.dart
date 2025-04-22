import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/machinery.dart';
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
      version: 3, // Incrementing version to handle schema update
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adding new columns for maintenance details from the previous version
      await db.execute('ALTER TABLE maintenance ADD COLUMN issue TEXT');
      await db.execute('ALTER TABLE maintenance ADD COLUMN fix TEXT');
      await db.execute('ALTER TABLE maintenance ADD COLUMN cost REAL');
    }
    
    if (oldVersion < 3) {
      // Upgrade to new schema with machinery table
      
      // Create a backup of customers
      await db.execute('CREATE TABLE customers_backup AS SELECT * FROM customers');
      
      // Create a backup of maintenance
      await db.execute('CREATE TABLE maintenance_backup AS SELECT * FROM maintenance');
      
      // Drop existing tables
      await db.execute('DROP TABLE IF EXISTS maintenance');
      await db.execute('DROP TABLE IF EXISTS customers');
      
      // Create new schema
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
          locationCoords TEXT
        )
      ''');
      
      // Create machinery table
      await db.execute('''
        CREATE TABLE machinery(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerId INTEGER NOT NULL,
          name TEXT NOT NULL,
          serialNumber TEXT NOT NULL,
          installationDate INTEGER NOT NULL,
          installationCost REAL,
          checkupInterval INTEGER NOT NULL,
          FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');
      
      // Create new maintenance table
      await db.execute('''
        CREATE TABLE maintenance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          machineryId INTEGER NOT NULL,
          dueDate INTEGER NOT NULL,
          nextMaintenanceDate INTEGER,
          maintenanceType TEXT NOT NULL,
          status TEXT NOT NULL,
          notes TEXT,
          completedDate INTEGER,
          issue TEXT,
          fix TEXT,
          cost REAL,
          createdAt INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
          FOREIGN KEY (machineryId) REFERENCES machinery (id) ON DELETE CASCADE
        )
      ''');
      
      // Restore customers data
      await db.execute('''
        INSERT INTO customers (
          id, name, contactPersonOwner, contactPersonProductionManager, 
          contactPersonTechnicalManager, address, pinCode, city, state, 
          phone, mobile, email, locationCoords
        )
        SELECT 
          id, name, contactPersonOwner, contactPersonProductionManager, 
          contactPersonTechnicalManager, address, pinCode, city, state, 
          phone, mobile, email, locationCoords
        FROM customers_backup
      ''');
      
      // Create machinery entries from customer data
      await db.execute('''
        INSERT INTO machinery (
          customerId, name, serialNumber, installationDate, checkupInterval
        )
        SELECT 
          id, 
          'Default Machinery', 
          'SN-' || id, 
          (SELECT IFNULL(MIN(installationDate), strftime('%s','now') * 1000) FROM maintenance_backup WHERE customerId = customers_backup.id), 
          CASE 
            WHEN checkupInterval = '2-month' THEN 2
            WHEN checkupInterval = '6-month' THEN 6
            WHEN checkupInterval = '1-month' THEN 1
            ELSE 3
          END
        FROM customers_backup
      ''');
      
      // Migrate maintenance data
      final List<Map<String, dynamic>> machineries = await db.query('machinery');
      for (var machinery in machineries) {
        int customerId = machinery['customerId'];
        int machineryId = machinery['id'];
        
        // Get all maintenances for this customer
        final List<Map<String, dynamic>> maintenances = await db.query(
          'maintenance_backup',
          where: 'customerId = ?',
          whereArgs: [customerId]
        );
        
        // Insert them linked to the new machinery
        for (var maintenance in maintenances) {
          await db.insert('maintenance', {
            'machineryId': machineryId,
            'dueDate': maintenance['nextMaintenanceDate'],
            'nextMaintenanceDate': maintenance['nextMaintenanceDate'],
            'maintenanceType': maintenance['maintenanceType'],
            'status': maintenance['status'],
            'notes': maintenance['notes'],
            'completedDate': maintenance['completedDate'],
            'issue': maintenance['issue'],
            'fix': maintenance['fix'],
            'cost': maintenance['cost'],
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
      
      // Drop backup tables
      await db.execute('DROP TABLE customers_backup');
      await db.execute('DROP TABLE maintenance_backup');
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
        locationCoords TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE machinery(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        name TEXT NOT NULL,
        serialNumber TEXT NOT NULL,
        installationDate INTEGER NOT NULL,
        installationCost REAL,
        checkupInterval INTEGER NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machineryId INTEGER NOT NULL,
        dueDate INTEGER NOT NULL,
        nextMaintenanceDate INTEGER,
        maintenanceType TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        completedDate INTEGER,
        issue TEXT,
        fix TEXT,
        cost REAL,
        createdAt INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        FOREIGN KEY (machineryId) REFERENCES machinery (id) ON DELETE CASCADE
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

  // Machinery CRUD operations
  Future<int> insertMachinery(Machinery machinery) async {
    final db = await database;
    return await db.insert('machinery', machinery.toMap());
  }

  Future<List<Machinery>> getMachineryForCustomer(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'machinery',
      where: 'customerId = ?',
      whereArgs: [customerId],
    );
    return List.generate(maps.length, (i) => Machinery.fromMap(maps[i]));
  }

  Future<Machinery?> getMachinery(int id) async {
    final db = await database;
    final maps = await db.query(
      'machinery',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Machinery.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Machinery>> getAllMachinery() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('machinery');
    return List.generate(maps.length, (i) => Machinery.fromMap(maps[i]));
  }

  Future<int> updateMachinery(Machinery machinery) async {
    final db = await database;
    return await db.update(
      'machinery',
      machinery.toMap(),
      where: 'id = ?',
      whereArgs: [machinery.id],
    );
  }

  Future<int> deleteMachinery(int id) async {
    final db = await database;
    return await db.delete(
      'machinery',
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

  Future<List<Maintenance>> getMaintenanceForMachinery(int machineryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'machineryId = ?',
      whereArgs: [machineryId],
    );

    // Debugging: Log the fetched maintenance records
    print('Fetched maintenance records for machineryId $machineryId: $maps');

    return List.generate(maps.length, (i) => Maintenance.fromMap(maps[i]));
  }

  Future<List<Maintenance>> getMaintenanceByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'dueDate BETWEEN ? AND ?',
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
      where: 'dueDate BETWEEN ? AND ?',
      whereArgs: [
        firstDay.millisecondsSinceEpoch,
        lastDay.millisecondsSinceEpoch
      ]
    );
    
    Map<DateTime, int> eventCounts = {};
    
    for (var map in maps) {
      final maintenance = Maintenance.fromMap(map);
      final date = DateTime(
        maintenance.dueDate.year,
        maintenance.dueDate.month,
        maintenance.dueDate.day,
      );
      
      if (eventCounts.containsKey(date)) {
        eventCounts[date] = eventCounts[date]! + 1;
      } else {
        eventCounts[date] = 1;
      }
    }
    
    return eventCounts;
  }

  // Method to mark maintenance as done and schedule next maintenance
  Future<Maintenance> markMaintenanceAsDone(
    Maintenance maintenance, {
    String? issue,
    String? fix,
    double? cost,
  }) async {
    // 1. Get the machinery to determine the checkupInterval
    final machinery = await getMachinery(maintenance.machineryId);
    if (machinery == null) {
      throw Exception('Machinery not found');
    }
    
    // 2. Update the current maintenance record as completed
    final updatedMaintenance = maintenance.copyWith(
      status: MaintenanceStatus.completed,
      completedDate: DateTime.now(),
      issue: issue,
      fix: fix,
      cost: cost,
    );
    
    await updateMaintenance(updatedMaintenance);
    
    // 3. Calculate and create the next maintenance based on machinery's checkupInterval
    final nextDueDate = DateTime(
      maintenance.dueDate.year,
      maintenance.dueDate.month + machinery.checkupInterval, 
      maintenance.dueDate.day,
    );
    
    final nextMaintenance = Maintenance(
      machineryId: maintenance.machineryId,
      dueDate: nextDueDate,
      nextMaintenanceDate: null,
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
    final relatedMaintenances = await getMaintenanceForMachinery(maintenance.machineryId);
    for (var m in relatedMaintenances) {
      // Find the next scheduled maintenance that was created when this one was marked as done
      if (m.id != maintenance.id && 
          m.maintenanceType == maintenance.maintenanceType &&
          m.status == MaintenanceStatus.upcoming &&
          m.dueDate.isAfter(maintenance.dueDate)) {
        // Delete the future scheduled maintenance
        await deleteMaintenance(m.id!);
        break;
      }
    }
    
    return updatedMaintenance;
  }

  // Helper methods for joined queries
  
  // Get all maintenance with customer and machinery details
  Future<List<Map<String, dynamic>>> getMaintenanceWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.*, 
        ma.name as machineryName, 
        ma.serialNumber,
        c.name as customerName,
        c.mobile as customerMobile
      FROM maintenance m
      JOIN machinery ma ON m.machineryId = ma.id
      JOIN customers c ON ma.customerId = c.id
      ORDER BY m.dueDate
    ''');
  }
  
  // Get upcoming maintenance with details
  Future<List<Map<String, dynamic>>> getUpcomingMaintenanceWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.*, 
        ma.name as machineryName, 
        ma.serialNumber,
        c.name as customerName,
        c.mobile as customerMobile
      FROM maintenance m
      JOIN machinery ma ON m.machineryId = ma.id
      JOIN customers c ON ma.customerId = c.id
      WHERE m.status = 'upcoming'
      ORDER BY m.dueDate
    ''');
  }
  
  // Get maintenance history for a customer
  Future<List<Map<String, dynamic>>> getMaintenanceHistoryForCustomer(int customerId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.*, 
        ma.name as machineryName, 
        ma.serialNumber
      FROM maintenance m
      JOIN machinery ma ON m.machineryId = ma.id
      WHERE ma.customerId = ?
      ORDER BY m.completedDate DESC, m.dueDate DESC
    ''', [customerId]);
  }
  
  // Get maintenance details for a specific date including customer and machinery info
  Future<List<Map<String, dynamic>>> getMaintenanceDetailsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await database;
    final maintenanceData = await db.rawQuery('''
      SELECT 
        m.*, 
        ma.name as machineryName, 
        ma.serialNumber,
        ma.checkupInterval,
        c.id as customerId,
        c.name as customerName,
        c.mobile as customerMobile,
        c.address,
        c.city,
        c.state,
        c.pinCode,
        c.locationCoords
      FROM maintenance m
      JOIN machinery ma ON m.machineryId = ma.id
      JOIN customers c ON ma.customerId = c.id
      WHERE m.dueDate BETWEEN ? AND ?
      ORDER BY m.dueDate
    ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);
    
    // Convert raw data to structured data
    return maintenanceData.map((item) {
      // Create a maintenance object from the maintenance fields
      final maintenanceFields = Map<String, dynamic>.from(item)
        ..removeWhere((key, value) => 
          key == 'machineryName' || 
          key == 'serialNumber' || 
          key == 'checkupInterval' ||
          key == 'customerId' || 
          key == 'customerName' || 
          key == 'customerMobile' ||
          key == 'address' ||
          key == 'city' ||
          key == 'state' ||
          key == 'pinCode' ||
          key == 'locationCoords');
      
      // Create a customer object with limited fields
      final customer = Customer(
        id: item['customerId'] as int,
        name: item['customerName'] as String,
        contactPersonOwner: '', // Not needed for display
        address: item['address'] as String,
        pinCode: item['pinCode'] as String,
        city: item['city'] as String,
        state: item['state'] as String,
        mobile: item['customerMobile'] as String,
        locationCoords: item['locationCoords'] as String?,
      );
      
      // Create a machinery object with limited fields
      final machinery = Machinery(
        id: item['machineryId'] as int,
        customerId: item['customerId'] as int,
        name: item['machineryName'] as String,
        serialNumber: item['serialNumber'] as String,
        installationDate: DateTime.now(), // Not needed for display
        checkupInterval: item['checkupInterval'] as int,
      );

      return {
        'maintenance': Maintenance.fromMap(maintenanceFields),
        'customer': customer,
        'machinery': machinery,
      };
    }).toList();
  }

  // DB Inspector methods
  Future<Map<String, List<Map<String, dynamic>>>> getAllRecords() async {
    final db = await database;
    Map<String, List<Map<String, dynamic>>> allRecords = {};
    
    // Get all customers
    allRecords['customers'] = await db.query('customers');
    
    // Get all machinery
    allRecords['machinery'] = await db.query('machinery');
    
    // Get all maintenance
    allRecords['maintenance'] = await db.query('maintenance');
    
    return allRecords;
  }

  Future<List<String>> getAllTables() async {
    final db = await database;
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    return tables.map((table) => table['name'] as String).toList();
  }
}