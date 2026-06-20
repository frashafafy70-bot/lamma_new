// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LawsuitGeneratorPage extends StatefulWidget {
  const LawsuitGeneratorPage({super.key});

  @override
  State<LawsuitGeneratorPage> createState() => _LawsuitGeneratorPageState();
}

class _LawsuitGeneratorPageState extends State<LawsuitGeneratorPage> {
  final TextEditingController _titleController = TextEditingController(text: 'صحيفة دعوى صحة توقيع');
  final TextEditingController _contentController = TextEditingController(text: '''إنه في يوم ............ الموافق .../ .../ ......م
بناءً على طلب السيد/ ................................. المقيم في ......................... ومحله المختار مكتب الأستاذ/ محمود البرعي المحامي.
أنا ............ محضر محكمة ............ الجزئية قد انتقلت وأعلنت:
السيد/ ................................. المقيم في ......................... مخاطباً مع/ .........................

الموضوع

بموجب عقد بيع ابتدائي مؤرخ .../ .../ ......م، باع المعلن إليه للطالب ما هو (عقار / شقة / أرض) الموضحة الحدود والمعالم بمتن العقد وصدر هذه الصحيفة. وحيث إن الطالب يهمه إثبات صحة توقيع المعلن إليه على العقد المذكور حماية لحقوقه، وذلك طبقاً لنص المادة 45 من قانون الإثبات.

بناءً عليه

أنا المحضر سالف الذكر قد انتقلت وأعلنت المعلن إليه وكلفته بالحضور أمام محكمة ............ الجزئية الكائن مقرها بـ ............ بجلستها التي ستنعقد علناً صباح يوم ............ الموافق .../ .../ ......م ليسمع الحكم بصحة توقيعه على عقد البيع الابتدائي المؤرخ .../ .../ ......م والموضح بالصحيفة، مع إلزامه بالمصروفات ومقابل أتعاب المحاماة.

ولأجل العلم،،،''');
  
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  final String mizanSvg = '''
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
    <path fill="#D4AF37" d="M256 32c12.5 0 24.1 6.4 30.8 17L311 96h105c17.7 0 32 14.3 32 32s-14.3 32-32 32H394.3l-51.4 171.4c-2.4 8-10 13.6-18.4 13.6H203.4c-8.4 0-16-5.6-18.4-13.6L133.7 160H16c-17.7 0-32-14.3-32-32s14.3-32 32-32H121l24.2-47c6.7-10.6 18.3-17 30.8-17H256zm-43.4 128l36.6 122h14.2l36.6-122H212.6zM96 288c-17.7 0-32 14.3-32 32v64H32c-17.7 0-32 14.3-32 32s14.3 32 32 32H480c17.7 0 32-14.3 32-32s-14.3-32-32-32h-32V320c0-17.7-14.3-32-32-32s-32 14.3-32 32v64H160V320c0-17.7-14.3-32-32-32z"/>
  </svg>
  ''';

  String formatMarginText(String text) {
    List<String> words = text.split(' ');
    List<String> lines = [];
    for (int i = 0; i < words.length; i += 2) {
      if (i + 1 < words.length) {
        lines.add('${words[i]} ${words[i + 1]}'); 
      } else {
        lines.add(words[i]); 
      }
    }
    return lines.join('\n');
  }

  Future<void> _generatePdf() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء كتابة نص العريضة أولاً ⚠️', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );

    try {
      final pdf = pw.Document();
      
      // تحميل الخطوط العربية المتوافقة مع الـ PDF
      final fontRegular = await PdfGoogleFonts.amiriRegular();
      final fontBold = await PdfGoogleFonts.amiriBold();

      final navyColor = PdfColor.fromHex('#0F172A'); 
      final goldColor = PdfColor.fromHex('#D4AF37'); 
      final inkColor = PdfColor.fromHex('#111111'); 

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            margin: const pw.EdgeInsets.only(top: 175, bottom: 40, left: 110, right: 35),
            theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
            
            buildBackground: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Stack(
                  children: [
                    // الإطارات الخارجية
                    pw.Positioned(
                      top: 15, bottom: 15, left: 15, right: 15,
                      child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: inkColor, width: 1.2))),
                    ),
                    pw.Positioned(
                      top: 20, bottom: 20, left: 20, right: 20,
                      child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: inkColor, width: 2))),
                    ),

                    // ترويسة المكتب والشعار
                    pw.Positioned(
                      top: 30, left: 30, right: 30, 
                      child: pw.Container(
                        height: 120, 
                        padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white, 
                          border: pw.Border.all(color: goldColor, width: 2.5), 
                          borderRadius: pw.BorderRadius.circular(15), 
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Expanded(
                              flex: 4,
                              child: pw.Center(
                                child: pw.Text(
                                  _titleController.text,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 20, font: fontBold, color: navyColor), 
                                ),
                              ),
                            ),
                            
                            pw.Expanded(
                              flex: 2,
                              child: pw.Center(
                                child: pw.SvgImage(svg: mizanSvg, width: 85, height: 75), 
                              ),
                            ),

                            pw.Expanded(
                              flex: 4,
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Text('مكتب الأستاذ / محمود السيد البرعي', style: pw.TextStyle(fontSize: 12, font: fontBold, color: navyColor)),
                                  pw.Text('أحمد السيد البرعي', style: pw.TextStyle(fontSize: 12, font: fontBold, color: navyColor)),
                                  pw.SizedBox(height: 5),
                                  pw.Text('المحاميان بالاستئناف العالي ومجلس الدولة', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, font: fontRegular, color: navyColor)),
                                  pw.SizedBox(height: 5),
                                  pw.Text('٠١٠٦٦٣٦٦٤٣ / م', style: pw.TextStyle(fontSize: 13, font: fontBold, color: navyColor)), 
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // الهامش الجانبي للدمغات
                    pw.Positioned(
                      top: 165, bottom: 20, left: 95, 
                      child: pw.Container(
                        width: 1, 
                        decoration: pw.BoxDecoration(
                          border: pw.Border(left: pw.BorderSide(color: inkColor, width: 1.5, style: pw.BorderStyle.dashed)),
                        ),
                      ),
                    ),

                    pw.Positioned(
                      top: 175, left: 25, 
                      child: pw.Container(
                        width: 65,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(formatMarginText(_titleController.text), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: fontBold, color: inkColor, lineSpacing: 1.5)),
                            pw.SizedBox(height: 45), 
                            pw.Text('كطلب\nالطالب', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, font: fontBold, color: inkColor, lineSpacing: 1.5)),
                            pw.SizedBox(height: 45),
                            pw.Text('وكيل\nالطالب', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, font: fontBold, color: inkColor, lineSpacing: 1.5)),
                            pw.SizedBox(height: 45),
                            pw.Text('المحامي', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, font: fontBold, color: inkColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // محتوى الدعوى
          build: (pw.Context context) {
            List<pw.Widget> pdfContentWidgets = [];
            final lines = _contentController.text.split('\n');

            for (var line in lines) {
              final trimmed = line.trim();
              
              if (trimmed == 'الموضوع' || trimmed == 'بناء عليه' || trimmed == 'بناءً عليه') {
                pdfContentWidgets.add(pw.SizedBox(height: 12)); 
                pdfContentWidgets.add(
                  pw.Center(
                    child: pw.Text(trimmed, style: pw.TextStyle(font: fontBold, fontSize: 19, color: inkColor)),
                  ),
                );
                pdfContentWidgets.add(pw.SizedBox(height: 8)); 
              } else if (trimmed.isNotEmpty) {
                pdfContentWidgets.add(
                  pw.Text(
                    trimmed,
                    style: const pw.TextStyle(fontSize: 15, lineSpacing: 2.0),
                    textAlign: pw.TextAlign.justify,
                  ),
                );
              } else {
                pdfContentWidgets.add(pw.SizedBox(height: 5)); 
              }
            }
            return pdfContentWidgets;
          }
        )
      );

      if (mounted) Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'عريضة_${_titleController.text}.pdf',
      );

    } catch (e) {
      if (mounted) Navigator.pop(context); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('مُولّد صحف الدعاوى 📄', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: 'عنوان العريضة',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.title_rounded, color: goldAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  textDirection: TextDirection.rtl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(height: 1.8, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    labelText: 'نص العريضة',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  label: const Text('معاينة وطباعة العريضة 🖨️', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}