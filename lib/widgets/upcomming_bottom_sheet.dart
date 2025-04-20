// This file contains the implementation for upcoming maintenance bottom sheet
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/maintenance.dart';

class UpcomingMaintenanceBottomSheet extends StatelessWidget {
  final Customer customer;
  final Maintenance maintenance;
  final Function(Maintenance) onMarkAsCompleted;
  final Function(String?) onOpenMap;

  const UpcomingMaintenanceBottomSheet({
    super.key,
    required this.customer,
    required this.maintenance,
    required this.onMarkAsCompleted,
    required this.onOpenMap,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
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
    final address = '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pinCode}';
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        customer.name,
                        style: AppTextStyles.heading2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Address',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Button to open in maps
                    OutlinedButton.icon(
                      onPressed: () => onOpenMap(customer.locationCoords),
                      icon: const Icon(
                        Icons.map,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      label: const Text(
                        'View Map',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Contacts',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildContactItem(
                  'Owner', 
                  customer.contactPersonOwner,
                  customer.mobile,
                ),
                if (customer.contactPersonProductionManager != null &&
                    customer.contactPersonProductionManager!.isNotEmpty)
                  _buildContactItem(
                    'Production Manager',
                    customer.contactPersonProductionManager!,
                    customer.phone ?? '',
                  ),
                if (customer.contactPersonTechnicalManager != null &&
                    customer.contactPersonTechnicalManager!.isNotEmpty)
                  _buildContactItem(
                    'Technical Manager',
                    customer.contactPersonTechnicalManager!,
                    '',
                  ),
                const SizedBox(height: 16),
                Text(
                  'Maintenance Details',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.build,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Type: ${maintenance.maintenanceType}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.event,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Maintenance: ${_formatDate(maintenance.nextMaintenanceDate)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Installation Date: ${_formatDate(maintenance.installationDate)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                
                if (maintenance.notes != null && maintenance.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes: ${maintenance.notes}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (maintenance.status == MaintenanceStatus.completed) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Completion Details',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  if (maintenance.completedDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed On: ${_formatDate(maintenance.completedDate!)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    
                  if (maintenance.issue != null && maintenance.issue!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Issue Found: ${maintenance.issue}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (maintenance.fix != null && maintenance.fix!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.build_circle,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fix Applied: ${maintenance.fix}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (maintenance.cost != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cost: ₹${maintenance.cost!.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ],
                
                const SizedBox(height: 16),
                if (maintenance.status != MaintenanceStatus.completed)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onMarkAsCompleted(maintenance);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.medium,
                      ),
                    ),
                    child: const Text(
                      'Mark as Completed',
                      style: AppTextStyles.buttonText,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusCompleted.withOpacity(0.1),
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: AppColors.statusCompleted),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.statusCompleted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Already Completed',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.statusCompleted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContactItem(String title, String name, String contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title: $name',
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (contact.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          if (contact.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call, color: AppColors.primaryColor, size: 20),
              onPressed: () => _makePhoneCall(contact),
              tooltip: 'Call $contact',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to show the bottom sheet
  static void show({
    required BuildContext context, 
    required Customer customer, 
    required Maintenance maintenance,
    required Function(Maintenance) onMarkAsCompleted,
    required Function(String?) onOpenMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return UpcomingMaintenanceBottomSheet(
          customer: customer,
          maintenance: maintenance,
          onMarkAsCompleted: onMarkAsCompleted,
          onOpenMap: onOpenMap,
        );
      },
    );
  }
}