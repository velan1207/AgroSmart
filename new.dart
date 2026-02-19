// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/field_provider.dart'; // Your state provider
import '../services/gemini_service.dart'; // The new Gemini service
import 'package:flutter_markdown/flutter_markdown.dart'; // To render Markdown

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  void _fetchAndShowAiInsights() async {
    setState(() {
      _isLoading = true;
    });

    final fieldProvider = Provider.of<FieldProvider>(context, listen: false);
    final latestData = fieldProvider.latestData; // Your latest sensor data
    final historicalData = fieldProvider.historicalData; // Your historical data
    final cropType = "Paddy (Rice)"; // Example crop type

    if (latestData == null) {
      // Handle case where there is no data
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No sensor data available to analyze.')),
      );
      return;
    }

    final insights = await _geminiService.getAiInsights(
      latestData: latestData,
      historicalData: historicalData,
      cropType: cropType,
    );

    setState(() {
      _isLoading = false;
    });

    // Show the insights in a bottom sheet or dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Insights', style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: MarkdownBody(
                          data: insights), // Use Markdown to display formatted text
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Assuming your UI has a Scaffold and a FloatingActionButton
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      // ... Your other dashboard widgets (sensor cards, charts, etc.)
      body: Center(
        child: Text('Your Dashboard UI Here'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _fetchAndShowAiInsights,
        label: _isLoading ? Text('Generating...') : Text('AI Insights'),
        icon: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.psychology_alt),
      ),
    );
  }
}
