import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/maintenance.dart';

class MaintenanceCard extends StatelessWidget {
  final String customerName;
  final String address;
  final DateTime maintenanceDate;
  final MaintenanceStatus status;
  final String maintenanceType;
  final VoidCallback onTap;

  const MaintenanceCard({
    super.key,
    required this.customerName,
    required this.address,
    required this.maintenanceDate,
    required this.status,
    required this.maintenanceType,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case MaintenanceStatus.upcoming:
        return AppColors.statusUpcoming;
      case MaintenanceStatus.completed:
        return AppColors.statusCompleted;
      case MaintenanceStatus.overdue:
        return AppColors.statusOverdue;
    }
  }

  String _getStatusText() {
    switch (status) {
      case MaintenanceStatus.upcoming:
        return 'Upcoming';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.overdue:
        return 'Overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(maintenanceDate);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: AppBorderRadius.small,
                      border: Border.all(color: _getStatusColor()),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}