import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_theme.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/maintenance.dart';
import '../models/customer.dart';
import '../models/machinery.dart'; // Ensure Machinery is imported
import '../widgets/maintenance_card.dart';
import '../widgets/upcomming_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  late Future<List<Map<String, dynamic>>> _todayMaintenanceFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _todayMaintenanceFuture = _getTodayMaintenanceWithCustomerInfo();
  }

  Future<List<Map<String, dynamic>>> _getTodayMaintenanceWithCustomerInfo() async {
    final today = DateTime.now();
    final List<Maintenance> maintenanceList = await _databaseService.getMaintenanceByDate(today);
    
    List<Map<String, dynamic>> result = [];
    
    for (var maintenance in maintenanceList) {
      // Get the machinery first since maintenance is now linked to machinery
      final machinery = await _databaseService.getMachinery(maintenance.machineryId);
      if (machinery != null) {
        // Then get the customer associated with that machinery
        final customer = await _databaseService.getCustomer(machinery.customerId);
        if (customer != null) {
          result.add({
            'maintenance': maintenance,
            'customer': customer,
            'machinery': machinery,
          });
        }
      }
    }
    
    return result;
  }
  
  Future<void> _showCompletionDialog(Maintenance maintenance) async {
    final TextEditingController issueController = TextEditingController();
    final TextEditingController fixController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Maintenance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record details for the maintenance completed on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: issueController,
                  decoration: const InputDecoration(
                    labelText: 'Issues Found',
                    border: OutlineInputBorder(),
                    hintText: 'Enter any issues discovered',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fixController,
                  decoration: const InputDecoration(
                    labelText: 'Fix Applied',
                    border: OutlineInputBorder(),
                    hintText: 'Enter the solution implemented',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                    hintText: 'Enter the cost if any',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                double? cost;
                if (costController.text.isNotEmpty) {
                  cost = double.tryParse(costController.text);
                }
                Navigator.of(context).pop({
                  'issue': issueController.text.isEmpty ? null : issueController.text,
                  'fix': fixController.text.isEmpty ? null : fixController.text,
                  'cost': cost,
                });
              },
              child: const Text('COMPLETE'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      await _databaseService.markMaintenanceAsDone(
        maintenance,
        issue: result['issue'],
        fix: result['fix'],
        cost: result['cost'],
      );
      
      setState(() {
        _refreshData();
      });
    }
  }
  
  Future<void> _deleteMaintenance(int maintenanceId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Maintenance'),
          content: const Text(
            'Are you sure you want to delete this maintenance record? This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (shouldDelete) {
      await _databaseService.deleteMaintenance(maintenanceId);
      
      setState(() {
        _refreshData();
      });
    }
  }

  void _openGoogleMaps(String? locationCoords) async {
    if (locationCoords == null || locationCoords.isEmpty) {
      // Show a snackbar message if coordinates are not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      // Parse the coordinates
      final parts = locationCoords.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        
        // Get the Google Maps URL from LocationService
        final url = _locationService.getGoogleMapsUrl(lat, lng);
        
        // Launch the URL
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Show error if unable to launch URL
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error if coordinates format is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid location coordinates format'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error if any exception occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening maps: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCustomerDetailsBottomSheet(Customer customer, Maintenance maintenance) {
    // Get the machinery from the job item
    final job = _todayMaintenanceFuture.then((jobs) {
      return jobs.firstWhere(
        (job) => 
          (job['maintenance'] as Maintenance).id == maintenance.id &&
          (job['customer'] as Customer).id == customer.id,
        orElse: () => {'machinery': null}
      );
    });
    
    job.then((foundJob) {
      UpcomingMaintenanceBottomSheet.show(
        context: context,
        customer: customer,
        maintenance: maintenance,
        machinery: foundJob['machinery'] as Machinery?,
        onMarkAsCompleted: _showCompletionDialog,
        onOpenMap: _openGoogleMaps,
      );
    });
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Maintenance'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _todayMaintenanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data: ${snapshot.error}',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }
          
          final maintenanceJobs = snapshot.data ?? [];
          
          if (maintenanceJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 72,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No maintenance scheduled for today',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Separate tasks into completed and remaining lists
          final completedTasks = maintenanceJobs.where(
            (job) => (job['maintenance'] as Maintenance).status == MaintenanceStatus.completed
          ).toList();
          
          final remainingTasks = maintenanceJobs.where(
            (job) => (job['maintenance'] as Maintenance).status != MaintenanceStatus.completed
          ).toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _refreshData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // Remaining tasks section
                if (remainingTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
                    child: Text(
                      'Remaining (${remainingTasks.length})',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...remainingTasks.map((job) => _buildMaintenanceItem(job)),
                  const SizedBox(height: 60), // Increased spacing from 16 to 32
                ],
                
                // Completed tasks section
                if (completedTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
                    child: Text(
                      'Completed (${completedTasks.length})',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.statusCompleted,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...completedTasks.map((job) => _buildMaintenanceItem(job)),
                  const SizedBox(height: 32), // Added 32px spacing after completed section
                ],
                
                // Add space at the bottom
                const SizedBox(height: 80), // Increased from 60 to 80
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMaintenanceItem(Map<String, dynamic> job) {
    final maintenance = job['maintenance'] as Maintenance;
    final customer = job['customer'] as Customer;
    
    final address = '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pinCode}';
    
    return Slidable(
      key: ValueKey(maintenance.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (maintenance.status != MaintenanceStatus.completed)
            SlidableAction(
              onPressed: (_) => _showCompletionDialog(maintenance),
              backgroundColor: AppColors.statusCompleted,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Mark as Done',
            ),
          SlidableAction(
            onPressed: (_) => _deleteMaintenance(maintenance.id!),
            backgroundColor: AppColors.statusOverdue,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: MaintenanceCard(
        customerName: customer.name,
        address: address,
        maintenanceDate: maintenance.nextMaintenanceDate ?? DateTime.now(),
        status: maintenance.status,
        maintenanceType: maintenance.maintenanceType,
        onTap: () {
          _showCustomerDetailsBottomSheet(customer, maintenance);
        },
      ),
    );
  }
}