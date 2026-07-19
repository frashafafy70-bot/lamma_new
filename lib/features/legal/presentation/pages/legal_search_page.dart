import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalSearchPage extends StatefulWidget {
  const LegalSearchPage({super.key});

  @override
  State<LegalSearchPage> createState() => _LegalSearchPageState();
}

class _LegalSearchPageState extends State<LegalSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  // قاموس القوانين المصري (الباحث الذكي)
  final List<Map<String, String>> _legalDatabase = [
    {
      'name': 'القانون المدني',
      'url': 'https://www.cc.gov.eg/legislation_single?id=113063'
    },
    {
      'name': 'قانون العقوبات',
      'url': 'https://www.cc.gov.eg/legislation_single?id=114878'
    },
    {
      'name': 'قانون الإجراءات الجنائية',
      'url': 'https://www.cc.gov.eg/legislation_single?id=114881'
    },
    {
      'name': 'قانون التجارة',
      'url': 'https://www.cc.gov.eg/legislation_single?id=113220'
    },
    {
      'name': 'قانون العمل',
      'url': 'https://www.cc.gov.eg/legislation_single?id=113702'
    },
    {
      'name': 'قانون الأحوال الشخصية',
      'url': 'https://www.cc.gov.eg/legislation_single?id=113303'
    },
  ];

  List<Map<String, String>> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _filteredResults = _legalDatabase;
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredResults = _legalDatabase
          .where((item) => item['name']!.contains(query))
          .toList();
    });
  }

  Future<void> _openLegalPortal(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('الباحث القانوني الذكي 🔍'),
          backgroundColor: const Color(0xFF0F172A)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم القانون...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredResults.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.gavel, color: Color(0xFFD4AF37)),
                title: Text(_filteredResults[i]['name']!),
                onTap: () => _openLegalPortal(_filteredResults[i]['url']!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
