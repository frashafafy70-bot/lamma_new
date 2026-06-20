import 'package:flutter/material.dart';
// import 'inheritance_calculator_page.dart'; // مسار حاسبة المواريث (عند إضافتها مستقبلاً)

class LegalCalculatorsPage extends StatefulWidget {
  const LegalCalculatorsPage({super.key});

  @override
  State<LegalCalculatorsPage> createState() => _LegalCalculatorsPageState();
}

class _LegalCalculatorsPageState extends State<LegalCalculatorsPage> {
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنصة الحسابية الذكية 🧮', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl, // 🟢 إجبار الواجهة عربي
        child: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCalcCard('حساب الفوائد', Icons.percent_rounded, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestCalculatorPage()));
            }),
            _buildCalcCard('حساب المواريث', Icons.account_balance_wallet_rounded, Colors.green, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً: حاسبة المواريث الشرعية', style: TextStyle(fontFamily: 'Cairo'))));
            }),
            _buildCalcCard('مكافأة الخدمة', Icons.work_history_rounded, Colors.orange, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً: حاسبة مكافأة نهاية الخدمة', style: TextStyle(fontFamily: 'Cairo'))));
            }),
            _buildCalcCard('رسوم الدعاوى', Icons.gavel_rounded, Colors.red, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً: حاسبة رسوم الدعاوى', style: TextStyle(fontFamily: 'Cairo'))));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}

// Temporary/local placeholder for InterestCalculatorPage in case the real
// implementation is located elsewhere or not yet exported. This fixes
// compilation error when referencing InterestCalculatorPage.
class InterestCalculatorPage extends StatelessWidget {
  const InterestCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الفوائد', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: const Center(child: Text('واجهة حاسبة الفوائد (قيد التطوير)', style: TextStyle(fontFamily: 'Cairo'))),
    );
  }
}