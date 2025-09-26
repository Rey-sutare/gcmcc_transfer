import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Assuming FeedbackService is in main.dart

class SurveyForm extends StatefulWidget {
  final bool isMobile;
  const SurveyForm({required this.isMobile, super.key});

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _surveyFormKey = GlobalKey<FormState>();
  final Map<String, String?> _responses = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _surveyQuestions = [
    {
      'section': 'Infrastructures and Process',
      'questions': [
        {
          'id': 'q1',
          'text':
              'The waiting areas we used were clean, orderly, and comfortable.',
          'sqd': null,
        },
        {
          'id': 'q2',
          'text':
              'The toilets and bathrooms inside the facility were kept clean, orderly and with a steady water supply.',
          'sqd': null,
        },
        {
          'id': 'q3',
          'text': 'The patients’ rooms were clean, tidy, and comfortable.',
          'sqd': null,
        },
        {
          'id': 'q4',
          'text':
              'The steps (including payment) I needed to do for my transaction were easy and simple.',
          'sqd': 'SQD3',
        },
        {
          'id': 'q5',
          'text':
              'The office followed the transaction’s requirements and steps based on the information provided.',
          'sqd': 'SQD2',
        },
        {
          'id': 'q6',
          'text':
              'I easily found information about my transaction from the office or its website.',
          'sqd': 'SQD4',
        },
        {
          'id': 'q7',
          'text': 'I spent a reasonable amount of time for my transaction.',
          'sqd': 'SQD1',
        },
      ],
    },
    {
      'section': 'Client Engagement and Empowerment',
      'questions': [
        {
          'id': 'q8',
          'text':
              'The medical condition, procedures, and instructions were discussed clearly.',
          'sqd': null,
        },
        {
          'id': 'q9',
          'text':
              'Our sentiments, cultural background, and beliefs were heard and considered in the treatment procedure.',
          'sqd': null,
        },
        {
          'id': 'q10',
          'text':
              'We were given the chance to decide which treatment procedure shall be performed.',
          'sqd': null,
        },
        {
          'id': 'q11',
          'text':
              'I got what I needed from the hospital, or (if denied) denial of request was sufficiently explained to me.',
          'sqd': 'SQD8',
        },
        {
          'id': 'q12',
          'text': 'I paid a reasonable amount of fees for my transaction.',
          'sqd': 'SQD5',
        },
      ],
    },
    {
      'section': 'Culture of Responsiveness',
      'questions': [
        {
          'id': 'q13_doctor',
          'text':
              'I was treated courteously by the Doctor, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_nurse',
          'text':
              'I was treated courteously by the Nurse, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_midwife',
          'text':
              'I was treated courteously by the Midwife, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_security',
          'text':
              'I was treated courteously by the Security, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_radiology',
          'text':
              'I was treated courteously by the Radiology Staff, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_pharmacy',
          'text':
              'I was treated courteously by the Pharmacy, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_laboratory',
          'text':
              'I was treated courteously by the Laboratory, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_admitting',
          'text':
              'I was treated courteously by the Admitting Staff, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_medical_records',
          'text':
              'I was treated courteously by the Medical Records, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_billing',
          'text':
              'I was treated courteously by the Billing, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_cashier',
          'text':
              'I was treated courteously by the Cashier, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_social_worker',
          'text':
              'I was treated courteously by the Social Worker, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_food_server',
          'text':
              'I was treated courteously by the Food Server, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q13_janitors',
          'text':
              'I was treated courteously by the Janitors/Orderly, and (if asked for help) the staff was helpful.',
          'sqd': 'SQD7',
        },
        {
          'id': 'q14',
          'text':
              'I was treated fairly, or “walang palakasan”, during my transaction. (If online: I am confident my online transaction was secure.)',
          'sqd': 'SQD6',
        },
        {
          'id': 'q15',
          'text': 'I am satisfied with the service that I availed.',
          'sqd': 'SQD0',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _ratingOptions = [
    {
      'value': 'Strongly Disagree',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.red[600],
    },
    {
      'value': 'Disagree',
      'icon': Icons.sentiment_dissatisfied,
      'color': Colors.orange[600],
    },
    {
      'value': 'Partially Agree',
      'icon': Icons.sentiment_neutral,
      'color': Colors.grey[600],
    },
    {
      'value': 'Agree',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.blue[600],
    },
    {
      'value': 'Strongly Agree',
      'icon': Icons.sentiment_very_satisfied,
      'color': Colors.green[600],
    },
    {'value': 'Not Applicable', 'icon': Icons.block, 'color': Colors.grey[400]},
  ];

  bool _isFormComplete() {
    return _surveyQuestions.every(
      (section) => section['questions'].every(
        (question) => _responses[question['id']] != null,
      ),
    );
  }

  void _submitSurvey() async {
    if (!_isFormComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please answer all rating questions before submitting.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final survey = {
      'responses': _responses,
      'comment': _commentController.text,
      'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
      'username':
          Provider.of<AuthService>(context, listen: false).fullname ?? 'Guest',
    };
    try {
      final feedbackService = Provider.of<FeedbackService>(
        context,
        listen: false,
      );
      await feedbackService.saveSurvey(survey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Survey submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _responses.clear();
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save survey: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildRatingLegend(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Legend',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: isMobile ? 8 : 12,
          runSpacing: 8,
          children: _ratingOptions.map((option) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option['icon'],
                  size: isMobile ? 20 : 24,
                  color: option['color'],
                ),
                SizedBox(width: 8),
                Text(
                  option['value'],
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _surveyFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Satisfaction Survey',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 20 : 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Please rate the following statements based on your experience.',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 14 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            _buildRatingLegend(widget.isMobile),
            SizedBox(height: 24),
            ..._surveyQuestions.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['section'],
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  ...section['questions'].map<Widget>((question) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['text'],
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _ratingOptions.map((option) {
                            final isSelected =
                                _responses[question['id']] == option['value'];
                            return Expanded(
                              child: InkWell(
                                onTap: () {
                                  print(
                                    'Tapped survey rating: ${option['value']} for ${question['id']}',
                                  ); // Debug print
                                  setState(() {
                                    _responses[question['id']] =
                                        option['value'];
                                    print(
                                      'Updated _responses[${question['id']}]: ${_responses[question['id']]}',
                                    ); // Debug print
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                splashColor: Colors.indigo.withOpacity(0.2),
                                highlightColor: Colors.indigo.withOpacity(0.1),
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 2 : 4,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: widget.isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.indigo.withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.indigo[700]!
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    option['icon'],
                                    size: widget.isMobile ? 20 : 24,
                                    color: option['color'], // Always show color
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_responses[question['id']] == null)
                          Padding(
                            padding: EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              'Please select a rating.',
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 12 : 14,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: 24),
                ],
              );
            }).toList(),
            Text(
              'Additional Comments',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Your comments (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.indigo.withOpacity(0.05),
              ),
              minLines: 4,
              maxLines: 6,
            ),
            SizedBox(height: 24),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || !_isFormComplete()
                    ? null
                    : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormComplete()
                      ? Colors.indigo[700]
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: widget.isMobile ? 14 : 16,
                    horizontal: widget.isMobile ? 24 : 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isFormComplete() ? 2 : 0,
                  shadowColor: _isFormComplete()
                      ? Colors.indigo.withOpacity(0.3)
                      : Colors.transparent,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: widget.isMobile ? 20 : 24,
                        width: widget.isMobile ? 20 : 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Submit Survey',
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
