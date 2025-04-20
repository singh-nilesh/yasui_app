import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/database_service.dart';
import '../models/customer.dart';
import '../widgets/customer_card.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<Customer>> _customersFuture;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _refreshData();
  }
  
  void _refreshData() {
    _customersFuture = _databaseService.getCustomers();
  }
  
  List<Customer> _filterCustomers(List<Customer> customers) {
    if (_searchQuery.isEmpty) {
      return customers;
    }
    
    final query = _searchQuery.toLowerCase();
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
             customer.city.toLowerCase().contains(query) ||
             customer.state.toLowerCase().contains(query) ||
             customer.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.medium,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _refreshData();
                });
              },
              child: FutureBuilder<List<Customer>>(
                future: _customersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading customers: ${snapshot.error}',
                        style: AppTextStyles.bodyLarge,
                      ),
                    );
                  }
                  
                  final customers = _filterCustomers(snapshot.data ?? []);
                  
                  if (customers.isEmpty) {
                    if (_searchQuery.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 72,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No customers found',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to add customer screen
                                // Will be implemented later
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Customer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 72,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final address = '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pinCode}';
                      
                      return CustomerCard(
                        customerName: customer.name,
                        address: address,
                        contactPerson: customer.contactPersonOwner,
                        mobile: customer.mobile,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailsScreen(
                                customer: customer,
                              ),
                            ),
                          ).then((_) => _refreshData());
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Removing the floating action button
    );
  }
}