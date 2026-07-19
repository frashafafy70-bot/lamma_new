import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LawsuitArchivePage extends StatelessWidget {
  const LawsuitArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("أرشيف الدعاوى 📁",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFD4AF37),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('lawsuits').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
                child: Text("لا توجد قضايا محفوظة حالياً",
                    style: TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final lawsuit = box.getAt(index);
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.folder_shared,
                      color: Color(0xFFD4AF37), size: 30),
                  title: Text(lawsuit['plaintiff'] ?? "مدعي غير معروف",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "ضد: ${lawsuit['defendant'] ?? 'غير معروف'}\nالتاريخ: ${lawsuit['date']?.substring(0, 10)}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () =>
                        box.deleteAt(index), // حذف القضية من الأرشيف
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
