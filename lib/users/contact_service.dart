import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveContactMessage({
    required String name,
    required String email,
    required String mobileNumber,
    required String inquiryType,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      final contactData = {
        'name': name,
        'email': email,
        'mobileNumber': mobileNumber,
        'inquiryType': inquiryType,
        'message': message,
        'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
        'userId': user?.uid ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('contact_messages').add(contactData);
      notifyListeners();
    } catch (e) {
      print('Error saving contact message: $e');
      rethrow;
    }
  }
}

class ContactSectionWrapper extends StatefulWidget {
  @override
  _ContactSectionWrapperState createState() => _ContactSectionWrapperState();
}

class _ContactSectionWrapperState extends State<ContactSectionWrapper> {
  Key _formKey = UniqueKey();

  void _resetForm() {
    setState(() {
      _formKey = UniqueKey(); // Generate a new key to rebuild the form
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContactSection(key: _formKey, onSubmitted: _resetForm);
  }
}

class ContactSection extends StatefulWidget {
  final VoidCallback onSubmitted;

  ContactSection({Key? key, required this.onSubmitted}) : super(key: key);

  @override
  _ContactSectionState createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedInquiryType = 'Type of Inquiry';
  final List<String> _inquiryTypes = [
    'Type of Inquiry',
    'Service Inquiry',
    'Doctor\'s Appointment',
    'Complaint',
    'Commendation',
    'Packages',
  ];

  bool _isSubmitting = false;

  void _submitContactForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final contactService = Provider.of<ContactService>(
        context,
        listen: false,
      );
      await contactService.saveContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        inquiryType: _selectedInquiryType,
        message: _messageController.text.trim(),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Trigger form rebuild after showing SnackBar
      Future.microtask(() => widget.onSubmitted());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          color: Color(0xFFF8FAFC),
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 24 : 40,
            horizontal: constraints.maxWidth * 0.05,
          ),
          child: Column(
            children: [
              SectionHeader(
                title: 'Contact Us',
                subtitle: 'Get in touch with our team for any inquiries.',
              ),
              SizedBox(height: isMobile ? 12 : 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('Name', isMobile),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),

                        // Email + Mobile Number Layout
                        isMobile
                            ? Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: _inputDecoration(
                                      'Email',
                                      isMobile,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty ||
                                          !value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  // Mobile Number
                                  TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration(
                                      'Mobile Number',
                                      isMobile,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your mobile number';
                                      }
                                      if (!RegExp(
                                        r'^[0-9]{10,11}$',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid mobile number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Email - 65%
                                  Expanded(
                                    flex: 65,
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: _inputDecoration(
                                        'Email',
                                        isMobile,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty ||
                                            !value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Mobile Number - 35%
                                  Expanded(
                                    flex: 35,
                                    child: TextFormField(
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDecoration(
                                        'Mobile Number',
                                        isMobile,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your mobile number';
                                        }
                                        if (!RegExp(
                                          r'^[0-9]{10,11}$',
                                        ).hasMatch(value)) {
                                          return 'Please enter a valid mobile number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        SizedBox(height: 12),

                        // Type of Inquiry
                        DropdownButtonFormField<String>(
                          value: _selectedInquiryType,
                          decoration: _inputDecoration(
                            'Type of Inquiry',
                            isMobile,
                          ),
                          items: _inquiryTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 15,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedInquiryType = value!);
                          },
                          validator: (value) {
                            if (value == null || value == 'Type of Inquiry') {
                              return 'Please select inquiry type';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),

                        // Message
                        TextFormField(
                          controller: _messageController,
                          decoration: _inputDecoration('Message', isMobile),
                          minLines: 4,
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your message';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),

                        // Submit Button
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _submitContactForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16,
                                horizontal: isMobile ? 24 : 32,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.indigo.withOpacity(0.3),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: isMobile ? 20 : 24,
                                    width: isMobile ? 20 : 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Send Message',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, bool isMobile) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.indigo.withOpacity(0.05),
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey[600],
        fontSize: isMobile ? 14 : 15,
      ),
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey[400],
        fontSize: isMobile ? 14 : 15,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
