import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/machinery.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import '../models/maintenance.dart'; // Ensure this import points to the correct file where Maintenance is defined

class MachineryManagementScreen extends StatefulWidget {
  final Customer customer;

  const MachineryManagementScreen({super.key, required this.customer});

  @override
  _MachineryManagementScreenState createState() => _MachineryManagementScreenState();
}

class _MachineryManagementScreenState extends State<MachineryManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Machinery> _machinery = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachinery();
  }

  Future<void> _loadMachinery() async {
    setState(() {
      _isLoading = true;
    });
    
    final machinery = await _databaseService.getMachineryForCustomer(widget.customer.id!);
    
    setState(() {
      _machinery = machinery;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Machinery for ${widget.customer.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _machinery.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.build_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No machinery found for this customer',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Machinery'),
                          onPressed: () => _showAddMachineryDialog(context),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMachinery,
                  child: ListView.builder(
                    itemCount: _machinery.length,
                    itemBuilder: (context, index) {
                      final machinery = _machinery[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text(
                            machinery.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Serial Number: ${machinery.serialNumber}'),
                              Text(
                                'Installation Date: ${DateFormat('dd/MM/yyyy').format(machinery.installationDate)}',
                              ),
                              Text('Checkup Interval: ${machinery.checkupInterval} months'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditMachineryDialog(
                                  context,
                                  machinery,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmation(
                                  context,
                                  machinery,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigate to machinery details or maintenance history
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MachineryDetailScreen(
                                  machinery: machinery,
                                  customer: widget.customer,
                                ),
                              ),
                            ).then((_) => _loadMachinery());
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _machinery.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddMachineryDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddMachineryDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController serialNumberController = TextEditingController();
    DateTime installationDate = DateTime.now();
    final TextEditingController installationCostController =
        TextEditingController();
    int checkupInterval = 3; // Default to 3 months

    await showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to rebuild the dialog when state changes
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add New Machinery'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Machinery Name *',
                    ),
                  ),
                  TextField(
                    controller: serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number *',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Installation Date:'),
                  OutlinedButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: installationDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          installationDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(installationDate),
                    ),
                  ),
                  TextField(
                    controller: installationCostController,
                    decoration: const InputDecoration(
                      labelText: 'Installation Cost',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Checkup Interval *',
                    ),
                    value: checkupInterval,
                    items: [1, 2, 3, 6, 12].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value ${value == 1 ? 'month' : 'months'}'),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      checkupInterval = newValue!;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      serialNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                      ),
                    );
                    return;
                  }

                  final newMachinery = Machinery(
                    customerId: widget.customer.id!,
                    name: nameController.text.trim(),
                    serialNumber: serialNumberController.text.trim(),
                    installationDate: installationDate,
                    installationCost: installationCostController.text.isNotEmpty
                        ? double.tryParse(installationCostController.text)
                        : null,
                    checkupInterval: checkupInterval,
                  );

                  final machineryId = await _databaseService.insertMachinery(
                    newMachinery,
                  );
                  
                  // Create initial maintenance record
                  final initialMaintenance = Maintenance(
                    machineryId: machineryId,
                    dueDate: DateTime(
                      installationDate.year,
                      installationDate.month + checkupInterval,
                      installationDate.day,
                    ),
                    maintenanceType: 'Regular',
                    status: MaintenanceStatus.upcoming,
                    notes: 'Initial scheduled maintenance',
                  );
                  
                  await _databaseService.insertMaintenance(initialMaintenance);

                  Navigator.of(context).pop();
                  _loadMachinery();
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditMachineryDialog(
    BuildContext context,
    Machinery machinery,
  ) async {
    final TextEditingController nameController =
        TextEditingController(text: machinery.name);
    final TextEditingController serialNumberController =
        TextEditingController(text: machinery.serialNumber);
    DateTime installationDate = machinery.installationDate;
    final TextEditingController installationCostController =
        TextEditingController(
            text: machinery.installationCost?.toString() ?? '');
    int checkupInterval = machinery.checkupInterval;

    await showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to rebuild the dialog when state changes
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Machinery'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Machinery Name *',
                    ),
                  ),
                  TextField(
                    controller: serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number *',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Installation Date:'),
                  OutlinedButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: installationDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          installationDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(installationDate),
                    ),
                  ),
                  TextField(
                    controller: installationCostController,
                    decoration: const InputDecoration(
                      labelText: 'Installation Cost',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Checkup Interval *',
                    ),
                    value: checkupInterval,
                    items: [1, 2, 3, 6, 12].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value ${value == 1 ? 'month' : 'months'}'),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      checkupInterval = newValue!;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      serialNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                      ),
                    );
                    return;
                  }

                  final updatedMachinery = Machinery(
                    id: machinery.id,
                    customerId: machinery.customerId,
                    name: nameController.text.trim(),
                    serialNumber: serialNumberController.text.trim(),
                    installationDate: installationDate,
                    installationCost: installationCostController.text.isNotEmpty
                        ? double.tryParse(installationCostController.text)
                        : null,
                    checkupInterval: checkupInterval,
                  );

                  await _databaseService.updateMachinery(updatedMachinery);
                  Navigator.of(context).pop();
                  _loadMachinery();
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Machinery machinery,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${machinery.name}? It will be marked as deleted and won\'t appear in listings. All upcoming maintenance records will be removed, but historical maintenance data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              await _databaseService.markMachineryAsDeleted(machinery.id!);
              Navigator.of(context).pop();
              _loadMachinery();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class MachineryDetailScreen extends StatefulWidget {
  final Machinery machinery;
  final Customer customer;

  const MachineryDetailScreen({
    super.key,
    required this.machinery,
    required this.customer,
  });

  @override
  _MachineryDetailScreenState createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends State<MachineryDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _maintenanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRecords();
  }

  Future<void> _loadMaintenanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    final maintenances = await _databaseService.getMaintenanceForMachinery(widget.machinery.id!);
    List<Map<String, dynamic>> records = [];
    
    for (var maintenance in maintenances) {
      records.add({
        'maintenance': maintenance,
        'customer': widget.customer,
        'machinery': widget.machinery,
      });
    }
    
    setState(() {
      _maintenanceRecords = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machinery.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMaintenanceRecords,
              child: ListView(
                children: [
                  // Machinery info card (now scrollable with the rest of the content)
                  _buildMachineryInfoCard(),
                  const Divider(),
                  
                  // Header section with title and button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Maintenance History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Schedule'),
                          onPressed: () => _showScheduleMaintenanceDialog(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Maintenance records list
                  _maintenanceRecords.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No maintenance records found',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true, // Important to work inside another ListView
                          physics: const NeverScrollableScrollPhysics(), // Disable scrolling of this inner ListView
                          itemCount: _maintenanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _maintenanceRecords[index];
                            final maintenance = record['maintenance'] as Maintenance;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  'Due: ${DateFormat('dd/MM/yyyy').format(maintenance.dueDate)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(maintenance.status),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${maintenance.maintenanceType}'),
                                    Text('Status: ${maintenance.status.toString().split('.').last}'),
                                    if (maintenance.completedDate != null)
                                      Text(
                                        'Completed: ${DateFormat('dd/MM/yyyy').format(maintenance.completedDate!)}',
                                      ),
                                    if (maintenance.issue != null && maintenance.issue!.isNotEmpty)
                                      Text('Issue: ${maintenance.issue}'),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: Icon(
                                    maintenance.status == MaintenanceStatus.completed
                                        ? Icons.check_circle
                                        : Icons.build,
                                  ),
                                  onPressed: () {
                                    if (maintenance.status != MaintenanceStatus.completed) {
                                      _showCompleteMaintenanceDialog(context, maintenance);
                                    } else {
                                      _showMaintenanceDetails(context, maintenance);
                                    }
                                  },
                                ),
                                onTap: () => _showMaintenanceDetails(context, maintenance),
                              ),
                            );
                          },
                        ),
                  // Add some padding at the bottom
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMachineryInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.machinery.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Serial Number', widget.machinery.serialNumber),
            _buildInfoRow(
              'Installation Date',
              DateFormat('dd/MM/yyyy').format(widget.machinery.installationDate),
            ),
            _buildInfoRow(
              'Checkup Interval',
              '${widget.machinery.checkupInterval} ${widget.machinery.checkupInterval == 1 ? 'month' : 'months'}',
            ),
            if (widget.machinery.installationCost != null)
              _buildInfoRow(
                'Installation Cost',
                '\$${widget.machinery.installationCost!.toStringAsFixed(2)}',
              ),
            const Divider(),
            _buildInfoRow(
              'Customer Contact',
              widget.customer.contactPersonOwner,
            ),
            _buildInfoRow('Mobile', widget.customer.mobile),
            if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
              _buildInfoRow('Email', widget.customer.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.upcoming:
        return Colors.blue;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.overdue:
        return Colors.red;
      }
  }

  Future<void> _showCompleteMaintenanceDialog(
    BuildContext context,
    Maintenance maintenance,
  ) async {
    final TextEditingController issueController = TextEditingController();
    final TextEditingController fixController = TextEditingController();
    final TextEditingController costController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Maintenance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: issueController,
                decoration: const InputDecoration(
                  labelText: 'Issues Found',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: fixController,
                decoration: const InputDecoration(
                  labelText: 'Fixes Applied',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService.markMaintenanceAsDone(
                maintenance,
                issue: issueController.text.trim(),
                fix: fixController.text.trim(),
                cost: costController.text.isNotEmpty
                    ? double.tryParse(costController.text)
                    : null,
              );
              Navigator.of(context).pop();
              _loadMaintenanceRecords();
            },
            child: const Text('Mark as Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMaintenanceDetails(
    BuildContext context,
    Maintenance maintenance,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Maintenance Details',
          style: TextStyle(
            color: _getStatusColor(maintenance.status),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Due Date', DateFormat('dd/MM/yyyy').format(maintenance.dueDate)),
              _buildDetailRow('Type', maintenance.maintenanceType),
              _buildDetailRow('Status', maintenance.status.toString().split('.').last),
              if (maintenance.completedDate != null)
                _buildDetailRow(
                  'Completed',
                  DateFormat('dd/MM/yyyy').format(maintenance.completedDate!),
                ),
              if (maintenance.notes != null && maintenance.notes!.isNotEmpty)
                _buildDetailRow('Notes', maintenance.notes!),
              if (maintenance.issue != null && maintenance.issue!.isNotEmpty)
                _buildDetailRow('Issues Found', maintenance.issue!),
              if (maintenance.fix != null && maintenance.fix!.isNotEmpty)
                _buildDetailRow('Fixes Applied', maintenance.fix!),
              if (maintenance.cost != null)
                _buildDetailRow('Cost', '\$${maintenance.cost!.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (maintenance.status == MaintenanceStatus.completed)
            TextButton(
              onPressed: () async {
                await _databaseService.markMaintenanceAsUndone(maintenance);
                Navigator.of(context).pop();
                _loadMaintenanceRecords();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Mark as Incomplete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleMaintenanceDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final TextEditingController notesController = TextEditingController();
    String maintenanceType = 'Regular';

    await showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to rebuild the dialog when state changes
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Schedule Maintenance'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Due Date:'),
                  OutlinedButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Maintenance Type',
                    ),
                    value: maintenanceType,
                    items: ['Regular', 'Emergency', 'Inspection', 'Upgrade'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      maintenanceType = newValue!;
                    },
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newMaintenance = Maintenance(
                    machineryId: widget.machinery.id!,
                    dueDate: selectedDate,
                    maintenanceType: maintenanceType,
                    status: MaintenanceStatus.upcoming,
                    notes: notesController.text.trim(),
                  );

                  await _databaseService.insertMaintenance(newMaintenance);
                  Navigator.of(context).pop();
                  _loadMaintenanceRecords();
                },
                child: const Text('Schedule'),
              ),
            ],
          ),
        );
      },
    );
  }
}