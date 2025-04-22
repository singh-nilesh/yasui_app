// This file contains the implementation for maintenance history bottom sheet
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/customer.dart';
import '../models/maintenance.dart';

class MaintenanceDetailsBottomSheet extends StatelessWidget {
  final Customer customer;
  final Maintenance maintenance;
  final Function(Maintenance) onMarkAsCompleted;
  final Function(String?) onOpenMap;

  const MaintenanceDetailsBottomSheet({
    super.key,
    required this.customer,
    required this.maintenance,
    required this.onMarkAsCompleted,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    
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
                // Header with customer name and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: AppTextStyles.heading2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(maintenance.status.toString()).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(maintenance.status.toString())),
                            ),
                            child: Text(
                              maintenance.status.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _getStatusColor(maintenance.status.toString()),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                
                // Maintenance Details Section
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.build,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Maintenance Details',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: Icons.category,
                          label: 'Type:',
                          value: maintenance.maintenanceType,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.event,
                          label: 'Next:',
                          value: maintenance.nextMaintenanceDate != null
                              ? _formatDate(maintenance.nextMaintenanceDate!)
                              : 'Not scheduled',
                        ),
                        if (maintenance.notes != null && maintenance.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.note,
                            label: 'Notes:',
                            value: maintenance.notes!,
                            isMultiLine: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Completion Details Section (only visible if completed)
                if (maintenance.status == MaintenanceStatus.completed)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    color: AppColors.statusCompleted.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.statusCompleted.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.statusCompleted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Completion Details',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.statusCompleted,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (maintenance.completedDate != null)
                            _buildDetailRow(
                              icon: Icons.calendar_today,
                              label: 'Completed On:',
                              value: _formatDate(maintenance.completedDate!),
                            ),
                          const SizedBox(height: 8),
                          if (maintenance.issue != null && maintenance.issue!.isNotEmpty)
                            _buildDetailRow(
                              icon: Icons.error_outline,
                              label: 'Issue Found:',
                              value: maintenance.issue!,
                              isMultiLine: true,
                            ),
                          if (maintenance.issue != null && maintenance.issue!.isNotEmpty)
                            const SizedBox(height: 8),
                          if (maintenance.fix != null && maintenance.fix!.isNotEmpty)
                            _buildDetailRow(
                              icon: Icons.build_circle,
                              label: 'Fix Applied:',
                              value: maintenance.fix!,
                              isMultiLine: true,
                            ),
                          if (maintenance.fix != null && maintenance.fix!.isNotEmpty)
                            const SizedBox(height: 8),
                          if (maintenance.cost != null)
                            _buildDetailRow(
                              icon: Icons.currency_rupee,
                              label: 'Cost:',
                              value: currencyFormat.format(maintenance.cost),
                              valueStyle: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                
                // Action Button (for marking as completed)
                const SizedBox(height: 16),
                if (maintenance.status != MaintenanceStatus.completed)
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onMarkAsCompleted(maintenance);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Mark as Completed',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusCompleted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                            'Maintenance Completed',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.statusCompleted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
    
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        isMultiLine
            ? Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: valueStyle ?? AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              )
            : Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$label ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: value,
                        style: valueStyle ?? AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    if (status == MaintenanceStatus.upcoming.toString().split('.').last) {
      return AppColors.primaryColor;
    } else if (status == MaintenanceStatus.completed.toString().split('.').last) {
      return AppColors.statusCompleted;
    } else if (status == MaintenanceStatus.overdue.toString().split('.').last) {
      return AppColors.statusOverdue;
    } else {
      return AppColors.textSecondary;
    }
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
        return MaintenanceDetailsBottomSheet(
          customer: customer,
          maintenance: maintenance,
          onMarkAsCompleted: onMarkAsCompleted,
          onOpenMap: onOpenMap,
        );
      },
    );
  }
}