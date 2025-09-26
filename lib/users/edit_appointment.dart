import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../users/doctor_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final bool isMobile;

  const EditAppointmentScreen({
    Key? key,
    required this.appointment,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  String? department;
  String? doctor;
  String? appointmentType;
  final reasonController = TextEditingController();
  final _dateFormat = DateFormat('MMM d, yyyy \'at\' hh:mm a');

  final appointmentTypes = [
    'New Patient',
    'Follow-up',
    'Emergency',
    'Consultation',
    'Procedure',
  ];

  List<String> departments = [];
  List<Map<String, dynamic>> doctorList = [];

  List<String> get doctors => department != null
      ? doctorList
            .where((doc) => doc['department'] == department)
            .map((doc) => doc['name'] as String)
            .toList()
      : [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadDepartmentsAndDoctors();
  }

  void _initializeFields() {
    final appointment = widget.appointment;
    try {
      final dateTime = _dateFormat.parse(appointment['date']);
      selectedDate = dateTime;
      selectedTime = DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      print('Error parsing date: $e');
    }
    department = appointment['department'];
    doctor = appointment['doctor'];
    appointmentType = appointment['type'];
    reasonController.text = appointment['reason'] ?? '';
  }

  Future<List<String>> getTimeSlots() async {
    if (department == null || doctor == null || selectedDate == null) {
      return [];
    }
    final dayOfWeek = DateFormat('EEEE').format(selectedDate!);
    final selectedDoctor = doctorList.firstWhere(
      (doc) => doc['name'] == doctor && doc['department'] == department,
      orElse: () => {},
    );
    if (selectedDoctor.isEmpty) {
      return [];
    }
    final availability = selectedDoctor['availability']?[dayOfWeek];
    if (availability is! List) {
      return [];
    }
    final bookedSlots = await Provider.of<AppointmentService>(
      context,
      listen: false,
    ).getBookedSlots(doctor!, selectedDate!);
    final currentTime = DateFormat(
      'hh:mm a',
    ).format(_dateFormat.parse(widget.appointment['date']));
    final availableSlots = List<String>.from(availability)
        .where((slot) => !bookedSlots.contains(slot) || slot == currentTime)
        .toList();
    return availableSlots;
  }

  Future<void> _loadDepartmentsAndDoctors() async {
    final doctorService = Provider.of<DoctorService>(context, listen: false);
    final doctors = await doctorService.loadDoctors();
    setState(() {
      doctorList = doctors.map((doc) {
        final availability = doc['availability'] as Map<String, dynamic>;
        return {
          ...doc,
          'availability': availability.map((key, value) {
            return MapEntry(
              key,
              value is List ? List<String>.from(value) : <String>[],
            );
          }),
        };
      }).toList();
      departments =
          doctors.map((doc) => doc['department'] as String).toSet().toList()
            ..sort();
    });
  }

  Future<void> _submit() async {
    String? errorMessage;
    if (selectedDate == null) {
      errorMessage = 'Please select a date.';
    } else if (selectedTime == null) {
      errorMessage = 'Please select a time slot.';
    } else if (department == null) {
      errorMessage = 'Please select a department.';
    } else if (doctor == null) {
      errorMessage = 'Please select a doctor.';
    } else if (appointmentType == null) {
      errorMessage = 'Please select an appointment type.';
    } else {
      final appointmentService = Provider.of<AppointmentService>(
        context,
        listen: false,
      );
      final isBooked = await appointmentService.isTimeSlotBooked(
        doctor!,
        selectedDate!,
        selectedTime!,
      );
      final currentTime = DateFormat(
        'hh:mm a',
      ).format(_dateFormat.parse(widget.appointment['date']));
      if (isBooked && selectedTime != currentTime) {
        errorMessage =
            'This time slot is already booked for the selected doctor.';
      }
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    final updatedAppointment = {
      'avatar':
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${doctor!.replaceAll(' ', '')}',
      'doctor': doctor!,
      'department': department!,
      'type': appointmentType!,
      'date':
          DateFormat('MMM d, yyyy').format(selectedDate!) + ' at $selectedTime',
      'status': 'Upcoming',
      'reason': reasonController.text,
      'patientName': widget.appointment['patientName'],
      'userId': widget.appointment['userId'],
    };

    try {
      await Provider.of<AppointmentService>(
        context,
        listen: false,
      ).updateAppointment(widget.appointment['id'], updatedAppointment);
      final resourcesSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .where('appointmentId', isEqualTo: widget.appointment['id'])
          .get();
      for (var doc in resourcesSnapshot.docs) {
        await doc.reference.update({
          'startTime': updatedAppointment['date'],
          'endTime': DateFormat('MMM d, yyyy \'at\' hh:mm a').format(
            DateFormat(
              'MMM d, yyyy \'at\' hh:mm a',
            ).parse(updatedAppointment['date']).add(Duration(hours: 1)),
          ),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isUltraSmall = screenWidth < 360;
        final isSmall = screenWidth < 600;
        final isMedium = screenWidth < 900;

        final double padding = isUltraSmall
            ? 8
            : isSmall
            ? 12
            : 16;
        final double fontSizeTitle = isUltraSmall
            ? 14
            : isSmall
            ? 16
            : 18;
        final double fontSizeLabel = isUltraSmall
            ? 12
            : isSmall
            ? 14
            : 16;
        final double buttonHeight = isUltraSmall
            ? 40
            : isSmall
            ? 48
            : 50;
        final double calendarHeight = isUltraSmall
            ? 200
            : isSmall
            ? 250
            : 300;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Edit Appointment',
              style: GoogleFonts.poppins(
                fontSize: fontSizeTitle,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            elevation: 2,
            backgroundColor: Colors.white,
            shadowColor: Colors.indigo.withOpacity(0.2),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: widget.isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormFields(
                        fontSizeLabel: fontSizeLabel,
                        padding: padding,
                        calendarHeight: calendarHeight,
                        buttonHeight: buttonHeight,
                        isUltraSmall: isUltraSmall,
                        isSmall: isSmall,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: _buildDateTimeFields(
                              fontSizeLabel: fontSizeLabel,
                              padding: padding,
                              calendarHeight: calendarHeight,
                              isUltraSmall: isUltraSmall,
                              isSmall: isSmall,
                            ),
                          ),
                        ),
                        SizedBox(width: padding),
                        Expanded(
                          child: Column(
                            children: _buildDetailsFields(
                              fontSizeLabel: fontSizeLabel,
                              padding: padding,
                              buttonHeight: buttonHeight,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDateTimeFields({
    required double fontSizeLabel,
    required double padding,
    required double calendarHeight,
    required bool isUltraSmall,
    required bool isSmall,
  }) {
    return [
      Text(
        'Select Date & Time',
        style: GoogleFonts.poppins(
          fontSize: fontSizeLabel,
          fontWeight: FontWeight.w500,
          color: Colors.indigo[900],
        ),
      ),
      SizedBox(height: padding * 0.75),
      Container(
        height: calendarHeight,
        constraints: BoxConstraints(maxWidth: 400),
        child: CalendarDatePicker(
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 365 * 10)),
          lastDate: DateTime.now().add(Duration(days: 365)),
          onDateChanged: (date) => setState(() {
            selectedDate = date;
            selectedTime = null;
          }),
        ),
      ),
      SizedBox(height: padding * 0.75),
      Text(
        'Available Time Slots',
        style: GoogleFonts.poppins(
          fontSize: fontSizeLabel,
          fontWeight: FontWeight.w500,
          color: Colors.indigo[900],
        ),
      ),
      SizedBox(height: padding * 0.5),
      FutureBuilder<List<String>>(
        future: getTimeSlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(color: Colors.indigo[700]);
          }
          if (snapshot.hasError) {
            return Text(
              'Error loading time slots: ${snapshot.error}',
              style: GoogleFonts.poppins(
                fontSize: isUltraSmall
                    ? 10
                    : isSmall
                    ? 12
                    : 14,
                color: Colors.red[600],
              ),
            );
          }
          final timeSlots = snapshot.data ?? [];
          if (timeSlots.isEmpty &&
              department != null &&
              doctor != null &&
              selectedDate != null) {
            return Text(
              'No available time slots for selected doctor and date.',
              style: GoogleFonts.poppins(
                fontSize: isUltraSmall
                    ? 10
                    : isSmall
                    ? 12
                    : 14,
                color: Colors.red[600],
              ),
            );
          }
          return Wrap(
            spacing: isUltraSmall
                ? 4
                : isSmall
                ? 6
                : 8,
            runSpacing: isUltraSmall
                ? 4
                : isSmall
                ? 6
                : 8,
            children: timeSlots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(
                      slot,
                      style: GoogleFonts.poppins(
                        fontSize: isUltraSmall
                            ? 10
                            : isSmall
                            ? 12
                            : 14,
                      ),
                    ),
                    selected: selectedTime == slot,
                    onSelected: (_) => setState(() {
                      selectedTime = slot;
                    }),
                    selectedColor: Colors.indigo[700],
                    labelStyle: GoogleFonts.poppins(
                      color: selectedTime == slot
                          ? Colors.white
                          : Colors.indigo[700],
                      fontSize: isUltraSmall
                          ? 10
                          : isSmall
                          ? 12
                          : 14,
                    ),
                    backgroundColor: Colors.indigo.withOpacity(0.05),
                    side: BorderSide(color: Colors.indigo[700]!),
                    padding: EdgeInsets.symmetric(
                      horizontal: isUltraSmall
                          ? 8
                          : isSmall
                          ? 10
                          : 12,
                      vertical: isUltraSmall
                          ? 4
                          : isSmall
                          ? 6
                          : 8,
                    ),
                    elevation: selectedTime == slot ? 2 : 0,
                  ),
                )
                .toList(),
          );
        },
      ),
    ];
  }

  List<Widget> _buildDetailsFields({
    required double fontSizeLabel,
    required double padding,
    required double buttonHeight,
  }) {
    return [
      Text(
        'Appointment Details',
        style: GoogleFonts.poppins(
          fontSize: fontSizeLabel,
          fontWeight: FontWeight.w500,
          color: Colors.indigo[900],
        ),
      ),
      SizedBox(height: padding * 0.75),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Department',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.indigo.withOpacity(0.05),
          labelStyle: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
        value: department,
        items: departments
            .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
            .toList(),
        onChanged: (value) => setState(() {
          department = value;
          doctor = null;
          selectedTime = null;
        }),
        hint: Text(
          'Select Department',
          style: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
      ),
      SizedBox(height: padding * 0.75),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Doctor',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.indigo.withOpacity(0.05),
          labelStyle: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
        value: doctor,
        items: doctors
            .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
            .toList(),
        onChanged: (value) => setState(() {
          doctor = value;
          selectedTime = null;
        }),
        hint: Text(
          'Select Doctor',
          style: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
      ),
      SizedBox(height: padding * 0.75),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Appointment Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.indigo.withOpacity(0.05),
          labelStyle: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
        value: appointmentType,
        items: appointmentTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) => setState(() {
          appointmentType = value;
        }),
        hint: Text(
          'Select Appointment Type',
          style: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
      ),
      SizedBox(height: padding * 0.75),
      TextFormField(
        controller: reasonController,
        decoration: InputDecoration(
          labelText: 'Reason for Appointment',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.indigo.withOpacity(0.05),
          labelStyle: GoogleFonts.poppins(fontSize: fontSizeLabel * 0.9),
        ),
        minLines: 3,
        maxLines: 5,
      ),
      SizedBox(height: padding * 1.5),
      ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        child: Text(
          'Update Appointment',
          style: GoogleFonts.poppins(
            fontSize: fontSizeLabel * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFormFields({
    required double fontSizeLabel,
    required double padding,
    required double calendarHeight,
    required double buttonHeight,
    required bool isUltraSmall,
    required bool isSmall,
  }) {
    return [
      ..._buildDateTimeFields(
        fontSizeLabel: fontSizeLabel,
        padding: padding,
        calendarHeight: calendarHeight,
        isUltraSmall: isUltraSmall,
        isSmall: isSmall,
      ),
      SizedBox(height: padding),
      ..._buildDetailsFields(
        fontSizeLabel: fontSizeLabel,
        padding: padding,
        buttonHeight: buttonHeight,
      ),
    ];
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}
