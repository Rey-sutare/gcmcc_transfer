import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SurveyResultsPage extends StatefulWidget {
  final bool isMobile;

  const SurveyResultsPage({Key? key, required this.isMobile}) : super(key: key);

  @override
  _SurveyResultsPageState createState() => _SurveyResultsPageState();
}

class _SurveyResultsPageState extends State<SurveyResultsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSection = 'All';

  final List<Map<String, dynamic>> _surveyQuestions = [
    {
      'section': 'Infrastructures and Process',
      'questions': [
        {
          'id': 'q1',
          'text':
              'The waiting areas we used were clean, orderly, and comfortable.',
        },
        {
          'id': 'q2',
          'text':
              'The toilets and bathrooms inside the facility were kept clean, orderly and with a steady water supply.',
        },
        {
          'id': 'q3',
          'text': 'The patients’ rooms were clean, tidy, and comfortable.',
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
        },
        {
          'id': 'q9',
          'text':
              'Our sentiments, cultural background, and beliefs were heard and considered in the treatment procedure.',
        },
        {
          'id': 'q10',
          'text':
              'We were given the chance to decide which treatment procedure shall be performed.',
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
              'I was treated fairly, or “walang palakasan”, during my transaction.',
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

  final Map<String, double> _ratingValues = {
    'Strongly Disagree': 1.0,
    'Disagree': 2.0,
    'Partially Agree': 3.0,
    'Agree': 4.0,
    'Strongly Agree': 5.0,
    'Not Applicable': 0.0,
  };

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
          // Title
          Text(
            'Survey Results',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.indigo[900],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          // Description
          Text(
            'Detailed analysis of patient survey responses',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          // Filters (Section Dropdown and Date Range Picker)
          _buildFilters(),
          SizedBox(height: 24),
          // Average Ratings by Section Chart
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
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
              child: _buildSectionRatingChart(),
            ),
          ),
          SizedBox(height: 24),
          // Survey Analytics Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Survey Analytics',
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.analytics,
                        color: Colors.indigo[700],
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Divider(color: Colors.indigo[100], thickness: 1),
                  SizedBox(height: 12),
                  _buildQuestionBreakdown(),
                  SizedBox(height: 16),
                  _buildCommentSummary(),
                ],
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
          ),
        ),
        SizedBox(height: 8),
        widget.isMobile
            ? Column(
                children: [
                  _buildSectionDropdown(),
                  SizedBox(height: 12),
                  _buildDateRangePicker(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildSectionDropdown()),
                  SizedBox(width: 16),
                  Expanded(child: _buildDateRangePicker()),
                ],
              ),
      ],
    );
  }

  Widget _buildSectionDropdown() {
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
        value: _selectedSection,
        isExpanded: true,
        underline: SizedBox(),
        items: ['All', ..._surveyQuestions.map((s) => s['section'] as String)]
            .map<DropdownMenuItem<String>>((String section) {
              return DropdownMenuItem<String>(
                value: section,
                child: Text(
                  section,
                  style: GoogleFonts.poppins(
                    fontSize: widget.isMobile ? 15 : 17,
                    color: Colors.indigo[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            })
            .toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedSection = value ?? 'All';
          });
        },
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.indigo[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Date Range',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 15 : 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStyledButton(
                  context: context,
                  text: _startDate == null
                      ? 'Start Date'
                      : DateFormat('MMM d, yyyy').format(_startDate!),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  backgroundColor: Colors.blue[300],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStyledButton(
                  context: context,
                  text: _endDate == null
                      ? 'End Date'
                      : DateFormat('MMM d, yyyy').format(_endDate!),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  backgroundColor: Colors.blue[300],
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red[600]),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRatingChart() {
    return FutureBuilder<Map<String, double>>(
      future: _getSectionRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: widget.isMobile ? 200 : 250,
            child: _buildLoadingIndicator(),
          );
        }
        final ratings = snapshot.data ?? {};
        if (ratings.isEmpty) {
          return SizedBox(
            height: widget.isMobile ? 200 : 250,
            child: Center(
              child: Text(
                'No survey data available.',
                style: GoogleFonts.poppins(
                  fontSize: widget.isMobile ? 15 : 17,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Ratings by Section',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: widget.isMobile ? 200 : 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5.0,
                  minY: 0.0,
                  barGroups: _surveyQuestions
                      .asMap()
                      .entries
                      .where(
                        (e) =>
                            _selectedSection == 'All' ||
                            e.value['section'] == _selectedSection,
                      )
                      .map((entry) {
                        final section = entry.value['section'] as String;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: ratings[section] ?? 0.0,
                              color: Colors.indigo[700],
                              width: widget.isMobile ? 20 : 30,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 5.0,
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          ],
                        );
                      })
                      .toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: 1.0,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: widget.isMobile ? 12 : 14,
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
                          final section =
                              _surveyQuestions[value.toInt()]['section']
                                  as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: widget.isMobile ? -45 * 3.14159 / 180 : 0,
                              child: Text(
                                section,
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 10 : 12,
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          Colors.indigo[900]!.withOpacity(0.8),
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final section =
                            _surveyQuestions[group.x.toInt()]['section']
                                as String;
                        return BarTooltipItem(
                          '$section\n${rod.toY.toStringAsFixed(1)}',
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
          ],
        );
      },
    );
  }

  Widget _buildQuestionBreakdown() {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: _getQuestionRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        final questionRatings = snapshot.data ?? {};
        if (questionRatings.isEmpty) {
          return Text(
            'No question data available.',
            style: GoogleFonts.poppins(
              fontSize: widget.isMobile ? 15 : 17,
              color: Colors.grey[600],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Breakdown',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 12),
            ..._surveyQuestions
                .where(
                  (s) =>
                      _selectedSection == 'All' ||
                      s['section'] == _selectedSection,
                )
                .map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['section'],
                        style: GoogleFonts.poppins(
                          fontSize: widget.isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      ...section['questions'].map<Widget>((question) {
                        final ratings = questionRatings[question['id']] ?? {};
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
                              Text(
                                question['text'],
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Average Rating: ${(ratings['average'] ?? 0.0).toStringAsFixed(1)}/5.0',
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 12 : 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                'Responses: ${ratings['count'] ?? 0}',
                                style: GoogleFonts.poppins(
                                  fontSize: widget.isMobile ? 12 : 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 12),
                    ],
                  );
                })
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildCommentSummary() {
    return FutureBuilder<List<String>>(
      future: _getFrequentComments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        final frequentWords = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment Summary',
              style: GoogleFonts.poppins(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8),
            frequentWords.isEmpty
                ? Text(
                    'No comments available.',
                    style: GoogleFonts.poppins(
                      fontSize: widget.isMobile ? 15 : 17,
                      color: Colors.grey[600],
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: frequentWords.map((word) {
                      return Chip(
                        label: Text(
                          word,
                          style: GoogleFonts.poppins(
                            fontSize: widget.isMobile ? 12 : 14,
                            color: Colors.indigo[700],
                          ),
                        ),
                        backgroundColor: Colors.indigo[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo[200]!),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.indigo[700]),
        SizedBox(height: 12),
        Text(
          'Loading Survey Data...',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.indigo[900]),
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

  Future<Map<String, double>> _getSectionRatings() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'surveys',
      );
      if (_startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: DateFormat('MMM d, yyyy').format(_startDate!),
        );
      }
      if (_endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: DateFormat('MMM d, yyyy').format(_endDate!),
        );
      }
      final snapshot = await query.get();

      final sectionTotals = <String, double>{};
      final sectionCounts = <String, int>{};

      for (var doc in snapshot.docs) {
        final responses =
            (doc.data()['responses'] as Map<String, dynamic>?) ?? {};
        for (var section in _surveyQuestions) {
          final sectionName = section['section'] as String;
          sectionTotals[sectionName] = sectionTotals[sectionName] ?? 0.0;
          sectionCounts[sectionName] = sectionCounts[sectionName] ?? 0;
          for (var question in section['questions']) {
            final rating = responses[question['id']] as String?;
            if (rating != null &&
                _ratingValues.containsKey(rating) &&
                rating != 'Not Applicable') {
              sectionTotals[sectionName] =
                  sectionTotals[sectionName]! + _ratingValues[rating]!;
              sectionCounts[sectionName] = sectionCounts[sectionName]! + 1;
            }
          }
        }
      }

      return sectionTotals.map(
        (key, value) => MapEntry(
          key,
          sectionCounts[key]! > 0 ? value / sectionCounts[key]! : 0.0,
        ),
      );
    } catch (e) {
      print('Error fetching section ratings: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, double>>> _getQuestionRatings() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'surveys',
      );
      if (_startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: DateFormat('MMM d, yyyy').format(_startDate!),
        );
      }
      if (_endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: DateFormat('MMM d, yyyy').format(_endDate!),
        );
      }
      final snapshot = await query.get();

      final questionRatings = <String, Map<String, double>>{};
      for (var section in _surveyQuestions) {
        if (_selectedSection != 'All' && section['section'] != _selectedSection)
          continue;
        for (var question in section['questions']) {
          final qId = question['id'] as String;
          questionRatings[qId] = {'average': 0.0, 'count': 0.0};
        }
      }

      for (var doc in snapshot.docs) {
        final responses =
            (doc.data()['responses'] as Map<String, dynamic>?) ?? {};
        for (var section in _surveyQuestions) {
          if (_selectedSection != 'All' &&
              section['section'] != _selectedSection)
            continue;
          for (var question in section['questions']) {
            final qId = question['id'] as String;
            final rating = responses[qId] as String?;
            if (rating != null &&
                _ratingValues.containsKey(rating) &&
                rating != 'Not Applicable') {
              questionRatings[qId]!['average'] =
                  questionRatings[qId]!['average']! + _ratingValues[rating]!;
              questionRatings[qId]!['count'] =
                  questionRatings[qId]!['count']! + 1;
            }
          }
        }
      }

      return questionRatings.map(
        (key, value) => MapEntry(key, {
          'average': value['count']! > 0
              ? value['average']! / value['count']!
              : 0.0,
          'count': value['count']!,
        }),
      );
    } catch (e) {
      print('Error fetching question ratings: $e');
      return {};
    }
  }

  Future<List<String>> _getFrequentComments() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'surveys',
      );
      if (_startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: DateFormat('MMM d, yyyy').format(_startDate!),
        );
      }
      if (_endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: DateFormat('MMM d, yyyy').format(_endDate!),
        );
      }
      final snapshot = await query.get();

      const stopwords = {
        'the',
        'is',
        'are',
        'was',
        'were',
        'a',
        'an',
        'and',
        'or',
        'but',
        'in',
        'on',
        'at',
        'to',
        'for',
        'of',
        'with',
        'by',
        'from',
        'up',
        'about',
        'into',
        'over',
        'after',
        'i',
        'it',
        'he',
        'she',
        'we',
        'they',
        'that',
        'this',
      };
      final wordCounts = <String, int>{};

      for (var doc in snapshot.docs) {
        final comment = (doc.data()['comment'] as String?)?.toLowerCase() ?? '';
        if (comment.isEmpty) continue;
        final words = comment
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
            .where((word) => word.isNotEmpty && !stopwords.contains(word))
            .toList();
        for (var word in words) {
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        }
      }

      return wordCounts.entries
          .where((entry) => entry.value >= 2)
          .map((entry) => entry.key)
          .toList()
        ..sort((a, b) => wordCounts[b]!.compareTo(wordCounts[a]!))
        ..take(10);
    } catch (e) {
      print('Error fetching frequent comments: $e');
      return [];
    }
  }
}
