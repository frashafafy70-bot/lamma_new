// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 

import 'legal_chat_page.dart'; 
import 'legal_calculators_page.dart'; 
import 'lawsuit_generator_page.dart'; 
import 'lawsuit_archive_page.dart'; 
import 'legal_library_page.dart';
import 'home_page.dart';

class LegalServicesPage extends StatefulWidget {
  final bool isLawyer;
  const LegalServicesPage({super.key, required this.isLawyer});

  @override
  State<LegalServicesPage> createState() => _LegalServicesPageState();
}

class _LegalServicesPageState extends State<LegalServicesPage> with TickerProviderStateMixin {
  late TabController _lawyerTabController;
  late TabController _clientTabController;

  String _activeContractCategory = 'عقود البيع';
  String _activeLawsuitCategory = 'القضاء المدني';
  String _activeJudgmentCategory = 'نقض مدني';
  String _activeBookCategory = 'القانون المدني';
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color goldAccent = const Color(0xFFD4AF37); 
  
  final String officePhoneNumber = '01000000000';

  @override
  void initState() {
    super.initState();
    _lawyerTabController = TabController(length: 5, vsync: this);
    _clientTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _lawyerTabController.dispose();
    _clientTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء الاتصال حالياً ⚠️', style: TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  // ==========================================
  // ⚖️ قاعدة البيانات الشاملة للموسوعة القانونية
  // ==========================================
  final Map<String, Map<String, String>> _contractsData = {
    'عقود البيع': {
      'عقد بيع سيارة ابتدائي': '''عقد بيع ابتدائي لمركبة (سيارة)\n\nإنه في يوم ............ الموافق .../ .../ ......م\nبموجب هذا العقد الموقع بين كل من:\nأولاً: السيد/ ................................. المقيم في: ......................... بطاقة رقم قومي: ......................... (طرف أول بائع)\nثانياً: السيد/ ................................. المقيم في: ......................... بطاقة رقم قومي: ......................... (طرف ثان مشتري)\n\nبعد أن أقر الطرفان بأهليتهما المعتبرة قانوناً للتعاقد والتصرف، اتفقا على الآتي:\nالبند الأول: باع وأسقط وتنازل الطرف الأول إلى الطرف الثاني المركبة التالية بياناتها:\nالماركة: .................... الموديل: .................... سنة الصنع: .................... \nرقم الشاسيه: ............................ رقم الموتور: ............................ \nرقم اللوحات المعدنية: ............................ وحدة المرور التابعة لها: ............................\nالبند الثاني: تم هذا البيع نظير ثمن إجمالي مقبوض قدره .................... جنيهاً، وأقر الطرف الأول (البائع) باستلامه الثمن بالكامل في مجلس العقد, ويعتبر توقيعه على هذا العقد بمثابة مخالصة نهائية بالثمن.\nالبند الثالث: يقر الطرف الثاني (المشتري) بأنه عاين السيارة المعاينة التامة النافية للجهالة وقبلها بحالتها الراهنة.\nالبند الرابع: يلتزم الطرف الأول بعمل التوكيل الرسمي الخاص بالبيع وإدارة السيارة لصالح الطرف الثاني بالشهر العقاري.\n\nتوقيع الطرف الأول (البائع): ............................\nتوقيع الطرف الثاني (المشتري): ............................''',
      'عقد بيع عقار نهائي': '''عقد بيع نهائي (عقار / شقة السكنية)\n\nإنه في يوم ............ الموافق .../ .../ ......م\nتم الاتفاق بين كل من:\nأولاً: السيد/ ................................. المقيم في: ......................... (طرف أول بائع)\nثانياً: السيد/ ................................. المقيم في: ......................... (طرف ثان مشتري)\n\nالبند الأول: باع الطرف الأول للطرف الثاني ما هو الشقة السكنية رقم (....) الكائنة بالدور (....) بالعقار رقم (....) بشارع ............................ ومساحتها الإجمالية ........ متراً مربعاً والمحدودة بحدود أربعة حاسمة.\nالبند الثاني: يؤول حق الملكية للطرف الأول البائع بموجب العقد المشهر رقم ........ لسنة ........ شهر عقاري الدقهلية.\nالبند الثالث: تم هذا البيع بثمن إجمالي قدره ............ جنيهاً مصرياً، تم سداده بالكامل نقداً وعداً بمجلس العقد ويعتبر توقيع البائع مخالصة تامة.\nالبند الرابع: يتعهد الطرف الأول بتقديم كافة مستندات الملكية والمثول أمام مصلحة الشهر العقاري للإقرار بالبيع ونقل الملكية رسمياً.\nتوقيع البائع: ........................ توقيع المشتري: ........................''',
      'عقد بيع حصة ميراثية': '''عقد بيع وتنازل عن حصة ميراثية مشاعة\n\nإنه في يوم ............ الموافق .../ .../ ......م\nباع الطرف الأول (الوارث) للطرف الثاني حصته الميراثية الشرعية المشاعة التي آلت إليه بطريق الميراث الشرعي عن مورثه المرحوم/ ..................... في التركة المتمثلة في (العقارات/الأراضي) الموضحة بالحدود والمعالم أدناه، وذلك لقاء ثمن إجمالي قدره ........ جنيهاً.''',
    },
    'عقود الإيجار': {
      'عقد إيجار شقة سكني': '''عقد إيجار خاضع لأحكام القانون رقم 4 لسنة 1996\n\nإنه في يوم ............ الموافق .../ .../ ......م\nأجر السيد/ ................................. (طرف أول مؤجر)\nإلى السيد/ ................................. (طرف ثان مستأجر)\n\nالبند الأول: أجر الطرف الأول للطرف الثاني ما هو الشقة رقم (....) الكائنة بالدور (....) بالعقار رقم (....) بشارع ............................ بقصد استخدامها كسكن خاص.\nالبند الثاني: مدة الإيجار هي ............ تبدأ من .../ .../ ......م وتنتهي في .../ .../ ......م، ولا تجدد العين إلا بموجب عقد مكتوب جديد وبشروط جديدة.\nالبند الثالث: الأجرة الشهرية المتفق عليها هي مبلغ .................... جنيهاً، وتدفع مقدماً في الأسبوع الأول من كل شهر ميلادي في يد المؤجر مقابل إيصال موقع.\nالبند الرابع: دفع المستأجر مبلغ ............ جنيهاً كتأمين عيني يرد عند انتهاء العقد وتسليم العين بالحالة التي كانت عليها وقت التعاقد.\nتوقيع المؤجر: ........................ توقيع المستأجر: ........................''',
    },
    'الإقرارات والتوكيلات': {
      'إقرار بالتصالح والتنازل': '''إقرار رسمي بالتصالح والتنازل أمام القضاء\n\nأقر أنا الموقع أدناه السيد/ ................................. بصفتي (المجني عليه / المدعي بالحق المدني) في القضية / المحضر رقم ....... لسنة ....... جنح / إداري ............\nبأنني قد تصالحت تصالحاً نهائياً وباتاً مع السيد/ ................................. (المتهم)، وذلك بعد أن تسلمت كافة حقوقي العينية والمادية والأدبية جراء الواقعة.\nالمقر بما فيه: ............................\nالرقم القومي: ............................\nالتوقيع: ............................''',
    }
  };

  final Map<String, Map<String, String>> _lawsuitsData = {
    'القضاء المدني': {
      'صحيفة دعوى صحة توقيع': '''إنه في يوم ............ الموافق .../ .../ ......م\nبناءً على طلب السيد/ ................................. المقيم في ......................... ومحله المختار مكتب الأستاذ/ محمود البرعي المحامي.\nأنا ............ محضر محكمة ............ الجزئية قد انتقلت وأعلنت:\nالسيد/ ................................. المقيم في ......................... مخاطباً مع/ .........................\n\nالموضوع\nبموجب عقد بيع ابتدائي مؤرخ .../ .../ ......م، باع المعلن إليه للطالب ما هو (عقار / شقة / أرض) الموضحة الحدود والمعالم بمتن العقد وصدر هذه الصحيفة. وحيث إن الطالب يهمه إثبات صحة توقيع المعلن إليه على العقد المذكور حماية لحقوقه، وذلك طبقاً لنص المادة 45 من قانون الإثبات.\nبناءً عليه\nأنا المحضر سالف الذكر قد انتقلت وأعلنت المعلن إليه وكلفتة بالحضور أمام محكمة ............ الجزئية الكائن مقرها بـ ............ بجلستها التي ستنعقد علناً صباح يوم ............ الموافق .../ .../ ......م ليسمع الحكم بصحة توقيعه على عقد البيع الابتدائي المؤرخ .../ .../ ......م والموضح بالصحيفة، مع إلزامه بالمصروفات ومقابل أتعاب المحاماة.\nولأجل العلم،،،''',
    },
    'محكمة الأسرة': {
      'صحيفة دعوى خلع': '''إنه في يوم ............ الموافق .../ .../ ......م\nبناءً على طلب السيدة/ ................................. المقيمة في ......................... ومحلها المختار مكتب الأستاذ/ محمود البرعي المحامي.\nأنا ............ محضر محكمة الأسرة بـ ............ قد انتقلت وأعلنت:\nالسيد/ ................................. (الزوج) المقيم in ......................... مخاطباً مع/ .........................\n\nالموضوع\nالطالبة زوجة للمعلن إليه بصحيح العقد الشرعي، وحيث إنها تبغض الحياة الزوجية معه وتخشى ألا تقيم حدود الله بسبب هذه البغضاء، واستحالت العشرة بينهما كلياً. وحيث إنها تقدمت لمكتب تسوية المنازعات الأسرية، وتقيم هذه الدعوى متنازلة عن جميع حقوقها المالية والشرعية.\nبناءً عليه\nأنا المحضر سالف الذكر علنت المعلن إليه للحضور أمام محكمة أسرة ............ بجلستها المنعقدة علناً يوم ............ الموافق .../ .../ ......م لتسمع الحكم بتطليق الطالبة عليه طلقة بائنة للخلع، مع إلزامه بالمصروفات.\nولأجل العلم،،،''',
    },
    'قضاء الجنايات والجنح': {
      'مذكرة دفاع في جنحة ضرب': '''مذكرة بدفاع السيد/ .................... (متهم)\nضد السيد/ .................... (مدعي بالحق المدني)\nفي الجنحة رقم ........ لسنة ........\n\nالدفاع:\nأولاً: التناقض البين بين الدليل القولي والدليل الفني.\nثانياً: كيدية الاتهام وتلفيقه لوجود خلافات سابقة.\nثالثاً: خلو الأوراق من مناظرة السيد محرر المحضر للمجني عليه.\nوبناء عليه نلتمس البراءة.''',
    },
    'مجلس الدولة': {
      'صحيفة طعن في قرار إداري': '''صحيفة دعوى إلغاء قرار إداري\nمقدمة إلى محكمة القضاء الإداري\n\nضد: السيد الأستاذ/ .................... بصفته.\nالموضوع: الطعن بالإلغاء على القرار رقم ........ لسنة ........ الصادر بتخطي الطالب في الترقية، مع ما يترتب على ذلك من آثار قانونية.''',
    }
  };

  final Map<String, Map<String, String>> _judgmentsData = {
    'نقض مدني': {
      'القصور في التسبيب وإغفال الدفاع': '''[المبدأ القانوني]:\nإن إغفال الحكم المطعون فيه بحث دفاع جوهري أبداه الخصم وتمسك به، وقدم المستندات الدالة عليه، والذي من شأنه - إن صح - أن يتغير به وجه الرأي في الدعوى، يعيب الحكم بالقصور في التسبيب والإخلال بحق الدفاع، مما يوجب نقضه.''',
    },
    'نقض جنائي': {
      'بطلان القبض والتفتيش': '''[المبدأ القانوني]:\nالتلبس حالة عينية تلازم الجريمة ذاتها لا شخص مرتكبها، ولا يصح لضابط الواقعة أن يختلق حالة التلبس أو يبنيها على استنتاج ظني. وبناءً عليه، فإن بطلان القبض والتفتيش لانتفاء حالة التلبس يستتبع بالضرورة بطلان كافة الدليل المستمد منه لكونه ثمرة إجراء غير مشروع (ما بُني على باطل فهو باطل).''',
    }
  };

  final Map<String, Map<String, String>> _booksData = {
    'القانون المدني': {
      'الوسيط للسنهوري - نظرية العقد': '''من كتاب: الوسيط في شرح القانون المدني (الجزء الأول - مصادر الالتزام)\nللعلامة: أ.د. عبد الرزاق السنهوري\n\n[شروط الانعقاد - التراضي]:\nيقول السنهوري: "العقد توافق إرادتين على إحداث أثر قانوني، ولا بد لانعقاد العقد من توافر أركان ثلاثة: الرضا، المحل، والسبب. أما الرضا فهو تطابق الإيجاب والقبول، ويجب أن يكون صادراً عن ذي أهلية، وخالياً من عيوب الإرادة كالغلط والتدليس والإكراه والاستغلال."''',
    }
  };

  // ==========================================
  // 📥 نظام الفايربيز لإرسال واستقبل الطلبات القانونية
  // ==========================================
  void _showServiceForm(String serviceName) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text('تقديم $serviceName', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
                const SizedBox(height: 8),
                Text('برجاء كتابة تفاصيل طلبك، وسيتم مراجعته بعناية.', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo')),
                const SizedBox(height: 24),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'الاسم بالكامل', prefixIcon: Icon(Icons.person, color: goldAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)))),
                const SizedBox(height: 16),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'رقم الهاتف للتواصل', prefixIcon: Icon(Icons.phone, color: goldAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)))),
                const SizedBox(height: 16),
                TextField(controller: detailsController, maxLines: 4, decoration: InputDecoration(labelText: 'تفاصيل المشكلة أو الطلب', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (nameController.text.isEmpty || phoneController.text.isEmpty || detailsController.text.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('برجاء ملء جميع الحقول! ⚠️', style: TextStyle(fontFamily: 'Cairo'))));
                        return;
                      }
                      
                      final messenger = ScaffoldMessenger.of(context);
                      
                      await FirebaseFirestore.instance.collection('legal_requests').add({
                        'clientId': FirebaseAuth.instance.currentUser?.uid, 
                        'clientName': nameController.text.trim(),
                        'clientPhone': phoneController.text.trim(),
                        'details': detailsController.text.trim(),
                        'serviceType': serviceName,
                        'status': 'pending',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (!sheetContext.mounted) return; 
                      Navigator.pop(sheetContext);

                      messenger.showSnackBar(
                        SnackBar(content: const Text('تم إرسال طلبك بنجاح! يمكنك المتابعة من "متابعة طلباتي" ⚖️', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating)
                      );
                    },
                    child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildLawyerRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('legal_requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لا توجد طلبات موكلين حالياً ☕', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String name = data['clientName'] ?? '';
            String phone = data['clientPhone'] ?? '';
            String details = data['details'] ?? '';
            String type = data['serviceType'] ?? '';
            String status = data['status'] ?? 'pending';

            return Card(
              elevation: 3, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy, fontFamily: 'Cairo')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: status == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(status == 'completed' ? 'تم التواصل' : 'قيد الانتظار', style: TextStyle(color: status == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                        )
                      ],
                    ),
                    const Divider(),
                    Text('الموكل: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 4),
                    Text('الهاتف: $phone', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text('التفاصيل:\n$details', style: TextStyle(color: Colors.grey.shade800, height: 1.4, fontFamily: 'Cairo')),
                    const Divider(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _makePhoneCall(phone), 
                          icon: const Icon(Icons.call_rounded, color: Colors.green),
                          tooltip: 'اتصال بالموكل',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LegalChatPage(requestId: doc.id)));
                          },
                          icon: Icon(Icons.chat_bubble_rounded, color: primaryNavy),
                          tooltip: 'محادثة الموكل',
                        ),
                        const Spacer(),
                        if (status == 'pending')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('legal_requests').doc(doc.id).update({'status': 'completed'});
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('تم التواصل', style: TextStyle(fontFamily: 'Cairo')),
                          )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 🎨 واجهة العميل (بوابة الخدمات ومتابعة الطلبات)
  // ==========================================
  Widget _buildClientView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتب العدالة - بوابة العملاء', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: primaryNavy, foregroundColor: Colors.white, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, size: 28),
          tooltip: 'العودة للرئيسية',
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
          },
        ),
        bottom: TabBar(
          controller: _clientTabController, indicatorColor: goldAccent, indicatorWeight: 4, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          tabs: const [Tab(icon: Icon(Icons.support_agent), text: 'الخدمات القانونية'), Tab(icon: Icon(Icons.track_changes), text: 'متابعة طلباتي')],
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: TabBarView(
        controller: _clientTabController,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                    child: Column(
                      children: [
                        Icon(Icons.balance_rounded, size: 60, color: goldAccent),
                        const SizedBox(height: 12),
                        const Text('مكتب العدالة للمحاماة والاستشارات القانونية', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 8),
                        const Text('نحن هنا لحماية حقوقك ومصالحك بكل احترافية وسرية تامة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('الخدمات المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  _buildServiceCard('طلب استشارة عاجلة', 'تواصل مع محامٍ متخصص فوراً', Icons.chat_rounded, () => _showServiceForm('طلب استشارة عاجلة')),
                  _buildServiceCard('صياغة ومراجعة العقود', 'بيع، إيجار، شراكة، وعمل', Icons.edit_document, () => _showServiceForm('طلب صياغة عقد')),
                  _buildServiceCard('تأسيس الشركات', 'إجراءات التراخيص والسجل التجاري', Icons.business_center_rounded, () => _showServiceForm('طلب تأسيس شركة')),
                  _buildServiceCard('حجز موعد بالمكتب', 'ترتيب زيارة لتبادل المستندات والتوكيلات', Icons.calendar_month_rounded, () => _showServiceForm('طلب حجز موعد')),
                  
                  _buildServiceCard(
                    'المنصة الحسابية الذكية 🧮', 
                    'احسب المواريث والفوائد ورسوم الدعاوى مجاناً', 
                    Icons.calculate_rounded, 
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalCalculatorsPage()));
                    }
                  ),
                ],
              ),
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('legal_requests')
                .where('clientId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 100, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('ليس لديك أي طلبات حالية.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ],
                  ),
                );
              }

              var requestDocs = snapshot.data!.docs;
              requestDocs.sort((a, b) => (b['timestamp'] as Timestamp?)?.compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()) ?? 0);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requestDocs.length,
                itemBuilder: (context, index) {
                  var doc = requestDocs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String type = data['serviceType'] ?? '';
                  String status = data['status'] ?? 'pending';

                  return Card(
                    elevation: 3, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy, fontFamily: 'Cairo')),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: status == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(status == 'completed' ? 'تم الرد' : 'جاري المراجعة', style: TextStyle(color: status == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                              )
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                                onPressed: () => _makePhoneCall(officePhoneNumber), 
                                icon: const Icon(Icons.call),
                                label: const Text('اتصال بالمكتب', style: TextStyle(fontFamily: 'Cairo')),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => LegalChatPage(requestId: doc.id)));
                                }, 
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('رسالة للمحامي', style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: primaryNavy.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(icon, color: primaryNavy, size: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontFamily: 'Cairo')),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: goldAccent, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showViewDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, 
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ProfessionalPetitionWidget(title: title, content: content),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () { Clipboard.setData(ClipboardData(text: content)); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم النسخ بنجاح! 📋⚖️', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: goldAccent)); },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white), label: const Text('نسخ النص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryMenuButton({required String name, required IconData icon, required String currentCategory, required Function(String) onSelected}) {
    bool isSelected = currentCategory == name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () { onSelected(name); setState(() => _searchQuery = ''); _searchController.clear(); },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryNavy : Colors.white, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primaryNavy : Colors.grey.shade300, width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: isSelected ? goldAccent : Colors.grey.shade500),
              const SizedBox(height: 8),
              Text(
                name, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : Colors.black87, fontFamily: 'Cairo'), 
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerSplitView({required Map<String, Map<String, String>> fullData, required String activeCategory, required List<Widget> sideMenuButtons, bool isBooks = false}) {
    final currentCategoryData = fullData[activeCategory] ?? {};
    final filteredData = currentCategoryData.entries.where((entry) => entry.key.contains(_searchQuery) || entry.value.contains(_searchQuery)).toList();

    return Row(
      textDirection: TextDirection.rtl, 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 145, 
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1.5))),
          child: ListView(children: sideMenuButtons),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController, onChanged: (val) => setState(() => _searchQuery = val), textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث في $activeCategory...', prefixIcon: Icon(Icons.search_rounded, color: primaryNavy),
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)),
                  ),
                ),
              ),
              
              if (activeCategory == 'القضاء المدني' || activeCategory == 'محكمة الأسرة' || activeCategory == 'قضاء الجنايات والجنح' || activeCategory == 'مجلس الدولة')
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: InkWell(
                        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LawsuitGeneratorPage())); },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF1E293B)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: goldAccent.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(Icons.picture_as_pdf_rounded, color: goldAccent, size: 28)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('مُولّد صحف الدعاوى الذكي 📄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldAccent, fontFamily: 'Cairo')),
                                    const SizedBox(height: 4),
                                    const Text('أدخل بيانات أي قضية وولدها في ملف PDF', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: InkWell(
                        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LawsuitArchivePage())); },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [goldAccent, const Color(0xFFB8860B)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: goldAccent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 28)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('أرشيف القضايا 📁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                                    SizedBox(height: 4),
                                    Text('إدارة القضايا والملفات المحفوظة مسبقاً', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (isBooks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: InkWell(
                    onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalLibraryPage())); },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade900]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.library_books_rounded, color: Colors.white, size: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('مكتبة الـ PDF الشاملة 📚', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                                SizedBox(height: 4),
                                Text('تصفح وحمل المراجع وأكواد القوانين الرسمية', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: filteredData.isEmpty
                    ? Center(child: Text('لا توجد نتائج مطابقة لـ "$_searchQuery" 🔍', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          String title = filteredData[index].key;
                          String content = filteredData[index].value;
                          return Card(
                            elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(backgroundColor: goldAccent.withValues(alpha: 0.2), child: Icon(isBooks ? Icons.menu_book_rounded : Icons.description_rounded, color: goldAccent)),
                              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy, fontFamily: 'Cairo')),
                              subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(content.split('\n').take(2).join('\n'), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontFamily: 'Cairo'))),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              onTap: () => _showViewDialog(title, content),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLawyerView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('مكتب العدالة - الموسوعة والطلبات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: primaryNavy, foregroundColor: Colors.white, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, size: 28),
          tooltip: 'العودة للرئيسية',
          onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage())); },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_rounded, size: 28, color: Colors.white),
            tooltip: 'المنصة الحسابية 🧮',
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalCalculatorsPage())); },
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _lawyerTabController, isScrollable: true, tabAlignment: TabAlignment.start, indicatorColor: goldAccent, indicatorWeight: 4, labelColor: Colors.white, unselectedLabelColor: Colors.white70, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
          tabs: const [
            Tab(icon: Icon(Icons.move_to_inbox_rounded), text: 'الطلبات الواردة 📥'),
            Tab(icon: Icon(Icons.description_rounded), text: 'العقود والتوكيلات'),
            Tab(icon: Icon(Icons.gavel_rounded), text: 'موسوعة صيغ الدعاوى'),
            Tab(icon: Icon(Icons.account_balance_rounded), text: 'مبادئ وأحكام النقض'),
            Tab(icon: Icon(Icons.library_books_rounded), text: 'المكتبة القانونية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _lawyerTabController,
        children: [
          _buildLawyerRequestsTab(), 
          _buildLawyerSplitView(fullData: _contractsData, activeCategory: _activeContractCategory, sideMenuButtons: [_buildCategoryMenuButton(name: 'عقود البيع', icon: Icons.storefront_rounded, currentCategory: _activeContractCategory, onSelected: (val) => setState(() => _activeContractCategory = val)), _buildCategoryMenuButton(name: 'عقود الإيجار', icon: Icons.apartment_rounded, currentCategory: _activeContractCategory, onSelected: (val) => setState(() => _activeContractCategory = val)), _buildCategoryMenuButton(name: 'الإقرارات والتوكيلات', icon: Icons.assignment_turned_in_rounded, currentCategory: _activeContractCategory, onSelected: (val) => setState(() => _activeContractCategory = val))]),
          _buildLawyerSplitView(fullData: _lawsuitsData, activeCategory: _activeLawsuitCategory, sideMenuButtons: [_buildCategoryMenuButton(name: 'القضاء المدني', icon: Icons.gavel_rounded, currentCategory: _activeLawsuitCategory, onSelected: (val) => setState(() => _activeLawsuitCategory = val)), _buildCategoryMenuButton(name: 'محكمة الأسرة', icon: Icons.people_alt_rounded, currentCategory: _activeLawsuitCategory, onSelected: (val) => setState(() => _activeLawsuitCategory = val)), _buildCategoryMenuButton(name: 'قضاء الجنايات والجنح', icon: Icons.local_police_rounded, currentCategory: _activeLawsuitCategory, onSelected: (val) => setState(() => _activeLawsuitCategory = val)), _buildCategoryMenuButton(name: 'مجلس الدولة', icon: Icons.account_balance_rounded, currentCategory: _activeLawsuitCategory, onSelected: (val) => setState(() => _activeLawsuitCategory = val))]),
          _buildLawyerSplitView(fullData: _judgmentsData, activeCategory: _activeJudgmentCategory, sideMenuButtons: [_buildCategoryMenuButton(name: 'نقض مدني', icon: Icons.balance_rounded, currentCategory: _activeJudgmentCategory, onSelected: (val) => setState(() => _activeJudgmentCategory = val)), _buildCategoryMenuButton(name: 'نقض جنائي', icon: Icons.local_police_rounded, currentCategory: _activeJudgmentCategory, onSelected: (val) => setState(() => _activeJudgmentCategory = val)), _buildCategoryMenuButton(name: 'نقض أحوال شخصية', icon: Icons.family_restroom_rounded, currentCategory: _activeJudgmentCategory, onSelected: (val) => setState(() => _activeJudgmentCategory = val))]),
          _buildLawyerSplitView(fullData: _booksData, activeCategory: _activeBookCategory, isBooks: true, sideMenuButtons: [_buildCategoryMenuButton(name: 'القانون المدني', icon: Icons.book_rounded, currentCategory: _activeBookCategory, onSelected: (val) => setState(() => _activeBookCategory = val)), _buildCategoryMenuButton(name: 'القانون الجنائي', icon: Icons.collections_bookmark_rounded, currentCategory: _activeBookCategory, onSelected: (val) => setState(() => _activeBookCategory = val)), _buildCategoryMenuButton(name: 'المرافعات والإجراءات', icon: Icons.import_contacts_rounded, currentCategory: _activeBookCategory, onSelected: (val) => setState(() => _activeBookCategory = val))]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLawyer) {
      return _buildClientView();
    }
    return _buildLawyerView(); 
  }
}

class ProfessionalPetitionWidget extends StatelessWidget {
  final String title;
  final String content;

  const ProfessionalPetitionWidget({
    super.key, 
    required this.title, 
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
      child: IntrinsicHeight(
        child: Row(
          textDirection: TextDirection.rtl, 
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, decoration: TextDecoration.underline, fontFamily: 'Cairo'))),
                    const SizedBox(height: 32),
                    Text(content, style: const TextStyle(fontSize: 16, height: 1.9, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Cairo'), textAlign: TextAlign.justify),
                  ],
                ),
              ),
            ),
            Container(
              width: 80,
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(right: BorderSide(color: Colors.red.shade800, width: 2.5))),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 2)),
                    child: const Icon(Icons.balance_rounded, color: Color(0xFF0F172A), size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text('مكتب\nالعدالة', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Cairo')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}