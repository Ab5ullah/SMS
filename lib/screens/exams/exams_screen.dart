import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/exam.dart';
import '../../utils/helpers.dart';
import 'add_edit_exam_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        title: const Text('Exam Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditExamScreen(),
                ),
              );
            },
            tooltip: 'Add Exam',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exams...',
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
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exams')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('examDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final exams = snapshot.data!.docs
                    .map((doc) => Exam.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ))
                    .where((exam) {
                  if (_searchQuery.isEmpty) return true;
                  return exam.name.toLowerCase().contains(_searchQuery) ||
                      exam.subject.toLowerCase().contains(_searchQuery) ||
                      exam.className.toLowerCase().contains(_searchQuery);
                }).toList();

                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No exams found'
                              : 'No exams match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddEditExamScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Exam'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: exams.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    final isUpcoming =
                        exam.examDate.isAfter(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUpcoming
                              ? Colors.blue
                              : Colors.grey,
                          child: Icon(
                            isUpcoming
                                ? Icons.upcoming
                                : Icons.history,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          exam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Subject: ${exam.subject}'),
                            Text('Class: ${exam.className} - ${exam.section}'),
                            Text('Date: ${Helpers.formatDate(exam.examDate)}'),
                            Text(
                                'Marks: ${exam.totalMarks} | Passing: ${exam.passingMarks}'),
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
                                      AddEditExamScreen(exam: exam),
                                ),
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(context, exam);
                            }
                          },
                        ),
                        onTap: () {
                          _showExamDetails(context, exam);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text(
            'Are you sure you want to delete ${exam.name}? This action cannot be undone.'),
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
                    .collection('exams')
                    .doc(exam.id)
                    .delete();
                if (context.mounted) {
                  Helpers.showSnackBar(
                    context,
                    'Exam deleted successfully',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Helpers.showSnackBar(
                    context,
                    'Error deleting exam: $e',
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

  void _showExamDetails(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', exam.subject),
              _buildDetailRow('Class', '${exam.className} - ${exam.section}'),
              _buildDetailRow('Exam Date', Helpers.formatDate(exam.examDate)),
              _buildDetailRow('Total Marks', exam.totalMarks.toString()),
              _buildDetailRow('Passing Marks', exam.passingMarks.toString()),
              if (exam.remarks != null)
                _buildDetailRow('Remarks', exam.remarks!),
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
                  builder: (context) => AddEditExamScreen(exam: exam),
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
