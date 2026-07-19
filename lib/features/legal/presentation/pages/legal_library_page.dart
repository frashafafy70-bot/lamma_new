import 'package:flutter/material.dart';

class LegalLibraryPage extends StatelessWidget {
  const LegalLibraryPage({super.key});

  final List<Map<String, String>> _laws = const [
    {
      'title': 'القانون المدني',
      'content':
          'مادة (1): التشريعات تطبق على جميع المسائل التي تتناولها نصوصها في لفظها وفي فحواها...\n\nمادة (2): لا يجوز إلغاء نص تشريعي إلا بتشريع لاحق ينص صراحة على هذا الإلغاء...'
    },
    {
      'title': 'قانون العقوبات',
      'content':
          'مادة (1): تسري أحكام هذا القانون على كل من يرتكب في القطر المصري جريمة من الجرائم المنصوص عليها فيه...'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('موسوعة لَمَّة القانونية'),
          backgroundColor: const Color(0xFF0F172A)),
      body: ListView.builder(
        itemCount: _laws.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text(_laws[i]['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LawContentPage(law: _laws[i]))),
          ),
        ),
      ),
    );
  }
}

class LawContentPage extends StatelessWidget {
  final Map<String, String> law;
  const LawContentPage({super.key, required this.law});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(law['title']!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: Text(law['content']!, style: const TextStyle(fontSize: 16))),
      ),
    );
  }
}
