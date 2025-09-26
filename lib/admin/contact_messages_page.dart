import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ContactMessagesPage extends StatelessWidget {
  final bool isMobile;

  const ContactMessagesPage({Key? key, required this.isMobile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Messages',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contact_messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.indigo[700]),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No contact messages found.',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isRead = data['read'] ?? false;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.message,
                          color: isRead ? Colors.grey : Colors.indigo[700],
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: Colors.indigo[900],
                          ),
                        ),
                        subtitle: Text(
                          data['date'] ?? 'No date',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isRead ? Icons.check_circle : Icons.circle_outlined,
                            color: isRead ? Colors.green : Colors.indigo[700],
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('contact_messages')
                                .doc(message.id)
                                .update({'read': true});
                          },
                          tooltip: isRead ? 'Marked as read' : 'Mark as read',
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Message from ${data['name'] ?? 'Unknown'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Email: ${data['email'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Mobile: ${data['mobileNumber'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Inquiry Type: ${data['inquiryType'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Date: ${data['date'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Message:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      data['message'] ?? 'No message',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.poppins(
                                      color: Colors.indigo[700],
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('contact_messages')
                                          .doc(message.id)
                                          .update({'read': true});
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo[700],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      'Mark as Read',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                              ],
                            ),
                          );
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
}
