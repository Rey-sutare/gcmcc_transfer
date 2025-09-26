import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // For AuthService

class FeedbackForm extends StatefulWidget {
  final bool isMobile;
  final String? appointmentId; // Add appointmentId parameter

  const FeedbackForm({
    required this.isMobile,
    this.appointmentId, // Optional, null for general feedback
    super.key,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final feedbackController = TextEditingController();
  int? satisfactionRating;
  bool _isSubmitting = false;

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (satisfactionRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a star rating.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final feedback = {
      'rating': satisfactionRating,
      'comment': feedbackController.text,
      'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
      'timestamp': DateTime.now(), // Store as Timestamp for consistency
      'username':
          Provider.of<AuthService>(context, listen: false).fullname ?? 'Guest',
      'type': widget.appointmentId != null ? 'appointment' : 'general',
      'read': false,
      'appointmentId': widget.appointmentId, // Include appointmentId
    };
    try {
      final feedbackService = Provider.of<FeedbackService>(
        context,
        listen: false,
      );
      final translationService = Provider.of<TranslationService>(
        context,
        listen: false,
      );

      String? commentForAnalysis = feedbackController.text.isNotEmpty
          ? feedbackController.text
          : null;
      if (commentForAnalysis != null &&
          await translationService.isTagalog(commentForAnalysis)) {
        commentForAnalysis = await translationService.translateToEnglish(
          commentForAnalysis,
          sourceLanguage: 'tl',
        );
      }

      await feedbackService.saveFeedback(feedback);
      final sentiment = commentForAnalysis != null
          ? await feedbackService.analyzeSentiment(commentForAnalysis)
          : null;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Feedback Submitted',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Text(
            sentiment == 'Positive'
                ? 'Thank you! We’re happy to hear you had a great experience. Wishing you good health!'
                : sentiment == 'Negative'
                ? 'We apologize for your experience. Your feedback helps us improve. Please contact us if we can assist further.'
                : 'Thanks for your feedback. We’ll use it to improve our services.',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 14 : 16,
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      setState(() {
        satisfactionRating = null;
        feedbackController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save feedback: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate Your Experience',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 12 : 16,
              vertical: widget.isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starPosition = index + 1;
                final isSelected =
                    satisfactionRating != null &&
                    starPosition <= satisfactionRating!;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      satisfactionRating = starPosition;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 8 : 12,
                    ),
                    child: Icon(
                      Icons.star,
                      size: widget.isMobile ? 32 : 36,
                      color: isSelected ? Colors.yellow[700] : Colors.grey[500],
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 8),
          if (satisfactionRating == null)
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Please select a star rating.',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: Colors.red[400],
                ),
              ),
            ),
          SizedBox(height: 24),
          Text(
            'Your Feedback (Optional)',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 12),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: feedbackController,
              decoration: InputDecoration(
                labelText: 'Do you have additional comments or suggestions?',
                hintText: 'Mayroon ka bang karagdagang komento o mungkahi?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo[700]!, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.indigo.withOpacity(0.05),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: widget.isMobile ? 14 : 15,
                ),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: widget.isMobile ? 14 : 15,
                ),
              ),
              minLines: 4,
              maxLines: 6,
              validator: (value) {
                // Comment is optional, so no validation error for empty input
                return null;
              },
            ),
          ),
          SizedBox(height: 24),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isMobile ? 14 : 16,
                  horizontal: widget.isMobile ? 24 : 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.indigo.withOpacity(0.3),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: widget.isMobile ? 20 : 24,
                      width: widget.isMobile ? 20 : 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit Feedback',
                      style: GoogleFonts.poppins(
                        fontSize: widget.isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }
}
