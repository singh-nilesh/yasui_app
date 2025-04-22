import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/machinery.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import 'machinery_management_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  late TabController _tabController;
  late Future<List<Machinery>> _machineryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Updated to 2 tabs
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _loadMaintenances();
    _loadMachinery();
  }

  void _loadMaintenances() {
  }

  void _loadMachinery() {
    _machineryFuture = _databaseService.getMachineryForCustomer(widget.customer.id!);
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
  
  void _navigateToMachineryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MachineryManagementScreen(
          customer: widget.customer,
        ),
      ),
    ).then((_) => setState(() {
      _loadData();
    }));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'N/A') return;
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildCustomerInfo(),
          Expanded(
            child: DefaultTabController(
              length: 2, // Updated to 2 tabs
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryColor,
                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Machinery'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(),
                        _buildMachineryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final address = '${widget.customer.address}, ${widget.customer.city}, ${widget.customer.state} - ${widget.customer.pinCode}';
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer.name,
              style: AppTextStyles.heading2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                if (widget.customer.locationCoords != null && 
                    widget.customer.locationCoords!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.map, color: AppColors.accentColor),
                    onPressed: () => _openGoogleMaps(widget.customer.locationCoords),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Contact Information'),
          _buildContactItem('Owner', widget.customer.contactPersonOwner, widget.customer.mobile),
          if (widget.customer.contactPersonProductionManager != null)
            _buildContactItem(
              'Production Manager', 
              widget.customer.contactPersonProductionManager!, 
              widget.customer.phone ?? 'N/A'
            ),
          if (widget.customer.contactPersonTechnicalManager != null)
            _buildContactItem(
              'Technical Manager', 
              widget.customer.contactPersonTechnicalManager!, 
              'N/A'
            ),
          if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
            _buildInfoRow(Icons.email, 'Email', widget.customer.email!),
          const SizedBox(height: 24),
          _buildSectionTitle('Address Information'),
          _buildInfoRow(Icons.home, 'Address', widget.customer.address),
          _buildInfoRow(Icons.location_city, 'City', widget.customer.city),
          _buildInfoRow(Icons.map, 'State', widget.customer.state),
          _buildInfoRow(Icons.pin_drop, 'Pin Code', widget.customer.pinCode),
          const SizedBox(height: 24),
          _buildSectionTitle('Machinery Information'),
          ElevatedButton.icon(
            onPressed: _navigateToMachineryManagement,
            icon: const Icon(Icons.build),
            label: const Text('Manage Machinery & Maintenance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
              minimumSize: const Size(double.maxFinite, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineryTab() {
    return FutureBuilder<List<Machinery>>(
      future: _machineryFuture,
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
        
        final machinery = snapshot.data ?? [];
        
        if (machinery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No machinery found for this customer',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToMachineryManagement,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Machinery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: machinery.length,
          itemBuilder: (context, index) {
            final machine = machinery[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: Icon(Icons.precision_manufacturing, color: Colors.white),
                ),
                title: Text(
                  machine.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serial: ${machine.serialNumber}'),
                    Text(
                      'Installed: ${DateFormat('MMM dd, yyyy').format(machine.installationDate)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Maintenance Interval: ${machine.checkupInterval} ${machine.checkupInterval == 1 ? 'month' : 'months'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MachineryDetailScreen(
                          machinery: machine,
                          customer: widget.customer,
                        ),
                      ),
                    ).then((_) => setState(() {
                      _loadData();
                    }));
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MachineryDetailScreen(
                        machinery: machine,
                        customer: widget.customer,
                      ),
                    ),
                  ).then((_) => setState(() {
                    _loadData();
                  }));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.heading3,
      ),
    );
  }
  
  Widget _buildContactItem(String title, String name, String contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    name,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (contact != 'N/A') Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentColor,
                        ),
                      ),
                    ],
                  ) else Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.call, 
                color: contact != 'N/A' ? AppColors.primaryColor : AppColors.textSecondary.withOpacity(0.5),
              ),
              onPressed: () => _makePhoneCall(contact),
              tooltip: contact != 'N/A' ? 'Call $contact' : null,
              disabledColor: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}