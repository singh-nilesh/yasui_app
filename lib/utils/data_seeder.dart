import 'package:yasui_app/models/customer.dart';
import 'package:yasui_app/models/machinery.dart';
import 'package:yasui_app/models/maintenance.dart';
import 'package:yasui_app/services/database_service.dart';

class DataSeeder {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> seedDatabase() async {
    final customers = await _databaseService.getCustomers();
    
    // Only seed if database is empty
    if (customers.isEmpty) {
      print('Seeding database with initial data...');
      
      // Insert sample customers
      final sampleCustomers = _createSampleCustomers();
      final customerIds = <int>[];
      
      for (var customer in sampleCustomers) {
        final id = await _databaseService.insertCustomer(customer);
        customerIds.add(id);
        print('Created customer: ${customer.name} with ID: $id');
      }
      
      // Insert sample machinery for each customer
      final machineryIds = <int>[];
      for (int i = 0; i < customerIds.length; i++) {
        final customerId = customerIds[i];
        final machineries = _createSampleMachineryForCustomer(customerId);
        
        for (var machinery in machineries) {
          final id = await _databaseService.insertMachinery(machinery);
          machineryIds.add(id);
          print('Created machinery: ${machinery.name} for customer ID: $customerId');
        }
      }
      
      // Insert sample maintenance records for each machinery
      for (int machineryId in machineryIds) {
        final maintenances = _createSampleMaintenanceForMachinery(machineryId);
        
        for (var maintenance in maintenances) {
          final id = await _databaseService.insertMaintenance(maintenance);
          print('Created maintenance record with ID: $id for machinery ID: $machineryId');
        }
      }
      
      print('Database seeding completed successfully!');
    } else {
      print('Database already has data. Skipping seed operation.');
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
      ),
    ];
  }

  List<Machinery> _createSampleMachineryForCustomer(int customerId) {
    final today = DateTime.now();
    
    // Create 2 machinery items per customer with different installation dates and checkup intervals
    return [
      Machinery(
        customerId: customerId,
        name: 'Production Line ${customerId}A',
        serialNumber: 'SN-${customerId}001',
        installationDate: DateTime(today.year - 1, today.month, today.day),
        installationCost: 250000 + (customerId * 10000),
        checkupInterval: customerId % 2 == 0 ? 3 : 2,
      ),
      Machinery(
        customerId: customerId,
        name: 'Auxiliary System ${customerId}B',
        serialNumber: 'SN-${customerId}002',
        installationDate: DateTime(today.year - 2, today.month + 2, today.day - 5),
        installationCost: 120000 + (customerId * 5000),
        checkupInterval: customerId % 2 == 0 ? 6 : 3,
      ),
    ];
  }

  List<Maintenance> _createSampleMaintenanceForMachinery(int machineryId) {
    final today = DateTime.now();
    
    // Create several maintenance records for each machinery with different statuses
    return [
      // Completed maintenance (in the past)
      Maintenance(
        machineryId: machineryId,
        dueDate: DateTime(today.year, today.month - 2, today.day),
        nextMaintenanceDate: null,
        maintenanceType: 'Regular',
        status: MaintenanceStatus.completed,
        notes: 'Routine maintenance check completed on schedule.',
        completedDate: DateTime(today.year, today.month - 2, today.day + 1),
        issue: machineryId % 3 == 0 ? 'Minor calibration issues detected' : null,
        fix: machineryId % 3 == 0 ? 'Recalibrated and tested' : 'No issues found, regular maintenance performed',
        cost: machineryId % 3 == 0 ? 2500.0 : 1200.0,
      ),
      
      // Current/upcoming maintenance (due today or in near future)
      Maintenance(
        machineryId: machineryId,
        dueDate: DateTime(today.year, today.month, today.day + (machineryId % 5)),
        nextMaintenanceDate: null,
        maintenanceType: machineryId % 2 == 0 ? 'Regular' : 'Inspection',
        status: MaintenanceStatus.upcoming,
        notes: 'Scheduled maintenance check for ${machineryId % 2 == 0 ? 'regular servicing' : 'detailed inspection'}.',
      ),
      
      // Overdue maintenance (if machinery ID is odd)
      if (machineryId % 2 != 0)
        Maintenance(
          machineryId: machineryId,
          dueDate: DateTime(today.year, today.month, today.day - 10),
          nextMaintenanceDate: null,
          maintenanceType: 'Emergency',
          status: MaintenanceStatus.overdue,
          notes: 'Urgent maintenance required based on performance metrics.',
        ),
      
      // Future scheduled maintenance
      Maintenance(
        machineryId: machineryId,
        dueDate: DateTime(today.year, today.month + 2, today.day),
        nextMaintenanceDate: null,
        maintenanceType: machineryId % 3 == 0 ? 'Upgrade' : 'Regular',
        status: MaintenanceStatus.upcoming,
        notes: machineryId % 3 == 0 
            ? 'Scheduled firmware and component upgrade.' 
            : 'Regular maintenance as per schedule.',
      ),
    ];
  }
}