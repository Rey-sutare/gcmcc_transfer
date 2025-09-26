import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ResourceManagementPage extends StatefulWidget {
  final bool isMobile;

  const ResourceManagementPage({Key? key, required this.isMobile})
    : super(key: key);

  @override
  _ResourceManagementPageState createState() => _ResourceManagementPageState();
}

class _ResourceManagementPageState extends State<ResourceManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _newToolController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedAppointmentId;
  String? _selectedTool;
  Map<String, dynamic>? _selectedAppointmentDetails;
  final _dateFormat = DateFormat('MMM d, yyyy \'at\' hh:mm a');
  String? _selectedDepartment;
  String _selectedTimePeriod = 'Monthly';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _newToolController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';
      });
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access this data. Please ensure you are logged in as an admin.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'failed-precondition':
          return 'The query requires an index. Please create it in the Firebase Console.';
        default:
          return 'An error occurred: ${error.message ?? error.toString()}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _submitResource() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAppointmentId == null || _selectedTool == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select an appointment and a tool',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
        return;
      }

      try {
        final appointmentDoc = await FirebaseFirestore.instance
            .collection('appointments')
            .doc(_selectedAppointmentId)
            .get();
        if (!appointmentDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected appointment not found',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }
        final appointmentData = appointmentDoc.data()!;
        final department =
            appointmentData['department'] as String? ?? 'Unknown';
        final dateStr = appointmentData['date'] as String? ?? '';

        DateTime? startTime;
        try {
          startTime = _dateFormat.parse(dateStr);
        } catch (e) {
          print('Error parsing appointment date: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid appointment date format',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }

        if (startTime.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot allocate resources for past appointments',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }

        final endTime = startTime.add(Duration(hours: 1));

        // Check tool availability
        final toolDoc = await FirebaseFirestore.instance
            .collection('tools')
            .where('name', isEqualTo: _selectedTool)
            .get();

        if (toolDoc.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected tool not found',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }

        final toolQuantity = toolDoc.docs.first['quantity'] as int? ?? 1;
        final maxSlots = toolQuantity * 10;

        final existingResources = await FirebaseFirestore.instance
            .collection('resources')
            .where('startTime', isEqualTo: _dateFormat.format(startTime))
            .where('name', isEqualTo: _selectedTool)
            .get();

        if (existingResources.docs.length >= maxSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tool $_selectedTool has reached its slot limit for this time',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }

        final resourceData = {
          'name': _selectedTool,
          'department': department,
          'startTime': _dateFormat.format(startTime),
          'endTime': _dateFormat.format(endTime),
          'appointmentId': _selectedAppointmentId,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('resources')
            .add(resourceData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tool allocated successfully',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
        setState(() {
          _selectedAppointmentId = null;
          _selectedTool = null;
          _selectedAppointmentDetails = null;
        });
      } catch (e) {
        final errorMessage = _getFriendlyErrorMessage(e);
        print('Error allocating tool: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _editResource(
    String resourceId,
    String currentTool,
    String currentAppointmentId,
  ) async {
    String? newTool = currentTool;
    String? newAppointmentId = currentAppointmentId;
    Map<String, dynamic>? newAppointmentDetails;

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final fontSizeBody = isUltraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : 16.0;
        final paddingHorizontal = isUltraSmall
            ? 8.0
            : isSmall
            ? 12.0
            : 16.0;

        return AlertDialog(
          title: Text(
            'Edit Resource Allocation',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody * 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAppointments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(fontSize: fontSizeBody);
                    }
                    if (snapshot.hasError) {
                      return Text(
                        _getFriendlyErrorMessage(snapshot.error),
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeBody,
                          color: Colors.red[600],
                        ),
                      );
                    }
                    final appointments = snapshot.data ?? [];
                    if (appointments.isEmpty) {
                      return Text(
                        'No upcoming appointments available.',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeBody,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Appointment',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: paddingHorizontal * 0.75,
                          vertical: 10,
                        ),
                      ),
                      value: newAppointmentId,
                      isExpanded: true,
                      items: appointments.map((app) {
                        final id = app['id']?.toString() ?? '';
                        final doctor = app['doctor']?.toString() ?? 'Unknown';
                        final date = app['date']?.toString() ?? 'Unknown';
                        final department =
                            app['department']?.toString() ?? 'Unknown';
                        final type = app['type']?.toString() ?? 'Unknown';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            '$doctor - $date ($department, $type)',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.indigo[900],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            newAppointmentId = value;
                            newAppointmentDetails = appointments.firstWhere(
                              (app) => app['id'] == value,
                            );
                          });
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: paddingHorizontal),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAvailableTools(
                    newAppointmentId ?? currentAppointmentId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator(fontSize: fontSizeBody);
                    }
                    if (snapshot.hasError) {
                      return Text(
                        _getFriendlyErrorMessage(snapshot.error),
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeBody,
                          color: Colors.red[600],
                        ),
                      );
                    }
                    final tools = snapshot.data ?? [];
                    if (tools.isEmpty) {
                      return Text(
                        'No tools available.',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeBody,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Tool',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: paddingHorizontal * 0.75,
                          vertical: 10,
                        ),
                      ),
                      value: newTool,
                      isExpanded: true,
                      items: tools.map((tool) {
                        return DropdownMenuItem<String>(
                          value: tool['name'],
                          child: Text(
                            '${tool['name']} (${tool['availableSlots']} slots available)',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.indigo[900],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            newTool = value;
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newTool == null || newAppointmentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please select an appointment and a tool',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  return;
                }

                try {
                  final appointmentDoc = await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(newAppointmentId)
                      .get();
                  if (!appointmentDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected appointment not found',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }
                  final appointmentData = appointmentDoc.data()!;
                  final department =
                      appointmentData['department'] as String? ?? 'Unknown';
                  final dateStr = appointmentData['date'] as String? ?? '';

                  DateTime? startTime;
                  try {
                    startTime = _dateFormat.parse(dateStr);
                  } catch (e) {
                    print('Error parsing appointment date: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invalid appointment date format',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }

                  if (startTime.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot allocate resources for past appointments',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }

                  final endTime = startTime.add(Duration(hours: 1));

                  // Check tool availability
                  final toolDoc = await FirebaseFirestore.instance
                      .collection('tools')
                      .where('name', isEqualTo: newTool)
                      .get();

                  if (toolDoc.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected tool not found',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }

                  final toolQuantity =
                      toolDoc.docs.first['quantity'] as int? ?? 1;
                  final maxSlots = toolQuantity * 10;

                  final existingResources = await FirebaseFirestore.instance
                      .collection('resources')
                      .where(
                        'startTime',
                        isEqualTo: _dateFormat.format(startTime),
                      )
                      .where('name', isEqualTo: newTool)
                      .get();

                  if (existingResources.docs.length >= maxSlots &&
                      existingResources.docs.first.id != resourceId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tool $newTool has reached its slot limit for this time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                    return;
                  }

                  final resourceData = {
                    'name': newTool,
                    'department': department,
                    'startTime': _dateFormat.format(startTime),
                    'endTime': _dateFormat.format(endTime),
                    'appointmentId': newAppointmentId,
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance
                      .collection('resources')
                      .doc(resourceId)
                      .update(resourceData);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Resource updated successfully',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                  setState(() {});
                } catch (e) {
                  final errorMessage = _getFriendlyErrorMessage(e);
                  print('Error updating resource: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        errorMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteResource(String resourceId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final fontSizeBody = isUltraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : 16.0;

        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody * 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: Text(
            'Are you sure you want to delete this resource allocation?',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody,
              color: Colors.grey[800],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('resources')
            .doc(resourceId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resource deleted successfully',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
        setState(() {});
      } catch (e) {
        final errorMessage = _getFriendlyErrorMessage(e);
        print('Error deleting resource: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _editTool(
    String toolId,
    String currentName,
    int currentQuantity,
  ) async {
    _newToolController.text = currentName;
    _quantityController.text = currentQuantity.toString();

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final fontSizeBody = isUltraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : 16.0;
        final paddingHorizontal = isUltraSmall
            ? 8.0
            : isSmall
            ? 12.0
            : 16.0;

        return AlertDialog(
          title: Text(
            'Edit Tool',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody * 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newToolController,
                decoration: InputDecoration(
                  labelText: 'Tool Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal * 0.75,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.indigo[900],
                ),
              ),
              SizedBox(height: paddingHorizontal),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal * 0.75,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_newToolController.text.trim().isEmpty ||
                    _quantityController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a tool name and quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(_quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('tools')
                      .doc(toolId)
                      .update({
                        'name': _newToolController.text.trim(),
                        'quantity': quantity,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                  _newToolController.clear();
                  _quantityController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tool updated successfully',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                  setState(() {});
                } catch (e) {
                  print('Error updating tool: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _getFriendlyErrorMessage(e),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTool(String toolId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final fontSizeBody = isUltraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : 16.0;

        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody * 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: Text(
            'Are you sure you want to delete this tool?',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody,
              color: Colors.grey[800],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('tools')
            .doc(toolId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tool deleted successfully',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
        setState(() {});
      } catch (e) {
        print('Error deleting tool: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getFriendlyErrorMessage(e),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTools() async {
    if (!_isAdmin) {
      print('User is not an admin, returning default tools');
      return [
        {'name': 'X-ray', 'quantity': 1},
        {'name': 'Ultrasound', 'quantity': 1},
        {'name': 'MRI', 'quantity': 1},
        {'name': 'CT Scan', 'quantity': 1},
        {'name': 'ECG', 'quantity': 1},
      ];
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tools')
          .get();
      final tools = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'quantity': doc['quantity'] as int? ?? 1,
            },
          )
          .toList();
      if (tools.isEmpty) {
        print('No tools found in Firestore, returning default list');
        return [
          {'name': 'X-ray', 'quantity': 1},
          {'name': 'Ultrasound', 'quantity': 1},
          {'name': 'MRI', 'quantity': 1},
          {'name': 'CT Scan', 'quantity': 1},
          {'name': 'ECG', 'quantity': 1},
        ];
      }
      return tools;
    } catch (e) {
      print('Error fetching tools: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return [
        {'name': 'X-ray', 'quantity': 1},
        {'name': 'Ultrasound', 'quantity': 1},
        {'name': 'MRI', 'quantity': 1},
        {'name': 'CT Scan', 'quantity': 1},
        {'name': 'ECG', 'quantity': 1},
      ];
    }
  }

  Stream<QuerySnapshot> _fetchToolsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('tools')
        .orderBy('timestamp', descending: true);

    print('Fetching tools stream: no department filter applied');
    return query.snapshots();
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableTools(
    String? appointmentId,
  ) async {
    try {
      final tools = await _fetchTools();
      if (appointmentId == null) return tools;

      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return tools;

      final dateStr = appointmentDoc.data()!['date'] as String? ?? '';
      DateTime? startTime;
      try {
        startTime = _dateFormat.parse(dateStr);
      } catch (e) {
        return tools;
      }

      final availableTools = <Map<String, dynamic>>[];
      for (var tool in tools) {
        final toolName = tool['name'] as String;
        final toolQuantity = tool['quantity'] as int? ?? 1;
        final maxSlots = toolQuantity * 10;

        final existingResources = await FirebaseFirestore.instance
            .collection('resources')
            .where('startTime', isEqualTo: _dateFormat.format(startTime))
            .where('name', isEqualTo: toolName)
            .get();

        final availableSlots = maxSlots - existingResources.docs.length;
        if (availableSlots > 0) {
          availableTools.add({
            'name': toolName,
            'quantity': toolQuantity,
            'availableSlots': availableSlots,
          });
        }
      }
      return availableTools;
    } catch (e) {
      print('Error fetching available tools: $e');
      return [];
    }
  }

  Future<List<String>> _fetchDepartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();
      final departments = snapshot.docs
          .map((doc) => doc['department'] as String? ?? 'Unknown')
          .toSet()
          .toList();
      departments.sort();
      return departments;
    } catch (e) {
      print('Error fetching departments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return [];
    }
  }

  Future<Map<String, int>> _fetchToolCounts() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedTimePeriod) {
        case 'Weekly':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'Yearly':
          startDate = now.subtract(Duration(days: 365));
          break;
        case 'Monthly':
        default:
          startDate = now.subtract(Duration(days: 30));
          break;
      }
      print(
        'Fetching tool stats for timePeriod: $_selectedTimePeriod, startDate: $startDate, department: ${_selectedDepartment ?? 'All'}',
      );

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('resources')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
      if (_selectedDepartment != null) {
        query = query.where('department', isEqualTo: _selectedDepartment);
      }

      final snapshot = await query.get();
      print('Resources found: ${snapshot.docs.length}');

      final toolCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp == null) {
          print('Missing timestamp for resource ${doc.id}');
          continue;
        }
        final allocationDate = timestamp.toDate();
        if (allocationDate.isBefore(startDate)) {
          print('Skipping resource ${doc.id} with date $allocationDate');
          continue;
        }

        final toolName = data['name'] as String? ?? 'Unknown';
        toolCounts[toolName] = (toolCounts[toolName] ?? 0) + 1;
      }

      final result = toolCounts;
      print('Tool stats result: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error fetching tool stats: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return {};
    }
  }

  Future<void> _addNewTool() async {
    if (_newToolController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a tool name and quantity',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid quantity',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tools').add({
        'name': _newToolController.text.trim(),
        'quantity': quantity,
        'department': _selectedDepartment ?? 'All',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _newToolController.clear();
      _quantityController.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tool added successfully',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.green[600],
        ),
      );
      setState(() {});
    } catch (e) {
      print('Error adding tool: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showAddToolDialog() {
    _newToolController.clear();
    _quantityController.clear();
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final fontSizeBody = isUltraSmall
            ? 12.0
            : isSmall
            ? 14.0
            : 16.0;
        final paddingHorizontal = isUltraSmall
            ? 8.0
            : isSmall
            ? 12.0
            : 16.0;

        return AlertDialog(
          title: Text(
            'Add New Tool',
            style: GoogleFonts.poppins(
              fontSize: fontSizeBody * 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newToolController,
                decoration: InputDecoration(
                  labelText: 'Tool Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal * 0.75,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.indigo[900],
                ),
              ),
              SizedBox(height: paddingHorizontal),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal * 0.75,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _addNewTool,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(
                  fontSize: fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isUltraSmall = screenWidth < 360;
    final isSmall = screenWidth < 600;
    final isMedium = screenWidth < 900;

    final double fontSizeTitle = isUltraSmall
        ? 20
        : isSmall
        ? 22
        : 26;
    final double fontSizeSubtitle = isUltraSmall
        ? 12
        : isSmall
        ? 14
        : 16;
    final double fontSizeBody = isUltraSmall
        ? 12
        : isSmall
        ? 14
        : 16;
    final double fontSizeTable = isUltraSmall
        ? 10
        : isSmall
        ? 12
        : 14;
    final double paddingHorizontal = isUltraSmall
        ? 8
        : isSmall
        ? 12
        : 16;
    final double paddingVertical = isUltraSmall ? 8 : 12;
    final double spacing = isUltraSmall
        ? 8
        : isSmall
        ? 12
        : 16;
    final double cardMinHeight = screenHeight * 0.2;
    final double cardMaxHeight = isUltraSmall
        ? 300
        : isSmall
        ? 350
        : 400;
    final double chartHeight = isUltraSmall
        ? 180
        : isSmall
        ? 200
        : 240;
    final double barWidth = isUltraSmall
        ? 8
        : isSmall
        ? 12
        : 16;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Resource Management',
            style: GoogleFonts.poppins(
              fontSize: fontSizeTitle,
              fontWeight: FontWeight.w700,
              color: Colors.indigo[900],
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing * 0.5),
          Text(
            'Allocate and manage hospital resources for appointments',
            style: GoogleFonts.poppins(
              fontSize: fontSizeSubtitle,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.indigo[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(paddingHorizontal * 0.75),
              constraints: BoxConstraints(
                minHeight: cardMinHeight,
                maxHeight: cardMaxHeight,
                minWidth: double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocate Tool',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing * 0.75),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchAppointments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingIndicator(
                              fontSize: fontSizeBody,
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              _getFriendlyErrorMessage(snapshot.error),
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody,
                                color: Colors.red[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          final appointments = snapshot.data ?? [];
                          if (appointments.isEmpty) {
                            return Text(
                              'No upcoming appointments available.',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Appointment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.indigo[700]!,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: paddingHorizontal * 0.75,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedAppointmentId,
                            isExpanded: true,
                            items: appointments.map((app) {
                              final id = app['id']?.toString() ?? '';
                              final doctor =
                                  app['doctor']?.toString() ?? 'Unknown';
                              final date = app['date']?.toString() ?? 'Unknown';
                              final department =
                                  app['department']?.toString() ?? 'Unknown';
                              final type = app['type']?.toString() ?? 'Unknown';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  '$doctor - $date ($department, $type)',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeBody,
                                    color: Colors.indigo[900],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedAppointmentId = value;
                                  _selectedAppointmentDetails = appointments
                                      .firstWhere((app) => app['id'] == value);
                                  _selectedTool = null;
                                  print('Selected appointment ID: $value');
                                });
                              }
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please select an appointment'
                                : null,
                            hint: Text(
                              'Choose an appointment',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: spacing * 0.75),
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchAvailableTools(
                              _selectedAppointmentId,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingIndicator(
                                  fontSize: fontSizeBody,
                                );
                              }
                              if (snapshot.hasError) {
                                return Text(
                                  _getFriendlyErrorMessage(snapshot.error),
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeBody,
                                    color: Colors.red[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              final tools = snapshot.data ?? [];
                              if (tools.isEmpty) {
                                return Text(
                                  'No tools available for this time slot.',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeBody,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Tool',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.indigo[700]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: paddingHorizontal * 0.75,
                                    vertical: 8,
                                  ),
                                ),
                                value: _selectedTool,
                                isExpanded: true,
                                items: tools.map((tool) {
                                  return DropdownMenuItem<String>(
                                    value: tool['name'],
                                    child: Text(
                                      '${tool['name']} (${tool['availableSlots']} slots available)',
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeBody,
                                        color: Colors.indigo[900],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedTool = value;
                                      print('Selected tool: $value');
                                    });
                                  }
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Please select a tool'
                                    : null,
                                hint: Text(
                                  'Choose a tool',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeBody,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: paddingHorizontal * 0.75),
                        _buildStyledButton(
                          context: context,
                          text: 'Add Tool',
                          onPressed: _showAddToolDialog,
                          backgroundColor: Colors.indigo[500],
                          fontSize: fontSizeBody,
                          paddingHorizontal: paddingHorizontal * 0.75,
                        ),
                      ],
                    ),
                    if (_selectedAppointmentId != null &&
                        _selectedAppointmentDetails != null &&
                        _selectedTool != null) ...[
                      SizedBox(height: spacing * 0.75),
                      Container(
                        padding: EdgeInsets.all(paddingHorizontal * 0.5),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Allocation Details',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[900],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing * 0.5),
                            Text(
                              'Doctor: ${_selectedAppointmentDetails!['doctor'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Date: ${_selectedAppointmentDetails!['date'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Department: ${_selectedAppointmentDetails!['department'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Type: ${_selectedAppointmentDetails!['type'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Patient ID: ${_selectedAppointmentDetails!['patientId'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tool: $_selectedTool',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody * 0.85,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: spacing * 0.75),
                    Align(
                      alignment: Alignment.center,
                      child: _buildStyledButton(
                        context: context,
                        text: 'Allocate Tool',
                        onPressed: _submitResource,
                        backgroundColor: Colors.indigo[700],
                        fontSize: fontSizeBody,
                        paddingHorizontal: paddingHorizontal * 0.75,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.teal[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(paddingHorizontal),
              constraints: BoxConstraints(
                minHeight: cardMinHeight * 1.5,
                minWidth: double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Tool Inventory',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeBody * 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory,
                          color: Colors.teal[700],
                          size: fontSizeBody,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: paddingHorizontal * 0.5),
                  Divider(
                    color: Colors.teal[100]!.withOpacity(0.6),
                    thickness: 1,
                  ),
                  SizedBox(height: paddingHorizontal * 0.5),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _fetchToolsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingIndicator(fontSize: fontSizeBody);
                        }
                        if (snapshot.hasError) {
                          print('Error loading tools: ${snapshot.error}');
                          return Text(
                            _getFriendlyErrorMessage(snapshot.error),
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.red[600],
                            ),
                          );
                        }
                        final tools = snapshot.data?.docs ?? [];
                        if (tools.isEmpty) {
                          return Text(
                            'No tools found.',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        return DataTable(
                          columnSpacing: isUltraSmall
                              ? 2
                              : isSmall
                              ? 4
                              : 8,
                          dataRowHeight: isUltraSmall
                              ? 32
                              : isSmall
                              ? 40
                              : 52,
                          headingRowHeight: isUltraSmall
                              ? 32
                              : isSmall
                              ? 40
                              : 44,
                          columns: [
                            DataColumn(
                              label: SizedBox(
                                width: isUltraSmall || isSmall
                                    ? screenWidth * 0.25
                                    : screenWidth * 0.3,
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeTable,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: isUltraSmall || isSmall
                                    ? screenWidth * 0.25
                                    : screenWidth * 0.3,
                                child: Text(
                                  'Quantity',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeTable,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: isUltraSmall || isSmall
                                    ? screenWidth * 0.25
                                    : screenWidth * 0.3,
                                child: Text(
                                  'Action',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeTable,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                          rows: tools.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final toolId = doc.id;
                            final name = data['name'] as String? ?? 'Unknown';
                            final quantity = data['quantity'] as int? ?? 1;
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: isUltraSmall || isSmall
                                        ? screenWidth * 0.25
                                        : screenWidth * 0.3,
                                    child: Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeTable,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: isUltraSmall || isSmall
                                        ? screenWidth * 0.25
                                        : screenWidth * 0.3,
                                    child: Text(
                                      quantity.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeTable,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: isUltraSmall || isSmall
                                        ? screenWidth * 0.25
                                        : screenWidth * 0.3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: isUltraSmall || isSmall
                                                ? fontSizeTable * 1.1
                                                : fontSizeTable * 1.5,
                                            color: Colors.indigo[700],
                                          ),
                                          onPressed: () =>
                                              _editTool(toolId, name, quantity),
                                          padding: EdgeInsets.all(
                                            isUltraSmall
                                                ? 1
                                                : isSmall
                                                ? 2
                                                : 4,
                                          ),
                                          constraints: BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            size: isUltraSmall || isSmall
                                                ? fontSizeTable * 1.1
                                                : fontSizeTable * 1.5,
                                            color: Colors.red[600],
                                          ),
                                          onPressed: () => _deleteTool(toolId),
                                          padding: EdgeInsets.all(
                                            isUltraSmall
                                                ? 1
                                                : isSmall
                                                ? 2
                                                : 4,
                                          ),
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          FutureBuilder<List<String>>(
            future: _fetchDepartments(),
            builder: (context, deptSnapshot) {
              if (deptSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator(fontSize: fontSizeBody);
              }
              if (deptSnapshot.hasError) {
                return Text(
                  _getFriendlyErrorMessage(deptSnapshot.error),
                  style: GoogleFonts.poppins(
                    fontSize: fontSizeBody,
                    color: Colors.red[600],
                  ),
                );
              }
              final depts = ['All', ...(deptSnapshot.data ?? [])];
              return Container(
                width: screenWidth * 0.9,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: paddingHorizontal * 0.75,
                      vertical: 10,
                    ),
                  ),
                  value: _selectedDepartment ?? 'All',
                  isExpanded: true,
                  items: depts.map((dept) {
                    return DropdownMenuItem<String>(
                      value: dept,
                      child: Text(
                        dept,
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeBody,
                          color: Colors.indigo[900],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedDepartment = (value == 'All') ? null : value;
                    });
                  },
                ),
              );
            },
          ),
          SizedBox(height: spacing),
          Container(
            width: screenWidth * 0.9,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Time Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: paddingHorizontal * 0.75,
                  vertical: 10,
                ),
              ),
              value: _selectedTimePeriod,
              isExpanded: true,
              items: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(
                    period,
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeBody,
                      color: Colors.indigo[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedTimePeriod = value;
                  });
                }
              },
            ),
          ),
          SizedBox(height: spacing),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.teal[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(paddingHorizontal),
              constraints: BoxConstraints(
                minHeight: cardMinHeight * 1.5,
                minWidth: double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Tool Utilization',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeBody * 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal[100]!.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          color: Colors.teal[700],
                          size: fontSizeBody,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: paddingHorizontal * 0.5),
                  Divider(
                    color: Colors.teal[100]!.withOpacity(0.6),
                    thickness: 1,
                  ),
                  SizedBox(height: paddingHorizontal * 0.5),
                  SizedBox(
                    height: chartHeight,
                    child: FutureBuilder<Map<String, int>>(
                      future: _fetchToolCounts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingIndicator(fontSize: fontSizeBody);
                        }
                        if (snapshot.hasError) {
                          print('Error in Tool Utilization: ${snapshot.error}');
                          return Text(
                            _getFriendlyErrorMessage(snapshot.error),
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                        final toolCounts = snapshot.data ?? {};
                        if (toolCounts.isEmpty) {
                          return Text(
                            'No tool allocation data available for ${_selectedDepartment ?? 'All'} ($_selectedTimePeriod)',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeBody,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                        final tools = toolCounts.keys.toList()..sort();
                        final maxY =
                            toolCounts.values
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() *
                            1.2;
                        final List<Color> barColors = [
                          Color(0xFF0288D1), // Light Blue
                          Color(0xFFD81B60), // Pink
                          Color(0xFF7B1FA2), // Purple
                          Color(0xFF689F38), // Green
                          Color(0xFFFFA000), // Amber
                          Color(0xFF1976D2), // Blue
                          Color(0xFF0097A7), // Cyan
                          Color(0xFFE64A19), // Deep Orange
                        ];
                        return Column(
                          children: [
                            SizedBox(
                              height: chartHeight * 0.7,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxY > 0 ? maxY : 10.0,
                                  barGroups: tools.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final tool = entry.value;
                                    final count = toolCounts[tool]!.toDouble();
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: count,
                                          color:
                                              barColors[index %
                                                  barColors.length],
                                          width: barWidth,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                                show: true,
                                                toY: maxY,
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                        ),
                                      ],
                                      showingTooltipIndicators: [0],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: maxY > 5 ? maxY / 5 : 1.0,
                                        getTitlesWidget: (value, meta) {
                                          if (value % 1 != 0)
                                            return const SizedBox();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSizeBody * 0.8,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          final toolName = tools[value.toInt()];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Transform.rotate(
                                              angle: isSmall
                                                  ? -45 * 3.14159 / 180
                                                  : 0,
                                              child: Text(
                                                toolName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSizeBody * 0.8,
                                                  color: Colors.grey[800],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final count =
                                              toolCounts[tools[value
                                                  .toInt()]] ??
                                              0;
                                          return Text(
                                            count.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSizeBody * 0.8,
                                              color: Colors.teal[900],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.teal[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY > 5
                                        ? maxY / 5
                                        : 1.0,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.teal[100]!.withOpacity(
                                          0.5,
                                        ),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) =>
                                          Colors.teal[900]!.withOpacity(0.9),
                                      getTooltipItem:
                                          (group, groupIdx, rod, rodIdx) {
                                            final toolName =
                                                tools[group.x.toInt()];
                                            final count =
                                                toolCounts[toolName] ?? 0;
                                            return BarTooltipItem(
                                              '$toolName\n$count Allocations',
                                              GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: fontSizeBody * 0.8,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: paddingHorizontal * 0.5),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: tools.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tool = entry.value;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color:
                                            barColors[index % barColors.length],
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      tool,
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSizeBody * 0.8,
                                        color: Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: paddingHorizontal * 0.5),
                  Center(
                    child: Text(
                      'Tool Allocations ($_selectedTimePeriod)',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeBody,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.indigo[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(paddingHorizontal * 0.5),
              constraints: BoxConstraints(
                minHeight: cardMinHeight * 0.75,
                minWidth: double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allocated Resources',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing),
                  StreamBuilder<QuerySnapshot>(
                    stream: () {
                      Query<Map<String, dynamic>> query = FirebaseFirestore
                          .instance
                          .collection('resources')
                          .orderBy('timestamp', descending: true);
                      if (_selectedDepartment != null) {
                        query = query.where(
                          'department',
                          isEqualTo: _selectedDepartment,
                        );
                      }
                      return query.snapshots();
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingIndicator(fontSize: fontSizeBody);
                      }
                      if (snapshot.hasError) {
                        print('Error loading resources: ${snapshot.error}');
                        return Text(
                          _getFriendlyErrorMessage(snapshot.error),
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeBody,
                            color: Colors.red[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      final resources = snapshot.data?.docs ?? [];
                      if (resources.isEmpty) {
                        return Text(
                          'No resources allocated.',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeBody,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          final resource = resources[index];
                          final resourceData =
                              resource.data() as Map<String, dynamic>;
                          final resourceId = resource.id;
                          final appointmentId =
                              resourceData['appointmentId']?.toString() ?? '';
                          final toolName =
                              resourceData['name']?.toString() ?? 'Unknown';
                          final startTime =
                              resourceData['startTime']?.toString() ??
                              'Unknown';
                          final endTime =
                              resourceData['endTime']?.toString() ?? 'Unknown';
                          final department =
                              resourceData['department']?.toString() ??
                              'Unknown';

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            title: Text(
                              '$toolName - $department',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBody,
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo[900],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: FutureBuilder<String>(
                              future: _getPatientId(appointmentId),
                              builder: (context, userSnapshot) {
                                final patientId =
                                    userSnapshot.data ?? 'Unknown';
                                return Text(
                                  'Patient ID: $patientId\nTime: $startTime - $endTime',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSizeBody * 0.85,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.indigo[700],
                                    size: fontSizeBody,
                                  ),
                                  onPressed: () => _editResource(
                                    resourceId,
                                    toolName,
                                    appointmentId,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[600],
                                    size: fontSizeBody,
                                  ),
                                  onPressed: () => _deleteResource(resourceId),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator({required double fontSize}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.teal[700]),
        SizedBox(height: 6),
        Text(
          'Loading Data...',
          style: GoogleFonts.poppins(
            fontSize: fontSize * 0.85,
            fontWeight: FontWeight.w500,
            color: Colors.teal[900],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required double fontSize,
    required double paddingHorizontal,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.indigo[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingHorizontal * 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.indigo.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: 'Upcoming')
          .get();

      // Get all appointment IDs that have allocated resources
      final resourcesSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();
      final allocatedAppointmentIds = resourcesSnapshot.docs
          .map((doc) => doc['appointmentId'] as String?)
          .toSet();

      final appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return appointments.where((app) {
        final dateStr = app['date'] as String? ?? '';
        final appId = app['id'] as String;
        try {
          final date = _dateFormat.parse(dateStr);
          // Only include appointments that haven't been allocated and are in the future
          return date.isAfter(now) && !allocatedAppointmentIds.contains(appId);
        } catch (e) {
          print('Error parsing date for appointment ${app['id']}: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return [];
    }
  }

  Future<String> _getPatientId(String appointmentId) async {
    try {
      if (appointmentId.isEmpty) return 'Unknown';
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!appointmentDoc.exists) {
        print('Appointment not found for ID: $appointmentId');
        return 'Unknown';
      }
      final patientId =
          appointmentDoc.data()?['patientId'] as String? ?? 'Unknown';
      print('Fetched patient ID for appointment ID $appointmentId: $patientId');
      return patientId;
    } catch (e) {
      print('Error fetching patient ID for appointment ID $appointmentId: $e');
      return 'Unknown';
    }
  }
}
