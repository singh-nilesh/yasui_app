import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_theme.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/maintenance.dart';
import '../models/customer.dart';
import '../models/machinery.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, int> _eventCounts = {};
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadMaintenanceForSelectedDay();
  }

  Future<void> _loadEvents() async {
    final events = await _databaseService.getEventCountForMonth(_focusedDay);
    setState(() {
      _eventCounts = events;
    });
  }

  void _loadMaintenanceForSelectedDay() {
    _maintenanceFuture = _databaseService.getMaintenanceDetailsForDate(_selectedDay);
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
        _loadMaintenanceForSelectedDay();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(42), // Reduced from default 56
        child: AppBar(
          title: const Text(
            'Maintenance Calendar',
            style: TextStyle(fontSize: 16), // Smaller title text
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildCalendar(),
            const Divider(height: 1),
            _buildMaintenanceListNonScrollable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), // Increased horizontal padding
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95, // Making it slightly smaller than screen width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month, // Always month format
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return List.generate(_eventCounts[normalizedDay] ?? 0, (index) => index);
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _loadMaintenanceForSelectedDay();
            });
          },
          onFormatChanged: (format) {
            setState(() {
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _loadEvents();
            });
          },
          
          // Remove most default styling since we're using a completely custom cell builder
          calendarStyle: const CalendarStyle(
            // Remove default decorations since we're handling them in the builders
            defaultDecoration: BoxDecoration(),
            weekendDecoration: BoxDecoration(),
            selectedDecoration: BoxDecoration(),
            todayDecoration: BoxDecoration(),
            outsideDecoration: BoxDecoration(),
            
            // Text styles still used for default dates
            weekendTextStyle: TextStyle(color: Colors.red),
            outsideTextStyle: TextStyle(color: Colors.grey),
            
            // Remove default markers since we're using custom builders
            markersAutoAligned: false,
            markersMaxCount: 0,
            markersAnchor: 0.5,
          ),
          
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: AppTextStyles.heading3.copyWith(
              fontSize: 14, // Reduced from 16 to 14
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primaryColor, size: 20), // Smaller icon size
            rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primaryColor, size: 20), // Smaller icon size
            headerPadding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced from 10.0 to 6.0
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
          
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            weekendStyle: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            ),
          ),
          
          // Making the calendar more compact but with enough space for the grid cells
          rowHeight: 45, // Reduced from 60 to 45 for month format
          daysOfWeekHeight: 20, // Also reduced from 25 to 20
          
          // Custom builders for creating the grid and boundary boxes
          calendarBuilders: CalendarBuilders(
            // Custom builder for each date cell
            defaultBuilder: (context, day, focusedDay) {
              return _buildDateCell(day, false, false, false);
            },
            
            // Builder for the selected day
            selectedBuilder: (context, day, focusedDay) {
              return _buildDateCell(day, day.weekday >= 6, true, false);
            },
            
            // Builder for today
            todayBuilder: (context, day, focusedDay) {
              return _buildDateCell(day, day.weekday >= 6, false, true);
            },
            
            // Builder for dates outside the current month
            outsideBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
            
            // Custom marker builder for showing event counts
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                final count = events.length;
                return Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
  
  // Helper method to build a calendar date cell with proper grid styling
  Widget _buildDateCell(DateTime day, bool isWeekend, bool isSelected, bool isToday) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primaryColor.withOpacity(0.2)
            : isToday 
                ? AppColors.accentColor.withOpacity(0.15)
                : Colors.white,
        border: Border.all(
          color: isSelected 
              ? AppColors.primaryColor 
              : isToday 
                  ? AppColors.accentColor
                  : Colors.grey.withOpacity(0.3),
          width: isSelected || isToday ? 1.0 : 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Date number in top-left
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected 
                    ? AppColors.primaryColor
                    : isToday 
                        ? AppColors.accentColor
                        : isWeekend 
                            ? Colors.red 
                            : Colors.black87,
                fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceListNonScrollable() {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced from 12 to 8
          width: double.infinity,
          color: AppColors.backgroundColor,
          child: Text(
            formattedDate,
            style: AppTextStyles.heading3.copyWith(fontSize: 14), // Added smaller font size
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _maintenanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error loading data: ${snapshot.error}',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              );
            }
            
            final maintenanceJobs = snapshot.data ?? [];
            
            if (maintenanceJobs.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No maintenance scheduled',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
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
            
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(height: 32), // Increased spacing from 16 to 32
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildMaintenanceItem(Map<String, dynamic> job) {
    final maintenance = job['maintenance'] as Maintenance;
    final customer = job['customer'] as Customer;
    final machinery = job['machinery'] as Machinery;
    
    final address = '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pinCode}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showMaintenanceDetails(job),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(maintenance.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(maintenance.status),
                      color: _getStatusColor(maintenance.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          machinery.name,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'S/N: ${machinery.serialNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(maintenance.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          maintenance.status.toString().split('.').last,
                          style: TextStyle(
                            color: _getStatusColor(maintenance.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(maintenance.dueDate),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Removed the buttons row with View Machine and Complete options
            ],
          ),
        ),
      ),
    );
  }

  void _showMaintenanceDetails(Map<String, dynamic> job) {
    final maintenance = job['maintenance'] as Maintenance;
    final customer = job['customer'] as Customer;
    final machinery = job['machinery'] as Machinery;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Maintenance Details',
                      style: AppTextStyles.heading3,
                    ),
                  ),
                  Row(
                    children: [
                      if (customer.locationCoords != null && customer.locationCoords!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.map, color: AppColors.accentColor),
                          onPressed: () => _openGoogleMaps(customer.locationCoords),
                          tooltip: 'Open in Maps',
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              // Customer & Machine info
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Address section added here
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  customer.address,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${customer.city}, ${customer.state} - ${customer.pinCode}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.build, color: AppColors.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  machinery.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Serial: ${machinery.serialNumber}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Maintenance Interval: ${machinery.checkupInterval} ${machinery.checkupInterval == 1 ? 'month' : 'months'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Maintenance Details
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.event,
                        'Due Date',
                        DateFormat('MMMM d, yyyy').format(maintenance.dueDate),
                      ),
                      _buildDetailRow(
                        _getStatusIcon(maintenance.status),
                        'Status',
                        maintenance.status.toString().split('.').last,
                        valueColor: _getStatusColor(maintenance.status),
                      ),
                      _buildDetailRow(
                        Icons.category,
                        'Type',
                        maintenance.maintenanceType,
                      ),
                      if (maintenance.notes != null && maintenance.notes!.isNotEmpty)
                        _buildDetailRow(
                          Icons.note,
                          'Notes',
                          maintenance.notes!,
                        ),
                      if (maintenance.completedDate != null)
                        _buildDetailRow(
                          Icons.check_circle,
                          'Completed On',
                          DateFormat('MMMM d, yyyy').format(maintenance.completedDate!),
                        ),
                      if (maintenance.issue != null && maintenance.issue!.isNotEmpty)
                        _buildDetailRow(
                          Icons.warning,
                          'Issues Found',
                          maintenance.issue!,
                        ),
                      if (maintenance.fix != null && maintenance.fix!.isNotEmpty)
                        _buildDetailRow(
                          Icons.build,
                          'Fix Applied',
                          maintenance.fix!,
                        ),
                      if (maintenance.cost != null)
                        _buildDetailRow(
                          Icons.attach_money,
                          'Cost',
                          '₹${maintenance.cost!.toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (maintenance.status != MaintenanceStatus.completed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Completed'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCompletionDialog(maintenance);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.upcoming:
        return AppColors.statusUpcoming;
      case MaintenanceStatus.completed:
        return AppColors.statusCompleted;
      case MaintenanceStatus.overdue:
        return AppColors.statusOverdue;
    }
  }

  IconData _getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.upcoming:
        return Icons.pending;
      case MaintenanceStatus.completed:
        return Icons.check_circle;
      case MaintenanceStatus.overdue:
        return Icons.warning;
    }
  }
}