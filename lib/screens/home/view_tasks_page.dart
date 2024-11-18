import 'package:flutter/material.dart';
import 'package:sales_navigator/screens/home/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:sales_navigator/screens/home/home_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ViewTasksPage extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final LeadItem leadItem;

  const ViewTasksPage({super.key, required this.tasks, required this.leadItem});

  @override
  _ViewTasksPageState createState() => _ViewTasksPageState();
}

class _ViewTasksPageState extends State<ViewTasksPage> {
  late List<Map<String, dynamic>> filteredTasks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> taskEvents = {};
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _organizeTaskEvents();
    _filterTasksByDate(_focusedDay);
  }

  void _organizeTaskEvents() {
    taskEvents = {};
    for (var task in widget.tasks) {
      final dueDate = task['due_date'] is String
          ? DateTime.parse(task['due_date'])
          : task['due_date'];
      final date = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (taskEvents.containsKey(date)) {
        taskEvents[date]!.add(task);
      } else {
        taskEvents[date] = [task];
      }
    }
  }

  void _filterTasksByDate(DateTime date) {
    setState(() {
      filteredTasks = taskEvents[DateTime(date.year, date.month, date.day)] ?? [];
    });
  }

  Future<void> _deleteTask(int taskId) async {
    final String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/delete_task.php';

    final Map<String, String> queryParameters = {
      'task_id': taskId.toString(),
    };

    final Uri uri =
    Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            widget.tasks.removeWhere((task) => task['id'] == taskId);
            _organizeTaskEvents();
            _filterTasksByDate(_selectedDay ?? _focusedDay); // Refresh task list
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
    }
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    await _navigateToEditTaskPage(context, task);
    setState(() {
      _organizeTaskEvents();
      _filterTasksByDate(_selectedDay ?? _focusedDay);
    });
  }

  Future<void> _navigateToEditTaskPage(
      BuildContext context, Map<String, dynamic> task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: 0,
          customerName: widget.leadItem.customerName,
          contactNumber: widget.leadItem.contactNumber,
          emailAddress: widget.leadItem.emailAddress,
          address: widget.leadItem.addressLine1,
          lastPurchasedAmount: widget.leadItem.amount,
          existingTitle: task['title'],
          existingDescription: task['description'],
          existingDueDate: task['due_date'],
          showTaskDetails: true,
          taskId: task['id'],
          showSalesOrderId: false,
        ),
      ),
    );

    if (result is Map<String, dynamic>) {
      // Update the local task list with the edited task
      final index = widget.tasks.indexWhere((t) => t['id'] == result['id']);
      if (index != -1) {
        setState(() {
          widget.tasks[index] = result;
          _organizeTaskEvents();
          _filterTasksByDate(_selectedDay ?? _focusedDay);
        });
      }
    }
  }

  Future<void> _fetchTaskDetails() async {
    final String baseUrl =
        '${dotenv.env['API_URL']}/sales_lead/get_task_details.php';

    final Map<String, String> queryParameters = {
      'lead_id': widget.leadItem.id.toString(),
    };

    final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          if (mounted) {
            setState(() {
              // Map and update tasks
              widget.tasks.clear();
              widget.tasks.addAll((responseData['tasks'] as List).map((task) {
                return {
                  'id': task['id'],
                  'title': task['title'],
                  'description': task['description'],
                  'due_date': DateTime.parse(task['due_date']),
                  'creation_date': DateTime.parse(task['creation_date']),
                };
              }));

              // Organize and filter tasks for display
              _organizeTaskEvents();
              _filterTasksByDate(_selectedDay ?? _focusedDay);
            });
          }
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to fetch task details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching task details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch task details: $e')),
      );
    }
  }

  String _getDueDateStatus(DateTime dueDate) {
    final difference = dueDate.difference(DateTime.now()).inDays;
    if (difference <= 0) {
      return "Due now";
    } else if (difference < 3) {
      return "Due in $difference days";
    } else {
      return "Due in $difference days";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0175FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _filterTasksByDate(selectedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.2), // Slightly transparent color
              ),
              todayTextStyle: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markersAlignment: Alignment.bottomCenter,
              markerSizeScale: 0.2,
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              return taskEvents[date] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, tasks) {
                if (tasks.isEmpty) return null;

                bool hasDueSoon = tasks.any((task) {
                  final taskMap = task as Map<String, dynamic>; // Explicitly cast task
                  final dueDate = taskMap['due_date']; // Access 'due_date' after casting
                  if (dueDate == null) return false; // Skip if dueDate is null
                  final difference = dueDate.difference(DateTime.now()).inDays;
                  return difference <= 3; // Tasks due in 3 or fewer days
                });

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      tasks.length,
                          (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: hasDueSoon ? Colors.red : Colors.green, // Red for due/soon, green otherwise
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
              child: Text('No tasks for the selected date.'),
            )
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final dueDate = task['due_date'];
                final dueDateStatus = _getDueDateStatus(dueDate);

                final dueInThreeDays =
                    dueDate.difference(DateTime.now()).inDays < 3;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: dueInThreeDays
                          ? Colors.red
                          : theme.colorScheme.secondaryContainer,
                    ),
                  ),
                  color: dueInThreeDays
                      ? Colors.red.shade50
                      : theme.colorScheme.surface,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      task['title'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Due: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              dueDateStatus,
                              style: TextStyle(
                                color: dueInThreeDays
                                    ? Colors.red
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(task['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTaskPage(
                id: widget.leadItem.id,
                customerName: widget.leadItem.customerName,
                contactNumber: widget.leadItem.contactNumber,
                emailAddress: widget.leadItem.emailAddress,
                address: widget.leadItem.addressLine1,
                lastPurchasedAmount: widget.leadItem.amount,
                showTaskDetails: true,
              ),
            ),
          );

          if (result == true) {
            setState(() {
              _organizeTaskEvents();
              _filterTasksByDate(_focusedDay);
            });
          }
        },
        tooltip: 'Create Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
