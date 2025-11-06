import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/fee.dart';
import '../../utils/helpers.dart';
import 'add_edit_fee_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, paid, unpaid, partial

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditFeeScreen(),
                ),
              );
            },
            tooltip: 'Add Fee Record',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unpaid', 'unpaid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partial', 'partial'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fees')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('dueDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var fees = snapshot.data!.docs
                    .map((doc) => Fee.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ))
                    .where((fee) {
                  // Apply status filter
                  if (_statusFilter != 'all' && fee.status != _statusFilter) {
                    return false;
                  }
                  // Apply search filter
                  if (_searchQuery.isEmpty) return true;
                  return fee.studentName.toLowerCase().contains(_searchQuery) ||
                      fee.studentId.toLowerCase().contains(_searchQuery);
                }).toList();

                if (fees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _statusFilter == 'all'
                              ? 'No fee records found'
                              : 'No records match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty && _statusFilter == 'all') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddEditFeeScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Fee Record'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Calculate statistics
                final totalAmount = fees.fold<double>(
                    0, (sum, fee) => sum + fee.amount);
                final totalPaid = fees.fold<double>(
                    0, (sum, fee) => sum + fee.paidAmount);
                final totalPending = totalAmount - totalPaid;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              'Rs. ${totalAmount.toStringAsFixed(0)}',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Paid',
                              'Rs. ${totalPaid.toStringAsFixed(0)}',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Pending',
                              'Rs. ${totalPending.toStringAsFixed(0)}',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: fees.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final fee = fees[index];
                          Color statusColor;
                          IconData statusIcon;

                          switch (fee.status) {
                            case 'paid':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'unpaid':
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              break;
                            case 'partial':
                              statusColor = Colors.orange;
                              statusIcon = Icons.access_time;
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusIcon = Icons.help;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: Icon(statusIcon, color: Colors.white),
                              ),
                              title: Text(
                                fee.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Month: ${fee.month} ${fee.year}'),
                                  Text('Class: ${fee.className} - ${fee.section}'),
                                  Text(
                                      'Amount: Rs. ${fee.amount} | Paid: Rs. ${fee.paidAmount}'),
                                  Text('Due: ${Helpers.formatDate(fee.dueDate)}'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddEditFeeScreen(fee: fee),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, fee);
                                  }
                                },
                              ),
                              onTap: () {
                                _showFeeDetails(context, fee);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Fee fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee Record'),
        content: Text(
            'Are you sure you want to delete this fee record for ${fee.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('fees')
                    .doc(fee.id)
                    .delete();
                if (context.mounted) {
                  Helpers.showSnackBar(
                    context,
                    'Fee record deleted successfully',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Helpers.showSnackBar(
                    context,
                    'Error deleting fee record: $e',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFeeDetails(BuildContext context, Fee fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fee.studentName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student ID', fee.studentId),
              _buildDetailRow('Class', '${fee.className} - ${fee.section}'),
              _buildDetailRow('Month', '${fee.month} ${fee.year}'),
              _buildDetailRow('Amount', 'Rs. ${fee.amount}'),
              _buildDetailRow('Paid Amount', 'Rs. ${fee.paidAmount}'),
              _buildDetailRow('Remaining', 'Rs. ${fee.remainingAmount}'),
              _buildDetailRow('Status', fee.status.toUpperCase()),
              _buildDetailRow('Due Date', Helpers.formatDate(fee.dueDate)),
              if (fee.paidDate != null)
                _buildDetailRow('Paid Date', Helpers.formatDate(fee.paidDate!)),
              if (fee.remarks != null)
                _buildDetailRow('Remarks', fee.remarks!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditFeeScreen(fee: fee),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
