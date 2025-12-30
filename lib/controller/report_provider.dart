
import 'package:flutter/material.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> reports = [];
  bool isReportListLoading = false;

  Future<void> fetchReports() async {
    isReportListLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Fetch reports logic here
    // For demonstration, we'll just add some dummy reports
    reports = [
      Report(id: '1', title: 'Sales Report', icon: 'assets/icons/document.png', url: 'https://example.com/sales'),
      Report(id: '2', title: 'Inventory Report', icon: 'assets/icons/document.png', url: 'https://example.com/inventory'),
      Report(id: '3', title: 'Customer Report', icon: 'assets/icons/document.png', url: 'https://example.com/customer'),
    ];

    isReportListLoading = false;
    notifyListeners();
  }
}

class Report {
  final String id;
  final String title;
  final String icon;
  final String url;

  Report({required this.id, required this.title, required this.icon, required this.url});
}