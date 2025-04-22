import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DbInspectorScreen extends StatefulWidget {
  const DbInspectorScreen({super.key});

  @override
  State<DbInspectorScreen> createState() => _DbInspectorScreenState();
}

class _DbInspectorScreenState extends State<DbInspectorScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _dbPath;
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>>? _allRecords;
  List<String>? _tables;

  @override
  void initState() {
    super.initState();
    _loadDbInfo();
  }

  Future<void> _loadDbInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the database path
      final db = await _databaseService.database;
      _dbPath = db.path;
      
      // Get all records using our method
      _allRecords = await _databaseService.getAllRecords();
      
      // Get all tables
      _tables = await _databaseService.getAllTables();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading database info: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Inspector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDbInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDbInfoCard(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTableContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDbInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildInfoRow('Path', _dbPath ?? 'Unknown'),
            _buildInfoRow('Tables', _tables?.join(', ') ?? 'None'),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    if (_allRecords == null || _allRecords!.isEmpty) {
      return const Center(child: Text('No data found in database'));
    }

    return DefaultTabController(
      length: _allRecords!.keys.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: _allRecords!.keys.map((table) {
              final count = _allRecords![table]?.length ?? 0;
              return Tab(
                text: '$table ($count)',
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _allRecords!.keys.map((table) {
                final records = _allRecords![table] ?? [];
                
                if (records.isEmpty) {
                  return const Center(child: Text('No records found'));
                }
                
                // Get column names from the first record
                final columns = records.isNotEmpty 
                    ? records.first.keys.toList() 
                    : [];
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 12,
                      columns: columns.map((col) => 
                        DataColumn(
                          label: Text(
                            col,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      ).toList(),
                      rows: records.map((record) {
                        return DataRow(
                          cells: columns.map((col) {
                            // Convert any complex types to string representation
                            String displayValue = '';
                            final value = record[col];
                            
                            if (value == null) {
                              displayValue = 'NULL';
                            } else if (value is DateTime) {
                              displayValue = value.toString();
                            } else {
                              displayValue = value.toString();
                            }
                            
                            return DataCell(
                              Text(
                                displayValue,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}