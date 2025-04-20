import '../models/customer.dart';
import '../models/maintenance.dart';
import '../services/database_service.dart';

class DataSeeder {
  final DatabaseService _databaseService = DatabaseService();
  
  Future<void> seedData() async {
    // Check if data already exists
    final customers = await _databaseService.getCustomers();
    if (customers.isNotEmpty) {
      return; // Database already has data
    }
    
    // Seed sample customers
    final List<Customer> sampleCustomers = _createSampleCustomers();
    List<int> customerIds = [];
    
    for (var customer in sampleCustomers) {
      final id = await _databaseService.insertCustomer(customer);
      customerIds.add(id);
    }
    
    // Seed sample maintenance records
    final sampleMaintenances = _createSampleMaintenances(customerIds);
    
    for (var maintenance in sampleMaintenances) {
      await _databaseService.insertMaintenance(maintenance);
    }
  }
  
  List<Customer> _createSampleCustomers() {
    return [
      Customer(
        name: 'ABC Industries',
        contactPersonOwner: 'John Smith',
        contactPersonProductionManager: 'David Wilson',
        contactPersonTechnicalManager: 'Robert Johnson',
        address: '123 Industrial Avenue',
        pinCode: '400001',
        city: 'Mumbai',
        state: 'Maharashtra',
        phone: '022-27654321',
        mobile: '9876543210',
        email: 'info@abcindustries.com',
        locationCoords: '19.076090,72.877426',
        checkupInterval: '2-month',
      ),
      Customer(
        name: 'XYZ Manufacturing',
        contactPersonOwner: 'Alice Brown',
        contactPersonProductionManager: 'Sam Davis',
        contactPersonTechnicalManager: null,
        address: '456 Factory Road',
        pinCode: '411014',
        city: 'Pune',
        state: 'Maharashtra',
        phone: '020-67890123',
        mobile: '8765432109',
        email: 'contact@xyzmanufacturing.com',
        locationCoords: '18.520430,73.856743',
        checkupInterval: '6-month',
      ),
      Customer(
        name: 'Sunshine Textiles',
        contactPersonOwner: 'Raj Patel',
        contactPersonProductionManager: 'Amit Shah',
        contactPersonTechnicalManager: 'Vijay Kumar',
        address: '789 Cotton Street',
        pinCode: '380001',
        city: 'Ahmedabad',
        state: 'Gujarat',
        phone: '079-12345678',
        mobile: '7654321098',
        email: 'info@sunshinetextiles.in',
        locationCoords: '23.022505,72.571365',
        checkupInterval: '2-month',
      ),
      Customer(
        name: 'Global Electronics',
        contactPersonOwner: 'Priya Sharma',
        contactPersonProductionManager: null,
        contactPersonTechnicalManager: 'Ajay Verma',
        address: '234 Tech Park',
        pinCode: '560001',
        city: 'Bangalore',
        state: 'Karnataka',
        phone: '080-23456789',
        mobile: '9876123450',
        email: 'contact@globalelectronics.com',
        locationCoords: '12.971599,77.594563',
        checkupInterval: '6-month',
      ),
      Customer(
        name: 'Eastern Chemicals',
        contactPersonOwner: 'Arun Gupta',
        contactPersonProductionManager: 'Sanjay Mishra',
        contactPersonTechnicalManager: null,
        address: '567 Chemical Zone',
        pinCode: '700001',
        city: 'Kolkata',
        state: 'West Bengal',
        phone: '033-34567890',
        mobile: '8765123490',
        email: 'info@easternchemicals.com',
        locationCoords: '22.572646,88.363895',
        checkupInterval: '2-month',
      ),
    ];
  }
  
  List<Maintenance> _createSampleMaintenances(List<int> customerIds) {
    final today = DateTime.now();
    final List<Maintenance> maintenances = [];
    
    // Today's maintenance for first customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[0],
        installationDate: DateTime(today.year - 1, today.month, today.day),
        nextMaintenanceDate: today,
        maintenanceType: '2-month',
        status: MaintenanceStatus.upcoming,
        notes: 'Regular bi-monthly maintenance check.',
      ),
    );
    
    // Today's maintenance for third customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[2],
        installationDate: DateTime(today.year - 1, today.month - 6, today.day + 5),
        nextMaintenanceDate: today,
        maintenanceType: '2-month',
        status: MaintenanceStatus.upcoming,
        notes: 'Check textile machinery for calibration.',
      ),
    );
    
    // Upcoming maintenance for second customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[1],
        installationDate: DateTime(today.year - 2, today.month, today.day),
        nextMaintenanceDate: today.add(const Duration(days: 15)),
        maintenanceType: '6-month',
        status: MaintenanceStatus.upcoming,
        notes: 'Semi-annual comprehensive maintenance.',
      ),
    );
    
    // Upcoming maintenance for fourth customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[3],
        installationDate: DateTime(today.year - 1, today.month - 2, today.day),
        nextMaintenanceDate: today.add(const Duration(days: 7)),
        maintenanceType: '6-month',
        status: MaintenanceStatus.upcoming,
        notes: 'Check all electronic equipment and update firmware if necessary.',
      ),
    );
    
    // Overdue maintenance for fifth customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[4],
        installationDate: DateTime(today.year - 1, today.month - 8, today.day),
        nextMaintenanceDate: today.subtract(const Duration(days: 5)),
        maintenanceType: '2-month',
        status: MaintenanceStatus.overdue,
        notes: 'Critical safety check for chemical processing equipment.',
      ),
    );
    
    // Additional future maintenance for first customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[0],
        installationDate: DateTime(today.year - 1, today.month, today.day),
        nextMaintenanceDate: today.add(const Duration(days: 60)),
        maintenanceType: '2-month',
        status: MaintenanceStatus.upcoming,
        notes: 'Follow-up to today\'s maintenance.',
      ),
    );
    
    // Completed maintenance for second customer
    maintenances.add(
      Maintenance(
        customerId: customerIds[1],
        installationDate: DateTime(today.year - 2, today.month - 6, today.day),
        nextMaintenanceDate: today.subtract(const Duration(days: 30)),
        maintenanceType: '6-month',
        status: MaintenanceStatus.completed,
        completedDate: today.subtract(const Duration(days: 28)),
        notes: 'All systems working properly after maintenance.',
      ),
    );
    
    // More future maintenance records
    for (int i = 0; i < customerIds.length; i++) {
      maintenances.add(
        Maintenance(
          customerId: customerIds[i],
          installationDate: DateTime(today.year - 1, today.month, today.day - i),
          nextMaintenanceDate: today.add(Duration(days: 90 + (i * 15))),
          maintenanceType: i % 2 == 0 ? '2-month' : '6-month',
          status: MaintenanceStatus.upcoming,
          notes: 'Scheduled regular maintenance.',
        ),
      );
    }
    
    return maintenances;
  }
}