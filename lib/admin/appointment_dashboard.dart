import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAppointmentsPage extends StatefulWidget {
  final bool isMobile;

  const AdminAppointmentsPage({Key? key, required this.isMobile})
    : super(key: key);

  @override
  _AdminAppointmentsPageState createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  String _selectedDepartment = 'All';
  String _selectedDoctor = 'All';
  String _selectedStatus = 'All'; // Added status filter
  List<String> _departments = ['All'];
  List<String> _doctors = ['All'];
  final List<String> _statusOptions = [
    'All',
    'Upcoming',
    'Done',
    'Rescheduled',
    'Cancelled',
  ];
  final List<String> _defaultTimeSlots = [
    '08:00 AM-10:00 AM',
    '10:00 AM-12:00 PM',
    '01:00 PM-03:00 PM',
    '03:00 PM-05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchDoctors();
  }

  Future<void> _fetchDepartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      print('Fetching departments. Total documents: ${snapshot.docs.length}');
      final departments =
          snapshot.docs
              .map((doc) => doc.data()['department'] as String?)
              .where((dept) => dept != null)
              .map((dept) => dept!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _departments = ['All', ...departments];
        if (!_departments.contains('Orthopedics')) {
          _departments.add('Orthopedics');
        }
        if (!_departments.contains('Neurology')) {
          _departments.add('Neurology');
        }
        _departments.sort();
        print('Departments loaded: $_departments');
      });
    } catch (e, stackTrace) {
      print('Error fetching departments: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      print('Fetching doctors. Total documents: ${snapshot.docs.length}');
      final doctors =
          snapshot.docs
              .map((doc) => doc.data()['doctor'] as String?)
              .where((doctor) => doctor != null)
              .map((doctor) => doctor!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _doctors = ['All', ...doctors];
        print('Doctors loaded: $_doctors');
      });
    } catch (e, stackTrace) {
      print('Error fetching doctors: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<List<Map<String, dynamic>>> _getDepartmentStats() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final dateFormat = DateFormat('MMM d, yyyy \'at\' hh:mm a');
      print(
        'Filtering appointments after: ${dateFormat.format(thirtyDaysAgo)}',
      );

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'appointments',
      );

      // Apply filters based on selected department, doctor, and status
      if (_selectedDepartment != 'All') {
        query = query.where('department', isEqualTo: _selectedDepartment);
        print('Filtering stats by department: $_selectedDepartment');
      }
      if (_selectedDoctor != 'All') {
        query = query.where('doctor', isEqualTo: _selectedDoctor);
        print('Filtering stats by doctor: $_selectedDoctor');
      }
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
        print('Filtering stats by status: $_selectedStatus');
      }

      final appointmentSnapshot = await query.get();
      print('Appointments found: ${appointmentSnapshot.docs.length}');

      final departmentCounts = <String, int>{};
      final filteredDocs = appointmentSnapshot.docs.where((doc) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr == null) {
          print('Skipping appointment with missing date: ${doc.id}');
          return false;
        }
        try {
          final date = dateFormat.parse(dateStr);
          return date.isAfter(thirtyDaysAgo) ||
              date.isAtSameMomentAs(thirtyDaysAgo);
        } catch (e) {
          print(
            'Error parsing date for appointment ${doc.id}: $dateStr, error: $e',
          );
          return false;
        }
      }).toList();

      print('Filtered appointments (last 30 days): ${filteredDocs.length}');

      for (var doc in filteredDocs) {
        final data = doc.data();
        final department = data['department'] as String? ?? 'Unknown';
        print('Processing appointment: dept=$department, docId=${doc.id}');
        departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
      }

      final result =
          departmentCounts.entries
              .map((e) => {'department': e.key, 'appointments': e.value})
              .toList()
            ..sort(
              (a, b) =>
                  (a['department'] as String?)?.compareTo(
                    b['department'] as String? ?? '',
                  ) ??
                  0,
            );
      print('Department stats: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error fetching department stats: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Map<String, List<String>> _getFallbackAvailability() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Map.fromEntries(
      days.map((day) => MapEntry(day, List.from(_defaultTimeSlots))),
    );
  }

  Future<Map<String, List<String>>> _getDoctorAvailability(
    String doctorName,
    String department,
  ) async {
    try {
      print('Fetching availability for doctor: $doctorName, dept: $department');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: doctorName)
          .where('department', isEqualTo: department)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print(
          'No doctor found for name: $doctorName in department: $department',
        );
        return _getFallbackAvailability();
      }

      final doctorData = querySnapshot.docs.first.data();
      final availability = doctorData['availability'] as Map<String, dynamic>?;

      if (availability == null || availability.isEmpty) {
        print('No availability data for doctor: $doctorName');
        return _getFallbackAvailability();
      }

      final validatedAvailability = <String, List<String>>{};
      for (var entry in availability.entries) {
        final day = entry.key;
        final slots = entry.value as List<dynamic>? ?? [];
        validatedAvailability[day] = slots
            .map((slot) => slot.toString())
            .where((slot) => slot.isNotEmpty)
            .toList();
      }

      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      for (var day in days) {
        validatedAvailability.putIfAbsent(
          day,
          () => List.from(_defaultTimeSlots),
        );
        if (validatedAvailability[day]!.isEmpty) {
          validatedAvailability[day] = List.from(_defaultTimeSlots);
        }
      }

      print('Validated availability: $validatedAvailability');
      return validatedAvailability;
    } catch (e, stackTrace) {
      print('Error fetching doctor availability: $e');
      print('Stack trace: $stackTrace');
      return _getFallbackAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Appointments',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.indigo[900],
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Manage and view patient appointments',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.indigo[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildFilters(),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Patients by Department',
                            style: GoogleFonts.poppins(
                              fontSize: widget.isMobile ? 18 : 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[900],
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bar_chart,
                            color: Colors.indigo[700],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(color: Colors.indigo[100], thickness: 1),
                    SizedBox(height: 12),
                    SizedBox(
                      height: widget.isMobile ? 230 : 280,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getDepartmentStats(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: widget.isMobile ? 230 : 280,
                              child: Center(child: _buildLoadingIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            print(
                              'Error in Patients by Department: ${snapshot.error}',
                            );
                            return SizedBox(
                              height: widget.isMobile ? 230 : 280,
                              child: Center(
                                child: Text(
                                  'Error loading data. Please check authentication or contact support.',
                                  style: GoogleFonts.poppins(
                                    fontSize: widget.isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          final departments = snapshot.data ?? [];
                          if (departments.isEmpty) {
                            print(
                              'No department data found. Check Firestore appointments collection and user permissions.',
                            );
                            return SizedBox(
                              height: widget.isMobile ? 230 : 280,
                              child: Center(
                                child: Text(
                                  'No department data available. Ensure you are logged in as an admin and appointments exist.',
                                  style: GoogleFonts.poppins(
                                    fontSize: widget.isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          print(
                            'Departments loaded: ${departments.map((d) => d['department']).toList()}',
                          );
                          final maxY =
                              departments
                                  .map((dept) => dept['appointments'] as int)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() *
                              1.2;
                          return Column(
                            children: [
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY > 0 ? maxY : 10.0,
                                    barGroups: departments.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final dept = entry.value;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: dept['appointments']
                                                .toDouble(),
                                            color: Colors.indigo[700],
                                            width: widget.isMobile ? 10 : 16,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            backDrawRodData:
                                                BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: maxY,
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                ),
                                          ),
                                        ],
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
                                                  fontSize: widget.isMobile
                                                      ? 12
                                                      : 14,
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
                                            final dept =
                                                departments[value
                                                    .toInt()]['department'];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Transform.rotate(
                                                angle: widget.isMobile
                                                    ? -45 * 3.14159 / 180
                                                    : 0,
                                                child: Text(
                                                  dept,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: widget.isMobile
                                                        ? 10
                                                        : 12,
                                                    color: Colors.grey[800],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: Colors.grey[300]!,
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
                                          color: Colors.grey[300],
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => Colors
                                            .indigo[900]!
                                            .withOpacity(0.8),
                                        getTooltipItem:
                                            (group, groupIdx, rod, rodIdx) {
                                              final dept =
                                                  departments[group.x
                                                      .toInt()]['department'];
                                              return BarTooltipItem(
                                                '$dept\n${rod.toY.toInt()} Patients',
                                                GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Patients by Department (Last 30 Days)',
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Appointment List',
                            style: GoogleFonts.poppins(
                              fontSize: widget.isMobile ? 18 : 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[900],
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Colors.indigo[700],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(color: Colors.indigo[100], thickness: 1),
                    SizedBox(height: 12),
                    _buildAppointmentList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: GoogleFonts.poppins(
            fontSize: widget.isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.indigo[900],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        widget.isMobile
            ? Column(
                children: [
                  _buildDepartmentDropdown(),
                  SizedBox(height: 12),
                  _buildDoctorDropdown(),
                  SizedBox(height: 12),
                  _buildStatusDropdown(), // Added status dropdown
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildDepartmentDropdown()),
                  SizedBox(width: 16),
                  Expanded(child: _buildDoctorDropdown()),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusDropdown(),
                  ), // Added status dropdown
                ],
              ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedStatus,
        isExpanded: true,
        underline: SizedBox(),
        items: _statusOptions.map<DropdownMenuItem<String>>((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.indigo[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedStatus = value ?? 'All';
            print('Selected status: $_selectedStatus');
          });
        },
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedDepartment,
        isExpanded: true,
        underline: SizedBox(),
        items: _departments.map<DropdownMenuItem<String>>((String dept) {
          return DropdownMenuItem<String>(
            value: dept,
            child: Text(
              dept,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.indigo[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedDepartment = value ?? 'All';
            _selectedDoctor = 'All'; // Reset doctor when department changes
            print('Selected department: $_selectedDepartment');
          });
        },
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedDoctor,
        isExpanded: true,
        underline: SizedBox(),
        items: _doctors.map<DropdownMenuItem<String>>((String doctor) {
          return DropdownMenuItem<String>(
            value: doctor,
            child: Text(
              doctor,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 15 : 17,
                color: Colors.indigo[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedDoctor = value ?? 'All';
            print('Selected doctor: $_selectedDoctor');
          });
        },
      ),
    );
  }

  Widget _buildAppointmentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildAppointmentStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Stream is waiting');
          return Center(child: _buildLoadingIndicator());
        }
        if (snapshot.hasError) {
          print('Error in Appointment List: ${snapshot.error}');
          return Text(
            'Error loading appointments: ${snapshot.error}',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print(
            'No appointment data found. Docs: ${snapshot.data?.docs.length ?? 0}',
          );
          return Text(
            'No appointments available.',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          );
        }
        final appointments = snapshot.data!.docs;
        print('Found ${appointments.length} appointments');
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointmentData =
                appointments[index].data() as Map<String, dynamic>? ?? {};
            final appointmentId = appointments[index].id;
            final userId = appointmentData['userId'] as String? ?? 'Unknown';
            final department =
                appointmentData['department'] as String? ?? 'Unknown';
            final doctor = appointmentData['doctor'] as String? ?? 'Unknown';
            final type = appointmentData['type'] as String? ?? 'Unknown';
            final date = appointmentData['date'] as String? ?? 'Unknown';
            final status = appointmentData['status'] as String? ?? 'Upcoming';
            final reason = appointmentData['reason'] as String? ?? '';
            final patientId =
                appointmentData['patientId'] as String? ?? 'Unknown';
            print(
              'Rendering appointment: patientId=$patientId, dept=$department, date=$date',
            );
            return Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Patient ID: $patientId',
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: DropdownButton<String>(
                          value: _statusOptions.contains(status)
                              ? status
                              : 'Upcoming',
                          underline: SizedBox(),
                          items: _statusOptions.map((String statusOption) {
                            return DropdownMenuItem<String>(
                              value: statusOption,
                              child: Text(
                                'Status: $statusOption',
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 14 : 16,
                                  color: _getStatusColor(statusOption),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newStatus) async {
                            if (newStatus != null && newStatus != status) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please sign in to update status.',
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

                              bool shouldProceed = false;
                              DateTime? newDateTime;
                              String formattedDate = date;

                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    title: Text(
                                      'Update Appointment Status',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo[900],
                                      ),
                                    ),
                                    content: newStatus == 'Rescheduled'
                                        ? SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Select a new date and time for the rescheduled appointment.',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                FutureBuilder<
                                                  Map<String, List<String>>
                                                >(
                                                  future:
                                                      _getDoctorAvailability(
                                                        doctor,
                                                        department,
                                                      ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return _buildLoadingIndicator();
                                                    }
                                                    if (snapshot.hasError) {
                                                      print(
                                                        'Error loading availability: ${snapshot.error}',
                                                      );
                                                      return Text(
                                                        'Error loading availability. Using default slots.',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .red[600],
                                                            ),
                                                      );
                                                    }
                                                    final availability =
                                                        snapshot.data ??
                                                        _getFallbackAvailability();
                                                    if (availability.isEmpty) {
                                                      return Text(
                                                        'No availability found. Using default slots.',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .red[600],
                                                            ),
                                                      );
                                                    }
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        _buildStyledButton(
                                                          context: context,
                                                          text:
                                                              'Select Date & Time',
                                                          onPressed: () async {
                                                            final now =
                                                                DateTime.now();
                                                            final pickedDate = await showDatePicker(
                                                              context: context,
                                                              initialDate: now
                                                                  .add(
                                                                    Duration(
                                                                      days: 1,
                                                                    ),
                                                                  ),
                                                              firstDate: now,
                                                              lastDate: now.add(
                                                                Duration(
                                                                  days: 365,
                                                                ),
                                                              ),
                                                              selectableDayPredicate: (DateTime day) {
                                                                final dayName =
                                                                    DateFormat(
                                                                      'EEEE',
                                                                    ).format(
                                                                      day,
                                                                    );
                                                                final slots =
                                                                    availability[dayName] ??
                                                                    [];
                                                                return slots
                                                                    .isNotEmpty;
                                                              },
                                                            );
                                                            if (pickedDate !=
                                                                null) {
                                                              final dayName =
                                                                  DateFormat(
                                                                    'EEEE',
                                                                  ).format(
                                                                    pickedDate,
                                                                  );
                                                              final availableSlots =
                                                                  availability[dayName] ??
                                                                  [];
                                                              if (availableSlots
                                                                  .isEmpty) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'No available slots for $dayName.',
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red[600],
                                                                  ),
                                                                );
                                                                return;
                                                              }
                                                              final pickedSlot = await showDialog<String>(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: Text(
                                                                    'Select Time Slot',
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .indigo[900],
                                                                    ),
                                                                  ),
                                                                  content: SingleChildScrollView(
                                                                    child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: availableSlots.map((
                                                                        slot,
                                                                      ) {
                                                                        return ListTile(
                                                                          title: Text(
                                                                            slot,
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize: 14,
                                                                              color: Colors.grey[800],
                                                                            ),
                                                                          ),
                                                                          onTap: () {
                                                                            Navigator.of(
                                                                              context,
                                                                            ).pop(
                                                                              slot,
                                                                            );
                                                                          },
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.of(
                                                                            context,
                                                                          ).pop(),
                                                                      child: Text(
                                                                        'Cancel',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.red[600],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              if (pickedSlot !=
                                                                  null) {
                                                                final slotParts =
                                                                    pickedSlot
                                                                        .split(
                                                                          '-',
                                                                        );
                                                                final startTimeStr =
                                                                    slotParts[0]
                                                                        .trim();
                                                                try {
                                                                  final timeFormat =
                                                                      DateFormat(
                                                                        'hh:mm a',
                                                                      );
                                                                  final startTime =
                                                                      timeFormat
                                                                          .parse(
                                                                            startTimeStr,
                                                                          );
                                                                  newDateTime = DateTime(
                                                                    pickedDate
                                                                        .year,
                                                                    pickedDate
                                                                        .month,
                                                                    pickedDate
                                                                        .day,
                                                                    startTime
                                                                        .hour,
                                                                    startTime
                                                                        .minute,
                                                                  );
                                                                  if (newDateTime!
                                                                      .isBefore(
                                                                        now,
                                                                      )) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          'Cannot schedule in the past.',
                                                                          style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                        backgroundColor:
                                                                            Colors.red[600],
                                                                      ),
                                                                    );
                                                                    return;
                                                                  }
                                                                  final isSlotAvailable = await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                        'appointments',
                                                                      )
                                                                      .where(
                                                                        'doctor',
                                                                        isEqualTo:
                                                                            doctor,
                                                                      )
                                                                      .where(
                                                                        'date',
                                                                        isEqualTo:
                                                                            DateFormat(
                                                                              'MMM d, yyyy \'at\' hh:mm a',
                                                                            ).format(
                                                                              newDateTime!,
                                                                            ),
                                                                      )
                                                                      .get()
                                                                      .then(
                                                                        (
                                                                          snapshot,
                                                                        ) => snapshot
                                                                            .docs
                                                                            .isEmpty,
                                                                      );
                                                                  if (!isSlotAvailable) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          'Selected slot is already booked.',
                                                                          style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                        backgroundColor:
                                                                            Colors.red[600],
                                                                      ),
                                                                    );
                                                                    return;
                                                                  }
                                                                  formattedDate =
                                                                      DateFormat(
                                                                        'MMM d, yyyy \'at\' hh:mm a',
                                                                      ).format(
                                                                        newDateTime!,
                                                                      );
                                                                  shouldProceed =
                                                                      true;
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop();
                                                                } catch (e) {
                                                                  print(
                                                                    'Error parsing time slot $startTimeStr: $e',
                                                                  );
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Invalid time slot format.',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red[600],
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          },
                                                          backgroundColor:
                                                              Colors.blue[300],
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text(
                                            'Are you sure you want to change the status to $newStatus?',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          shouldProceed = true;
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Confirm',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.indigo[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (!shouldProceed) {
                                print('Status update cancelled by user');
                                return;
                              }

                              try {
                                final updateData = {
                                  'status': newStatus,
                                  'updated_at': DateFormat(
                                    'MMM d, yyyy \'at\' hh:mm a',
                                  ).format(DateTime.now()),
                                };

                                if (newStatus == 'Rescheduled' &&
                                    newDateTime != null) {
                                  updateData['date'] = formattedDate;
                                }

                                await FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc(appointmentId)
                                    .update(updateData);

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('appointment_history')
                                    .add({...appointmentData, ...updateData});

                                print(
                                  'Appointment $appointmentId updated to status: $newStatus${newStatus == 'Rescheduled' ? ' with new date: $formattedDate' : ''}',
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Status updated to $newStatus successfully${newStatus == 'Rescheduled' ? ' for $formattedDate' : ''}.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.green[600],
                                  ),
                                );
                              } catch (e) {
                                print(
                                  'Error updating appointment $appointmentId: $e',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error updating status: $e',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red[600],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Department: $department',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Doctor: $doctor',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Type: $type',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Date and Time: $date',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 12 : 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Reason: $reason',
                      style: GoogleFonts.poppins(
                        fontSize: widget.isMobile ? 12 : 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildAppointmentStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'appointments',
    );
    if (_selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: _selectedDepartment);
      print('Filtering by department: $_selectedDepartment');
    }
    if (_selectedDoctor != 'All') {
      query = query.where('doctor', isEqualTo: _selectedDoctor);
      print('Filtering by doctor: $_selectedDoctor');
    }
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
      print('Filtering by status: $_selectedStatus');
    }
    return query.snapshots();
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        print('User not found for ID: $userId');
        return 'Unknown';
      }
      final name = userDoc.data()?['name'] as String? ?? 'Unknown';
      print('Fetched user name for ID $userId: $name');
      return name;
    } catch (e, stackTrace) {
      print('Error fetching user name for ID $userId: $e');
      print('Stack trace: $stackTrace');
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue[600]!;
      case 'Done':
        return Colors.green[600]!;
      case 'Rescheduled':
        return Colors.orange[600]!;
      case 'Cancelled':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 6),
        Text(
          'Loading Data...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.indigo[900],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.indigo[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.indigo.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
