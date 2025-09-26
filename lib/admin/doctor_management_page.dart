import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../users/doctor_service.dart';

class DoctorManagementPage extends StatefulWidget {
  final bool isMobile;

  const DoctorManagementPage({Key? key, required this.isMobile})
    : super(key: key);

  @override
  _DoctorManagementPageState createState() => _DoctorManagementPageState();
}

class _DoctorManagementPageState extends State<DoctorManagementPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _department;
  Map<String, List<String>> _availability = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };
  final List<String> _defaultTimeSlots = [
    '08:00 AM-10:00 AM',
    '10:00 AM-12:00 PM',
    '01:00 PM-03:00 PM',
    '03:00 PM-05:00 PM',
  ];
  final List<String> _departments = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Dermatology',
  ];
  String _selectedDepartment = 'All';
  String _searchQuery = '';

  void _showAddDoctorDialog({Map<String, dynamic>? doctor}) {
    if (doctor != null) {
      _name = doctor['name'];
      _department = doctor['department'];
      _availability = Map<String, List<String>>.from(
        doctor['availability'] ?? {},
      );
    } else {
      _name = null;
      _department = null;
      _availability = {
        'Monday': [],
        'Tuesday': [],
        'Wednesday': [],
        'Thursday': [],
        'Friday': [],
        'Saturday': [],
        'Sunday': [],
      };
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
              title: Text(
                doctor == null ? 'Add Doctor' : 'Edit Doctor',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[900],
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: _name,
                        decoration: InputDecoration(
                          labelText: 'Doctor Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          filled: true,
                          fillColor: Colors.indigo[50],
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.indigo[700],
                            size: 18,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 13 : 14,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a name' : null,
                        onChanged: (value) => _name = value,
                      ),
                      SizedBox(height: 8),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          filled: true,
                          fillColor: Colors.indigo[50],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _department,
                            isExpanded: true,
                            hint: Text(
                              'Select Department',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 13 : 14,
                              ),
                            ),
                            items: _departments.map((String department) {
                              return DropdownMenuItem<String>(
                                value: department,
                                child: Text(
                                  department,
                                  style: GoogleFonts.poppins(
                                    fontSize: widget.isMobile ? 13 : 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _department = newValue;
                              });
                            },
                            style: GoogleFonts.poppins(
                              fontSize: widget.isMobile ? 13 : 14,
                              color: Colors.indigo[900],
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.indigo[700],
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Availability',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 12 : 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo[900],
                        ),
                      ),
                      ..._availability.keys.map((day) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              day,
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo[700],
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: _defaultTimeSlots.map((slot) {
                                final isSelected = _availability[day]!.contains(
                                  slot,
                                );
                                return ChoiceChip(
                                  label: Text(
                                    slot,
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.isMobile ? 10 : 11,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _availability[day]!.add(slot);
                                      } else {
                                        _availability[day]!.remove(slot);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.indigo[700],
                                  labelStyle: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.indigo[700],
                                    fontSize: widget.isMobile ? 10 : 11,
                                  ),
                                  backgroundColor: Colors.indigo[50],
                                  side: BorderSide(
                                    color: Colors.indigo[700]!,
                                    width: 0.5,
                                  ),
                                  elevation: isSelected ? 1 : 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.indigo[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_department == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select a department',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: Colors.red[600],
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        );
                        return;
                      }
                      final doctorService = Provider.of<DoctorService>(
                        context,
                        listen: false,
                      );
                      final doctorData = {
                        'name': _name,
                        'department': _department,
                        'availability': _availability,
                      };
                      try {
                        if (doctor == null) {
                          await doctorService.addDoctor(doctorData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Doctor added successfully',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              backgroundColor: Colors.green[600],
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          );
                        } else {
                          await doctorService.updateDoctor(
                            doctor['id'],
                            doctorData,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Doctor updated successfully',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              backgroundColor: Colors.green[600],
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          );
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: $e',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: Colors.red[400],
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 1,
                  ),
                  child: Text(
                    doctor == null ? 'Add' : 'Update',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.indigo[200]!, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedDepartment,
        isExpanded: true,
        underline: SizedBox(),
        items: ['All', ..._departments].map((String department) {
          return DropdownMenuItem<String>(
            value: department,
            child: Text(
              department,
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 13 : 14,
                color: Colors.indigo[900],
              ),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedDepartment = value ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search doctors...',
        prefixIcon: Icon(Icons.search, color: Colors.indigo[700], size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        filled: true,
        fillColor: Colors.indigo[50],
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
      style: GoogleFonts.poppins(fontSize: widget.isMobile ? 13 : 14),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doctor Management',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[900],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAddDoctorDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 12 : 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shadowColor: Colors.indigo.withOpacity(0.3),
                ),
                child: Text(
                  'Add Doctor',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDepartmentDropdown(),
                    SizedBox(height: 8),
                    _buildSearchBar(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDepartmentDropdown()),
                    SizedBox(width: 12),
                    Expanded(child: _buildSearchBar()),
                  ],
                ),
          SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Provider.of<DoctorService>(context).loadDoctors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.indigo[700]),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No doctors available.',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }
              final doctors = snapshot.data!
                  .where(
                    (doctor) =>
                        _selectedDepartment == 'All' ||
                        doctor['department'] == _selectedDepartment,
                  )
                  .where(
                    (doctor) =>
                        _searchQuery.isEmpty ||
                        doctor['name'].toLowerCase().contains(_searchQuery),
                  )
                  .toList();

              // Group doctors by department
              final groupedDoctors = <String, List<Map<String, dynamic>>>{};
              for (var doctor in doctors) {
                final dept = doctor['department'] as String? ?? 'Unknown';
                groupedDoctors[dept] = groupedDoctors[dept] ?? [];
                groupedDoctors[dept]!.add(doctor);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedDoctors.entries.map((entry) {
                  final department = entry.key;
                  final deptDoctors = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      widget.isMobile
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: deptDoctors.length,
                              itemBuilder: (context, index) {
                                final doctor = deptDoctors[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < deptDoctors.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  child: DoctorCard(
                                    doctor: doctor,
                                    isMobile: widget.isMobile,
                                    onEdit: () =>
                                        _showAddDoctorDialog(doctor: doctor),
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          title: Text(
                                            'Confirm Delete',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          content: Text(
                                            'Delete ${doctor['name']}?',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                'Cancel',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.indigo[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'Delete',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await Provider.of<DoctorService>(
                                          context,
                                          listen: false,
                                        ).deleteDoctor(doctor['id']);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Doctor deleted',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                              ),
                                            ),
                                            backgroundColor: Colors.green[600],
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.05,
                                  ),
                              itemCount: deptDoctors.length,
                              itemBuilder: (context, index) {
                                final doctor = deptDoctors[index];
                                return DoctorCard(
                                  doctor: doctor,
                                  isMobile: widget.isMobile,
                                  onEdit: () =>
                                      _showAddDoctorDialog(doctor: doctor),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        title: Text(
                                          'Confirm Delete',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        content: Text(
                                          'Delete ${doctor['name']}?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Cancel',
                                              style: GoogleFonts.poppins(
                                                color: Colors.indigo[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Delete',
                                              style: GoogleFonts.poppins(
                                                color: Colors.red[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await Provider.of<DoctorService>(
                                        context,
                                        listen: false,
                                      ).deleteDoctor(doctor['id']);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Doctor deleted',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: Colors.green[600],
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                      SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DoctorCard({
    Key? key,
    required this.doctor,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final List<String> _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  void _showScheduleDialog(
    BuildContext context,
    Map<String, dynamic> availability,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Doctor's Schedule",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 0.6,
              ),
            ),
            children: _days.map((day) {
              final slots = availability[day] as List<dynamic>? ?? [];
              final slotText = slots.isNotEmpty ? slots.join(', ') : '—';
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      slotText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Close",
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = doctor['name'] ?? 'Unknown';
    final String department = doctor['department'] ?? 'General';
    final double rating = (doctor['rating'] ?? 4.5).toDouble();
    final Map<String, dynamic> availability = doctor['availability'] ?? {};

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        minHeight: isMobile
            ? 200
            : 250, // Define minimum height to prevent overflow
        maxWidth: isMobile ? double.infinity : 300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min to avoid unbounded height
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: isMobile ? 30 : 32, // Slightly smaller for mobile
            backgroundColor: Colors.grey[200], // Fallback background
            child: ClipOval(
              child: Image.asset(
                "assets/logo.png",
                fit: BoxFit.contain, // Ensure entire image fits
                width: isMobile ? 60 : 64, // Match diameter (2 * radius)
                height: isMobile ? 60 : 64,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: isMobile ? 30 : 32,
                  color: Colors.indigo[700],
                ), // Fallback icon if image fails
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              department.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _showScheduleDialog(context, availability),
            icon: const Icon(Icons.schedule, size: 16),
            label: Text(
              "View Schedule",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(
                    "Edit",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                fit: FlexFit.tight,
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 14),
                  label: Text(
                    "Delete",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
