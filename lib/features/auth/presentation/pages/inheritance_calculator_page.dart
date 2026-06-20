// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InheritanceCalculatorPage extends StatefulWidget {
  const InheritanceCalculatorPage({super.key});

  @override
  State<InheritanceCalculatorPage> createState() => _InheritanceCalculatorPageState();
}

class _InheritanceCalculatorPageState extends State<InheritanceCalculatorPage> {
  final TextEditingController _cashCtrl = TextEditingController();
  final TextEditingController _otherCashCtrl = TextEditingController(); 
  final TextEditingController _buildingMetersCtrl = TextEditingController(); 
  final TextEditingController _agriFeddansCtrl = TextEditingController(); 
  final TextEditingController _agriQiratsCtrl = TextEditingController(); 
  final TextEditingController _agriSahmsCtrl = TextEditingController(); 
  final TextEditingController _goldCtrl = TextEditingController(); 
  
  bool _isDeceasedMale = true;
  
  int _deceasedSons = 0; 
  int _deceasedDaughters = 0; 

  int _wives = 0;
  int _husband = 0;
  
  int _sons = 0;
  int _daughters = 0;
  int _grandsons = 0;
  int _granddaughters = 0; 
  
  int _father = 0;
  int _mother = 0;
  int _grandfather = 0; 
  int _paternalGrandmother = 0; 
  int _maternalGrandmother = 0; 

  int _fullBrothers = 0;
  int _fullSisters = 0;
  int _consanguineBrothers = 0; 
  int _consanguineSisters = 0;  
  int _uterineSiblings = 0;      

  int _nephews = 0; 
  int _paternalUncles = 0; 
  int _cousins = 0; 
  
  int _paternalAunts = 0; 
  int _paternalAuntsOffspring = 0; 
  int _maternalUncles = 0; 
  int _maternalUnclesOffspring = 0; 
  int _maternalAunts = 0; 
  int _maternalAuntsOffspring = 0; 

  int _pregnancies = 0; 
  int _missingSons = 0; 
  int _hermaphroditeSons = 0; 
  
  int _pregnantFullBros = 0;
  int _pregnantConsBros = 0;
  int _pregnantUterineBros = 0;
  
  int _missingFullBros = 0;
  int _missingConsBros = 0;
  int _missingUterineBros = 0;
  
  int _hermaphroditeFullBros = 0;
  int _hermaphroditeConsBros = 0;
  int _hermaphroditeUterineBros = 0;

  List<Map<String, dynamic>> _results = [];
  bool _showResults = false;
  String _explanationText = ''; 

  double _totalCash = 0;
  double _totalMeters = 0;
  double _totalFeddans = 0;
  double _totalQirats = 0;
  double _totalSahms = 0;
  double _totalGold = 0;

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  final String _legalDeclaration = 
      "إقرار: أقر أنا الموقع أدناه بسلامة البيانات الواردة في هذا التقرير، وأوافق على توزيع التركة وفقاً للسهام الشرعية والقانونية الموضحة أعلاه، "
      "وأتعهد بعدم الطعن على هذه القسمة مستقبلاً، كما أقر بحجز النصيب الموقوف للحمل/الغائب/الخنثى المشكل (إن وجد) احتياطاً كأمانة لحين البت في أمره قانوناً وشرعاً.";

  void _calculateAdvancedInheritance() {
    double inputCash = double.tryParse(_cashCtrl.text) ?? 0;
    double inputOther = double.tryParse(_otherCashCtrl.text) ?? 0;
    _totalCash = inputCash + inputOther;
    
    _totalMeters = double.tryParse(_buildingMetersCtrl.text) ?? 0;
    
    _totalFeddans = double.tryParse(_agriFeddansCtrl.text) ?? 0;
    _totalQirats = double.tryParse(_agriQiratsCtrl.text) ?? 0;
    _totalSahms = double.tryParse(_agriSahmsCtrl.text) ?? 0;
    double totalAgriSahms = (_totalFeddans * 576) + (_totalQirats * 24) + _totalSahms;
    
    _totalGold = double.tryParse(_goldCtrl.text) ?? 0;

    List<Map<String, dynamic>> tempResults = [];
    StringBuffer exp = StringBuffer(); 
    
    double abstractEstate = 2400000.0; 
    double obligatoryWillAmount = 0;

    exp.writeln('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ');
    exp.writeln('«يُوصِيكُمُ اللَّهُ فِي أَوْلَادِكُمْ لِلذَّكَرِ مِثْلُ حَظِّ الْأُنْثَيَيْنِ...»\n');
    exp.writeln('📌 التأصيل الشرعي والقانوني للمسألة وحيثيات القسمة:\n');

    int effectiveSons = _sons + _missingSons + _pregnancies;
    int effectiveDaughters = _daughters + _hermaphroditeSons;
    
    int effectiveFullBros = _fullBrothers + _missingFullBros + _pregnantFullBros;
    int effectiveFullSisters = _fullSisters + _hermaphroditeFullBros;
    
    int effectiveConsBrothers = _consanguineBrothers + _missingConsBros + _pregnantConsBros;
    int effectiveConsSisters = _consanguineSisters + _hermaphroditeConsBros;
    
    int effectiveUterineSiblings = _uterineSiblings + _hermaphroditeUterineBros + _missingUterineBros + _pregnantUterineBros;

    int totalDhawiArham = _paternalAunts + _paternalAuntsOffspring + 
                          _maternalUncles + _maternalUnclesOffspring + 
                          _maternalAunts + _maternalAuntsOffspring;

    if (_deceasedSons > 0 || _deceasedDaughters > 0) {
      int hypSons = effectiveSons + _deceasedSons;
      int hypDaughters = effectiveDaughters + _deceasedDaughters;

      bool hypHasBranch = hypSons > 0 || hypDaughters > 0 || _grandsons > 0 || _granddaughters > 0;
      int hypTotalSiblings = effectiveFullBros + effectiveFullSisters + effectiveConsBrothers + effectiveConsSisters + effectiveUterineSiblings;

      double hypWivesAmount = 0;
      double hypHusbandAmount = 0;
      if (!_isDeceasedMale && _husband == 1) {
        hypHusbandAmount = abstractEstate * (hypHasBranch ? 0.25 : 0.50);
      }
      if (_isDeceasedMale && _wives > 0) {
        hypWivesAmount = abstractEstate * (hypHasBranch ? 0.125 : 0.25);
      }

      double hypMotherAmount = 0;
      if (_mother == 1) {
        hypMotherAmount = abstractEstate * ((hypHasBranch || hypTotalSiblings >= 2) ? (1 / 6) : (1 / 3));
      }

      double hypFatherAmount = 0;
      if (_father == 1) {
        hypFatherAmount = abstractEstate * (hypHasBranch ? (1 / 6) : 0);
      }

      double hypMaternalGrandmotherAmount = 0;
      double hypPaternalGrandmotherAmount = 0;
      if (_mother == 0 && _maternalGrandmother == 1) {
        hypMaternalGrandmotherAmount = abstractEstate * (1 / 6);
      }
      if (_mother == 0 && _father == 0 && _paternalGrandmother == 1) {
        hypPaternalGrandmotherAmount = abstractEstate * (1 / 6);
      }

      double hypFixed = hypWivesAmount + hypHusbandAmount + hypMotherAmount + hypFatherAmount + hypMaternalGrandmotherAmount + hypPaternalGrandmotherAmount;
      double hypResidue = abstractEstate - hypFixed;
      if (hypResidue < 0) {
        hypResidue = 0;
      }

      double hypOneSonShare = 0;
      double hypOneDaughterShare = 0;

      if (hypSons > 0) {
        double partValue = hypResidue / ((hypSons * 2) + hypDaughters);
        hypOneSonShare = partValue * 2;
        hypOneDaughterShare = partValue;
      } else if (hypDaughters > 0) {
        double shareFraction = hypDaughters == 1 ? 0.5 : (2 / 3);
        hypOneDaughterShare = (abstractEstate * shareFraction) / hypDaughters;
      }

      double rawObligatoryWill = (_deceasedSons * hypOneSonShare) + (_deceasedDaughters * hypOneDaughterShare);
      double maxAllowedWill = abstractEstate / 3;

      exp.writeln('📜 أولاً: الوصية الواجبة (قانون 71 لسنة 1946)');
      if (rawObligatoryWill > maxAllowedWill) {
         obligatoryWillAmount = maxAllowedWill;
         exp.writeln('- تم حساب النصيب الافتراضي للأحفاد ووجد أنه يتجاوز ثلث التركة، فتم رده إلى (الثلث) قانوناً وشرعاً.');
      } else {
         obligatoryWillAmount = rawObligatoryWill;
         exp.writeln('- تم استخراج النصيب الافتراضي للأحفاد (أبناء الفرع المتوفى) باعتبار أصلهم حياً.');
      }
      exp.writeln('');
    }

    double estate = abstractEstate - obligatoryWillAmount; 

    bool hasBranch = effectiveSons > 0 || effectiveDaughters > 0 || _grandsons > 0 || _granddaughters > 0;
    bool hasMaleBranch = effectiveSons > 0 || _grandsons > 0;
    int totalSiblings = effectiveFullBros + effectiveFullSisters + effectiveConsBrothers + effectiveConsSisters + effectiveUterineSiblings;
    bool hasSiblingGroup = totalSiblings >= 2;

    double husbandAmount = 0;
    double wivesAmount = 0;
    double fatherAmount = 0;
    double motherAmount = 0;
    double grandfatherAmount = 0;
    double paternalGrandmotherAmount = 0;
    double maternalGrandmotherAmount = 0;
    double uterineSiblingsAmount = 0;
    
    bool isGrandfatherBlocked = _father == 1;
    bool isPaternalGrandmotherBlocked = _mother == 1 || _father == 1;
    bool isMaternalGrandmotherBlocked = _mother == 1;
    bool isGrandsonBlocked = effectiveSons > 0;
    
    bool areAllSiblingsBlocked = effectiveSons > 0 || _grandsons > 0 || _father == 1;
    bool areConsanguineBlocked = areAllSiblingsBlocked || effectiveFullBros > 0 || effectiveFullSisters >= 2;
    bool areUterineBlocked = areAllSiblingsBlocked || _grandfather == 1 || hasBranch;

    bool areNephewsBlocked = areAllSiblingsBlocked || effectiveFullBros > 0 || effectiveConsBrothers > 0 || _grandfather == 1;
    bool areUnclesBlocked = areNephewsBlocked || _nephews > 0;
    bool areCousinsBlocked = areUnclesBlocked || _paternalUncles > 0;
    
    bool hasAnyAsaba = hasMaleBranch || _father == 1 || _grandfather == 1 || effectiveFullBros > 0 || effectiveConsBrothers > 0 || _nephews > 0 || _paternalUncles > 0 || _cousins > 0;
    bool hasRaddTarget = effectiveDaughters > 0 || _granddaughters > 0 || _mother == 1 || _paternalGrandmother == 1 || _maternalGrandmother == 1 || effectiveFullSisters > 0 || effectiveConsSisters > 0 || effectiveUterineSiblings > 0;
    bool areDhawiArhamBlocked = hasAnyAsaba || hasRaddTarget;

    String getBreakdown(double fraction) {
      if (fraction <= 0) {
        return '';
      }
      List<String> parts = [];
      if (_totalCash > 0) {
        parts.add('• نقدية: ${(fraction * _totalCash).toStringAsFixed(2)} ج.م');
      }
      if (_totalMeters > 0) {
        parts.add('• عقارات ومباني: ${(fraction * _totalMeters).toStringAsFixed(2)} متر مربع');
      }
      if (totalAgriSahms > 0) {
        double fSahms = fraction * totalAgriSahms;
        int f = (fSahms / 576).floor();
        double r1 = fSahms - (f * 576);
        int q = (r1 / 24).floor();
        double s = r1 - (q * 24);
        String landStr = '• أراضي زراعية: ';
        if (f > 0) {
          landStr += '$f فدان و ';
        }
        if (q > 0 || f > 0) {
          landStr += '$q قيراط و ';
        }
        landStr += '${s.toStringAsFixed(2)} سهم';
        parts.add(landStr);
      }
      if (_totalGold > 0) {
        parts.add('• ذهب: ${(fraction * _totalGold).toStringAsFixed(2)} جرام');
      }
      
      if (parts.isEmpty) {
        return 'النسبة الشرعية: ${(fraction * 100).toStringAsFixed(2)}%';
      }
      return parts.join('\n');
    }

    void addResult(String heir, String status, String share, double amount, {String? reason}) {
      double fraction = amount / abstractEstate;
      tempResults.add({
        'heir': heir,
        'status': status,
        'share': share,
        'amount': amount,
        'reason': reason,
        'fraction': fraction,
        'breakdown': getBreakdown(fraction),
      });
    }

    if (_pregnancies > 0 || _missingSons > 0 || _hermaphroditeSons > 0 || 
        _pregnantFullBros > 0 || _missingFullBros > 0 || _hermaphroditeFullBros > 0 ||
        _pregnantConsBros > 0 || _missingConsBros > 0 || _hermaphroditeConsBros > 0 ||
        _pregnantUterineBros > 0 || _missingUterineBros > 0 || _hermaphroditeUterineBros > 0) {
      exp.writeln('⚠️ ثانياً: قواعد الاحتياط الفقهي للحالات الخاصة (الغائب والخنثى والحمل)');
      exp.writeln('- القاعدة العامة: يُعامل الحمل والغائب بتقدير الذكورة (لحجز النصيب الأكبر)، ويُعامل الخنثى المشكل بتقدير الأنوثة (النصيب الأقل المتيقن).');
      exp.writeln('- الإخوة لأم (إن وجدوا بحالة احتياط): الذكر والأنثى فيهم سواء في القسمة.');
      exp.writeln('');
    }

    exp.writeln('⚖️ ثالثاً: أصحاب الفروض (وفقاً للكتاب والسنة)');
    
    if (!_isDeceasedMale && _husband == 1) {
      double share = hasBranch ? 0.25 : 0.50;
      husbandAmount = estate * share;
      addResult('الزوج', 'فرض', hasBranch ? '1/4' : '1/2', husbandAmount);
    }
    
    if (_isDeceasedMale && _wives > 0) {
      double share = hasBranch ? 0.125 : 0.25;
      wivesAmount = (estate * share) / _wives;
      addResult('الزوجة (لكل واحدة)', 'فرض', hasBranch ? '1/8' : '1/4', wivesAmount);
    }

    if (_mother == 1) {
      double share = (hasBranch || hasSiblingGroup) ? (1 / 6) : (1 / 3);
      motherAmount = estate * share;
      addResult('الأم', 'فرض', (hasBranch || hasSiblingGroup) ? '1/6' : '1/3', motherAmount);
    } else {
      if (_maternalGrandmother == 1) {
        if (isMaternalGrandmotherBlocked) {
          addResult('الجدة لأم', 'محجوبة', '0', 0.0, reason: 'بسبب وجود الأم');
        } else {
          maternalGrandmotherAmount = estate * (1 / 6);
          addResult('الجدة لأم', 'فرض', '1/6', maternalGrandmotherAmount);
        }
      }
      if (_paternalGrandmother == 1) {
        if (isPaternalGrandmotherBlocked) {
          String reason = _mother == 1 ? 'الأم' : 'الأب';
          addResult('الجدة لأب', 'محجوبة', '0', 0.0, reason: 'بسبب وجود $reason');
        } else {
          paternalGrandmotherAmount = estate * (1 / 6);
          addResult('الجدة لأب', 'فرض', '1/6', paternalGrandmotherAmount);
        }
      }
    }

    if (_father == 1) {
      double share = hasBranch ? (1 / 6) : 0.0; 
      fatherAmount = estate * share;
    } else if (_grandfather == 1) {
      if (isGrandfatherBlocked) {
        addResult('الجد لأب', 'محجوب', '0', 0.0, reason: 'بسبب وجود الأب');
      } else {
        double share = hasBranch ? (1 / 6) : 0.0;
        grandfatherAmount = estate * share;
      }
    }

    if (effectiveUterineSiblings > 0) {
      if (areUterineBlocked) {
        addResult('الإخوة لأم', 'محجوبون', '0', 0.0, reason: 'وجود فرع وارث أو أصل مذكر');
      } else {
        double share = effectiveUterineSiblings == 1 ? (1 / 6) : (1 / 3);
        uterineSiblingsAmount = (estate * share) / effectiveUterineSiblings;
        if (_uterineSiblings > 0) {
          addResult('ولد أم (لكل واحد)', 'فرض', effectiveUterineSiblings == 1 ? '1/6' : '1/3', uterineSiblingsAmount);
        }
        if (_hermaphroditeUterineBros > 0) {
          addResult('أخ لأم (خنثى)', 'فرض', effectiveUterineSiblings == 1 ? '1/6' : '1/3', uterineSiblingsAmount, reason: 'الذكر والأنثى فيه سواء');
        }
        if (_missingUterineBros > 0) {
          addResult('أخ لأم (غائب/مفقود)', 'موقوف', 'نصيب فرض', uterineSiblingsAmount * _missingUterineBros, reason: 'يُوقف لحين عودته');
        }
        if (_pregnantUterineBros > 0) {
          addResult('حمل (في أخ لأم)', 'موقوف', 'نصيب فرض', uterineSiblingsAmount * _pregnantUterineBros, reason: 'يُوقف احتياطاً لحين الولادة');
        }
      }
    }

    double totalFixedDistributed = (_wives * wivesAmount) + husbandAmount + motherAmount + maternalGrandmotherAmount + paternalGrandmotherAmount + fatherAmount + grandfatherAmount + (effectiveUterineSiblings * uterineSiblingsAmount);
    double residue = estate - totalFixedDistributed;
    if (residue < 0) {
      residue = 0; 
    }

    exp.writeln('🧬 رابعاً: العصبات والحجب (من يستحق الباقي)');
    
    double sonShare = 0;
    double daughterShare = 0;
    if (effectiveSons > 0) {
      double totalParts = (effectiveSons * 2.0) + effectiveDaughters;
      double partValue = residue / totalParts;
      sonShare = partValue * 2;
      daughterShare = partValue;
      residue = 0; 
      
      if (_daughters > 0) {
        addResult('البنت (لكل واحدة)', 'عصبة بالغير', 'باقي للذكر مثل الحظين', daughterShare);
      }
      if (_hermaphroditeSons > 0) {
        addResult('ابن (خنثى مشكل)', 'فرض الأقل', 'نصيب أنثى', daughterShare * _hermaphroditeSons, reason: 'احتياطاً يُعامل كأنثى');
      }
      if (_sons > 0) {
        addResult('الابن (لكل واحد)', 'عصبة بالنفس', 'باقي للذكر مثل الحظين', sonShare);
      }
      if (_missingSons > 0) {
        addResult('الابن المفقود/الغائب', 'موقوف', 'نصيب كامل', sonShare * _missingSons, reason: 'يُوقف لحين عودته');
      }
      if (_pregnancies > 0) {
        addResult('الحمل المستكن (فرع)', 'موقوف', 'تقدير ذكر', sonShare * _pregnancies, reason: 'يُوقف احتياطاً لحين الولادة');
      }
      
    } else if (effectiveDaughters > 0) {
      double shareFraction = effectiveDaughters == 1 ? 0.5 : (2 / 3);
      daughterShare = (estate * shareFraction) / effectiveDaughters;
      
      if (_daughters > 0) {
        addResult('البنت (لكل واحدة)', 'فرض', effectiveDaughters == 1 ? '1/2' : '2/3', daughterShare);
      }
      if (_hermaphroditeSons > 0) {
        addResult('ابن (خنثى مشكل)', 'فرض الأقل', effectiveDaughters == 1 ? '1/2' : '2/3', daughterShare, reason: 'يُعامل كأنثى احتياطاً');
      }
      residue -= (daughterShare * effectiveDaughters);
    }

    if (_grandsons > 0 || _granddaughters > 0) {
      if (isGrandsonBlocked) {
        if (_grandsons > 0) {
          addResult('ابن الابن', 'محجوب', '0', 0.0, reason: 'وجود الفرع المذكر (أو الحمل/الغائب)');
        }
        if (_granddaughters > 0) {
          addResult('بنت الابن', 'محجوبة', '0', 0.0, reason: 'وجود الفرع الأعلى');
        }
      } else {
        double totalGrandParts = (_grandsons * 2.0) + _granddaughters;
        if (totalGrandParts > 0 && residue > 0) {
          double partValue = residue / totalGrandParts;
          addResult('ابن ابن (لكل واحد)', 'عصبة', 'باقي', partValue * 2);
          if (_granddaughters > 0) {
            addResult('بنت ابن (لكل واحدة)', 'عصبة بالغير', 'باقي', partValue);
          }
          residue = 0;
        }
      }
    }

    if (!hasMaleBranch) {
      if (_father == 1) {
        fatherAmount += residue; 
        addResult('الأب', 'فرض + عصبة', hasBranch ? '1/6 + باقي' : 'الكل تعصيباً', fatherAmount);
        residue = 0;
      } else if (_grandfather == 1 && !isGrandfatherBlocked) {
        grandfatherAmount += residue;
        addResult('الجد لأب', 'فرض + عصبة', hasBranch ? '1/6 + باقي' : 'الكل تعصيباً', grandfatherAmount);
        residue = 0;
      }
    }

    if (residue > 0) {
      if (areAllSiblingsBlocked) {
        if (_fullBrothers > 0) {
          addResult('الأخ الشقيق', 'محجوب', '0', 0.0, reason: 'مُحجب بالفرع المذكر المتيقن أو الحمل');
        }
        if (_fullSisters > 0) {
          addResult('الأخت الشقيقة', 'محجوبة', '0', 0.0, reason: 'وجود حاجب أقرب');
        }
        if (_hermaphroditeFullBros > 0) {
          addResult('أخ شقيق (خنثى)', 'محجوب', '0', 0.0, reason: 'وجود حاجب أقرب');
        }
        if (_missingFullBros > 0) {
          addResult('أخ شقيق (غائب)', 'محجوب', '0', 0.0, reason: 'وجود حاجب أقرب');
        }
        if (_pregnantFullBros > 0) {
          addResult('حمل (في أخ شقيق)', 'محجوب', '0', 0.0, reason: 'وجود حاجب أقرب');
        }
      } else {
        if (effectiveFullBros > 0 || effectiveFullSisters > 0) {
          double totalParts = (effectiveFullBros * 2.0) + effectiveFullSisters;
          double partValue = residue / totalParts;
          if (_fullBrothers > 0) {
            addResult('الأخ الشقيق (لكل واحد)', 'عصبة بالنفس', 'باقي تعصيباً', partValue * 2);
          }
          if (_missingFullBros > 0) {
            addResult('أخ شقيق (غائب)', 'موقوف', 'نصيب ذكر', partValue * 2 * _missingFullBros, reason: 'يُوقف لحين عودته');
          }
          if (_pregnantFullBros > 0) {
            addResult('حمل (أخ شقيق)', 'موقوف', 'تقدير ذكر', partValue * 2 * _pregnantFullBros, reason: 'يُوقف احتياطاً لحين الولادة');
          }
          if (_fullSisters > 0) {
            addResult('الأخت الشقيقة (لكل واحدة)', 'عصبة بالغير', 'باقي تعصيباً', partValue);
          }
          if (_hermaphroditeFullBros > 0) {
            addResult('أخ شقيق (خنثى)', 'عصبة بالغير', 'باقي تعصيباً', partValue, reason: 'يُعامل كأنثى احتياطاً');
          }
          residue = 0;
        }
      }
    }

    if (residue > 0) {
      if (areConsanguineBlocked) {
        addResult('الإخوة لأب', 'محجوبون', '0', 0.0, reason: 'وجود حاجب أقرب درجة');
      } else {
        double totalParts = (effectiveConsBrothers * 2.0) + effectiveConsSisters;
        double partValue = residue / totalParts;
        if (_consanguineBrothers > 0) {
          addResult('الأخ لأب (لكل واحد)', 'عصبة', 'باقي', partValue * 2);
        }
        if (_missingConsBros > 0) {
          addResult('أخ لأب (غائب)', 'موقوف', 'نصيب ذكر', partValue * 2 * _missingConsBros, reason: 'يُوقف لحين عودته');
        }
        if (_pregnantConsBros > 0) {
          addResult('حمل (أخ لأب)', 'موقوف', 'تقدير ذكر', partValue * 2 * _pregnantConsBros, reason: 'يُوقف احتياطاً لحين الولادة');
        }
        if (_consanguineSisters > 0) {
          addResult('الأخت لأب (لكل واحدة)', 'عصبة بالغير', 'باقي', partValue);
        }
        if (_hermaphroditeConsBros > 0) {
          addResult('أخ لأب (خنثى)', 'عصبة بالغير', 'باقي', partValue, reason: 'يُعامل كأنثى احتياطاً');
        }
        residue = 0;
      }
    }

    if (_nephews > 0) {
      if (areNephewsBlocked) {
        addResult('أبناء الإخوة', 'محجوبون', '0', 0.0, reason: 'وجود إخوة أو فروع مذكرة');
      } else if (residue > 0) {
        double amountPerNephew = residue / _nephews;
        addResult('ابن الأخ (لكل واحد)', 'عصبة بالنفس', 'باقي تعصيباً', amountPerNephew);
        residue = 0;
      }
    }

    if (_paternalUncles > 0) {
      if (areUnclesBlocked) {
        addResult('الأعمام', 'محجوبون', '0', 0.0, reason: 'وجود حاجب أقرب درجة');
      } else if (residue > 0) {
        double amountPerUncle = residue / _paternalUncles;
        addResult('العم (لكل واحد)', 'عصبة بالنفس', 'باقي تعصيباً', amountPerUncle);
        residue = 0;
      }
    }

    if (_cousins > 0) {
      if (areCousinsBlocked) {
        addResult('أبناء الأعمام', 'محجوبون', '0', 0.0, reason: 'وجود حاجب أقرب درجة');
      } else if (residue > 0) {
        double amountPerCousin = residue / _cousins;
        addResult('ابن العم (لكل واحد)', 'عصبة بالنفس', 'باقي تعصيباً', amountPerCousin);
        residue = 0;
      }
    }

    if (residue > 0) {
      if (hasRaddTarget) {
         addResult('الرد الشرعي', 'قاعدة الرد', 'يرد الباقي لأصحاب الفروض نسبياً', residue);
      } else if (totalDhawiArham > 0) {
         if (areDhawiArhamBlocked) {
            addResult('ذوو الأرحام', 'محجوبون', '0', 0.0, reason: 'لوجود أصحاب فروض أو عصبات');
         } else {
            double amountPerArham = residue / totalDhawiArham;
            if (_paternalAunts > 0) {
              addResult('العمات (لكل واحدة)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            if (_paternalAuntsOffspring > 0) {
              addResult('أبناء العمات (لكل واحد)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            if (_maternalUncles > 0) {
              addResult('الأخوال (لكل واحد)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            if (_maternalUnclesOffspring > 0) {
              addResult('أبناء الأخوال (لكل واحد)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            if (_maternalAunts > 0) {
              addResult('الخالات (لكل واحدة)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            if (_maternalAuntsOffspring > 0) {
              addResult('أبناء الخالات (لكل واحد)', 'توريث الأرحام', 'الباقي بالتساوي', amountPerArham);
            }
            residue = 0;
         }
      } else {
         addResult('بيت المال', 'لا وارث', 'الباقي', residue);
      }
    } else if (totalDhawiArham > 0) {
      addResult('ذوو الأرحام', 'محجوبون', '0', 0.0, reason: 'استغرقت الفروض التركة');
    }

    if (obligatoryWillAmount > 0) {
      double fraction = obligatoryWillAmount / abstractEstate;
      tempResults.insert(0, {
        'heir': 'أحفاد الوصية الواجبة',
        'status': 'مستحقة قانوناً',
        'share': 'وصية واجبة',
        'amount': obligatoryWillAmount,
        'fraction': fraction,
        'breakdown': getBreakdown(fraction),
      });
    }

    setState(() {
      _results = tempResults;
      _explanationText = exp.toString(); 
      _showResults = true;
    });
  }

  Future<void> _saveToArchive() async {
    if (_results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء حساب التركة أولاً قبل الحفظ ⚠️')));
      return;
    }
    
    TextEditingController clientNameController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          textDirection: TextDirection.rtl,
          children: [Icon(Icons.cloud_upload_rounded, color: primaryNavy), const SizedBox(width: 8), const Text('حفظ في أرشيف الموكلين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: clientNameController, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: 'اسم الموكل / رقم القضية', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 12),
            TextField(controller: notesController, textDirection: TextDirection.rtl, maxLines: 2, decoration: InputDecoration(labelText: 'ملاحظات إضافية (اختياري)', prefixIcon: const Icon(Icons.note_alt_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (clientNameController.text.trim().isEmpty) { 
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('برجاء إدخال اسم الموكل ⚠️'), backgroundColor: Colors.orange)); 
                return; 
              }
              Navigator.pop(ctx, clientNameController.text.trim());
            },
            icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('حفظ الآن', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!context.mounted) {
      return;
    }
    if (name == null || name.isEmpty) {
      return;
    }

    try {
      Map<String, dynamic> archiveData = {
        'clientName': name,
        'notes': notesController.text.trim(),
        'isMaleDeceased': _isDeceasedMale,
        'timestamp': FieldValue.serverTimestamp(),
        'results': _results,
        'explanation': _explanationText,
      };
      await FirebaseFirestore.instance.collection('inheritance_archive').add(archiveData);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح! ☁️✅'), backgroundColor: Colors.green)); 
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  void _showExplanationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(textDirection: TextDirection.rtl, children: [Icon(Icons.lightbulb, color: goldAccent), const SizedBox(width: 8), const Text('شرح التأصيل الشرعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Text(_explanationText, style: const TextStyle(fontSize: 14, height: 1.8, color: Colors.black87), textDirection: TextDirection.rtl))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))],
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes(PdfPageFormat format) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(10), margin: const pw.EdgeInsets.only(bottom: 20), decoration: pw.BoxDecoration(color: PdfColors.blueGrey900, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(children: [pw.Text('مكتب العدالة للمحاماة والاستشارات القانونية', style: pw.TextStyle(color: PdfColors.white, fontSize: 22, font: arabicBold)), pw.SizedBox(height: 5), pw.Text('إعداد الأستاذ / محمود المواريث - المحامي', style: pw.TextStyle(color: PdfColors.amber300, fontSize: 16))])
          );
        },
        footer: (pw.Context context) { return pw.Container(margin: const pw.EdgeInsets.only(top: 20), alignment: pw.Alignment.center, child: pw.Text('تم استخراج هذا التقرير آلياً عبر محرك المواريث الذكي (منصة لمة) - صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))); },
        build: (pw.Context context) {
          return [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('تقرير الفرز الشرعي وتقسيم الأعيان', style: pw.TextStyle(fontSize: 18, font: arabicBold, color: PdfColors.black)), pw.Text('تاريخ التقرير: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}', style: pw.TextStyle(fontSize: 12))]),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            pw.TableHelper.fromTextArray(
              headers: ['النصيب المفرز من الأعيان والأصول', 'النسبة الشرعية', 'الحالة القانونية', 'الوارث'],
              data: _results.map((res) {
                bool isBlocked = res['status'].toString().contains('محجوب');
                String percentStr = isBlocked ? '0%' : '${(res['fraction'] * 100).toStringAsFixed(2)}%';
                String breakdown = isBlocked ? 'محجوب (لا شيء)' : res['breakdown'];
                return [breakdown, percentStr, "${res['status']}\n${res['reason'] ?? res['share']}", res['heir']];
              }).toList(),
              headerStyle: pw.TextStyle(font: arabicBold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
              cellAlignment: pw.Alignment.centerRight,
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey400),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            
            pw.SizedBox(height: 30),
            pw.Text('💡 شرح التأصيل الشرعي وحيثيات القسمة:', style: pw.TextStyle(fontSize: 14, font: arabicBold, color: PdfColors.blue900)),
            pw.Divider(color: PdfColors.blueGrey200),
            pw.SizedBox(height: 10),
            pw.Text(_explanationText, style: pw.TextStyle(font: arabicFont, fontSize: 11, lineSpacing: 2, color: PdfColors.black)),
            
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text('الإقرار القانوني للمصادقة:', style: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.red900)),
            pw.Paragraph(text: _legalDeclaration, style: pw.TextStyle(font: arabicFont, fontSize: 10, lineSpacing: 1.5)),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('توقيع الموكل / الورثة: ___________________', style: pw.TextStyle(font: arabicBold)),
                pw.Text('توقيع المحامي المعتمد: ___________________', style: pw.TextStyle(font: arabicBold))
              ]
            )
          ];
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _printPdf() async {
    try { 
      final bytes = await _generatePdfBytes(PdfPageFormat.a4);
      if (!context.mounted) {
        return;
      }
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes, name: 'تقرير_مواريث_${DateTime.now().millisecondsSinceEpoch}.pdf'); 
    } catch (error) { 
      if (!context.mounted) {
        return; 
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('عذراً، فشل فتح شاشة الطباعة ⚠️\n$error'), backgroundColor: Colors.red.shade800)); 
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final bytes = await _generatePdfBytes(PdfPageFormat.a4);
      if (!context.mounted) {
        return;
      }
      await Printing.sharePdf(bytes: bytes, filename: 'تقرير_مواريث_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (error) { 
      if (!context.mounted) {
        return; 
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('عذراً، فشل تحميل الملف للجهاز ⚠️\n$error'), backgroundColor: Colors.red.shade800)); 
    }
  }

  Widget _buildSectionCardHeader(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        textDirection: TextDirection.rtl, 
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildUniformCounter(String label, int value, VoidCallback onAdd, VoidCallback onRemove, {int max = 99}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: Colors.black87))),
          Row(
            children: [
              IconButton(onPressed: value > 0 ? onRemove : null, icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24)),
              Container(width: 35, alignment: Alignment.center, child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
              IconButton(onPressed: value < max ? onAdd : null, icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 24)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAssetInput(String title, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller, keyboardType: TextInputType.number, textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo'),
        decoration: InputDecoration(
          labelText: title, 
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          prefixIcon: Icon(icon, color: goldAccent), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2, 
            shadowColor: Colors.black.withValues(alpha: 0.24), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCardHeader('بيانات التركة والأصول', Icons.account_balance_wallet_rounded, primaryNavy),
                  const Divider(height: 20),
                  _buildAssetInput('النقدية والسيولة بالبنوك (ج.م)', Icons.attach_money_rounded, _cashCtrl),
                  _buildAssetInput('مساحة العقارات والمباني (بالمتر المربع)', Icons.apartment_rounded, _buildingMetersCtrl),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('مساحة الأراضي الزراعية:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo')),
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildAssetInput('فدان', Icons.landscape_rounded, _agriFeddansCtrl)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAssetInput('قيراط', Icons.grass_rounded, _agriQiratsCtrl)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAssetInput('سهم', Icons.eco_rounded, _agriSahmsCtrl)),
                    ],
                  ),
                  
                  _buildAssetInput('الذهب والمجوهرات (بالجرام)', Icons.diamond_rounded, _goldCtrl),
                  _buildAssetInput('سيارات وأصول أخرى (تقييم مالي ج.م)', Icons.directions_car_rounded, _otherCashCtrl),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.24), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'جنس المتوفى والفرع الوارث', 
                          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('ذكر', style: TextStyle(fontFamily: 'Cairo')), 
                            selected: _isDeceasedMale, 
                            onSelected: (v) => setState(() { _isDeceasedMale = true; _husband = 0; }), 
                            selectedColor: goldAccent.withValues(alpha: 0.2)
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('أنثى', style: TextStyle(fontFamily: 'Cairo')), 
                            selected: !_isDeceasedMale, 
                            onSelected: (v) => setState(() { _isDeceasedMale = false; _wives = 0; }), 
                            selectedColor: goldAccent.withValues(alpha: 0.2)
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 25),
                  
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.amber.shade50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCardHeader('الوصية الواجبة (القانون المصري)', Icons.gavel_rounded, Colors.amber.shade800),
                        _buildUniformCounter('أبناء ذكور متوفين قبله', _deceasedSons, () => setState(() => _deceasedSons++), () => setState(() => _deceasedSons--)),
                        _buildUniformCounter('بنات إناث متوفيات قبله', _deceasedDaughters, () => setState(() => _deceasedDaughters++), () => setState(() => _deceasedDaughters--)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCardHeader('أصحاب الفروض (الأزواج)', Icons.people_alt_rounded, primaryNavy),
                  if (_isDeceasedMale) _buildUniformCounter('الزوجات', _wives, () => setState(() => _wives++), () => setState(() => _wives--), max: 4)
                  else _buildUniformCounter('الزوج', _husband, () => setState(() => _husband = 1), () => setState(() => _husband = 0), max: 1),
                  
                  const Divider(height: 25),
                  _buildSectionCardHeader('الفروع (الأحياء وقت الوفاة)', Icons.child_care_rounded, primaryNavy),
                  _buildUniformCounter('الأبناء الصلبيين', _sons, () => setState(() => _sons++), () => setState(() => _sons--)),
                  _buildUniformCounter('البنات الصلبيات', _daughters, () => setState(() => _daughters++), () => setState(() => _daughters--)),
                  _buildUniformCounter('أبناء الابن', _grandsons, () => setState(() => _grandsons++), () => setState(() => _grandsons--)),
                  _buildUniformCounter('بنات الابن', _granddaughters, () => setState(() => _granddaughters++), () => setState(() => _granddaughters--)), 
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCardHeader('احتياط الفروع (موقوف/مُجمد)', Icons.shield_rounded, Colors.blueGrey.shade800),
                        _buildUniformCounter('حمل مستكن (يُوقف له ذكر احتياطاً)', _pregnancies, () => setState(() => _pregnancies++), () => setState(() => _pregnancies--)),
                        _buildUniformCounter('ابن مفقود/غائب (يُحجز نصيبه)', _missingSons, () => setState(() => _missingSons++), () => setState(() => _missingSons--)),
                        _buildUniformCounter('ابن خنثى مشكل (يعامل كأنثى احتياطاً)', _hermaphroditeSons, () => setState(() => _hermaphroditeSons++), () => setState(() => _hermaphroditeSons--)),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 25),
                  _buildSectionCardHeader('الأصول (الآباء والأجداد والجدات)', Icons.elderly_rounded, primaryNavy),
                  _buildUniformCounter('الأب', _father, () => setState(() => _father = 1), () => setState(() => _father = 0), max: 1),
                  _buildUniformCounter('الأم', _mother, () => setState(() => _mother = 1), () => setState(() => _mother = 0), max: 1),
                  _buildUniformCounter('الجد الصحيح لأب', _grandfather, () => setState(() => _grandfather = 1), () => setState(() => _grandfather = 0), max: 1),
                  _buildUniformCounter('الجدة لأب (أم الأب)', _paternalGrandmother, () => setState(() => _paternalGrandmother = 1), () => setState(() => _paternalGrandmother = 0), max: 1),
                  _buildUniformCounter('الجدة لأم (أم الأم)', _maternalGrandmother, () => setState(() => _maternalGrandmother = 1), () => setState(() => _maternalGrandmother = 0), max: 1),
                  
                  const Divider(height: 25),
                  _buildSectionCardHeader('الحواشي المقربة (الإخوة والأخوات)', Icons.group_rounded, primaryNavy),
                  _buildUniformCounter('الإخوة الأشقاء', _fullBrothers, () => setState(() => _fullBrothers++), () => setState(() => _fullBrothers--)),
                  _buildUniformCounter('الأخوات الشقيقات', _fullSisters, () => setState(() => _fullSisters++), () => setState(() => _fullSisters--)),
                  _buildUniformCounter('الإخوة لأب', _consanguineBrothers, () => setState(() => _consanguineBrothers++), () => setState(() => _consanguineBrothers--)),
                  _buildUniformCounter('الأخوات لأب', _consanguineSisters, () => setState(() => _consanguineSisters++), () => setState(() => _consanguineSisters--)),
                  _buildUniformCounter('الإخوة والأخوات لأم', _uterineSiblings, () => setState(() => _uterineSiblings++), () => setState(() => _uterineSiblings--)),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCardHeader('احتياط الحواشي (موقوف/مُجمد)', Icons.hourglass_bottom_rounded, Colors.blueGrey.shade800),
                        _buildUniformCounter('حمل (يرجى أن يكون أخ شقيق)', _pregnantFullBros, () => setState(() => _pregnantFullBros++), () => setState(() => _pregnantFullBros--)),
                        _buildUniformCounter('أخ شقيق غائب/مفقود', _missingFullBros, () => setState(() => _missingFullBros++), () => setState(() => _missingFullBros--)),
                        _buildUniformCounter('أخ شقيق خنثى (يعامل كأنثى)', _hermaphroditeFullBros, () => setState(() => _hermaphroditeFullBros++), () => setState(() => _hermaphroditeFullBros--)),
                        const Divider(height: 15),
                        _buildUniformCounter('حمل (يرجى أن يكون أخ لأب)', _pregnantConsBros, () => setState(() => _pregnantConsBros++), () => setState(() => _pregnantConsBros--)),
                        _buildUniformCounter('أخ لأب غائب/مفقود', _missingConsBros, () => setState(() => _missingConsBros++), () => setState(() => _missingConsBros--)),
                        _buildUniformCounter('أخ لأب خنثى (يعامل كأنثى)', _hermaphroditeConsBros, () => setState(() => _hermaphroditeConsBros++), () => setState(() => _hermaphroditeConsBros--)),
                        const Divider(height: 15),
                        _buildUniformCounter('حمل (يرجى أن يكون أخ لأم)', _pregnantUterineBros, () => setState(() => _pregnantUterineBros++), () => setState(() => _pregnantUterineBros--)),
                        _buildUniformCounter('أخ لأم غائب/مفقود', _missingUterineBros, () => setState(() => _missingUterineBros++), () => setState(() => _missingUterineBros--)),
                        _buildUniformCounter('أخ لأم خنثى (الذكر كالأنثى)', _hermaphroditeUterineBros, () => setState(() => _hermaphroditeUterineBros++), () => setState(() => _hermaphroditeUterineBros--)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.red.shade50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCardHeader('امتداد العصبات وذوي الأرحام', Icons.warning_amber_rounded, Colors.red.shade800),
                        _buildUniformCounter('أبناء الإخوة الذكور', _nephews, () => setState(() => _nephews++), () => setState(() => _nephews--)),
                        _buildUniformCounter('الأعمام (أشقاء / لأب)', _paternalUncles, () => setState(() => _paternalUncles++), () => setState(() => _paternalUncles--)),
                        _buildUniformCounter('أبناء الأعمام (ابن العم)', _cousins, () => setState(() => _cousins++), () => setState(() => _cousins--)),
                        const Divider(height: 15),
                        _buildUniformCounter('العمات', _paternalAunts, () => setState(() => _paternalAunts++), () => setState(() => _paternalAunts--)),
                        _buildUniformCounter('أبناء العمات', _paternalAuntsOffspring, () => setState(() => _paternalAuntsOffspring++), () => setState(() => _paternalAuntsOffspring--)),
                        const Divider(height: 15),
                        _buildUniformCounter('الأخوال', _maternalUncles, () => setState(() => _maternalUncles++), () => setState(() => _maternalUncles--)),
                        _buildUniformCounter('أبناء الأخوال', _maternalUnclesOffspring, () => setState(() => _maternalUnclesOffspring++), () => setState(() => _maternalUnclesOffspring--)),
                        const Divider(height: 15),
                        _buildUniformCounter('الخالات', _maternalAunts, () => setState(() => _maternalAunts++), () => setState(() => _maternalAunts--)),
                        _buildUniformCounter('أبناء الخالات', _maternalAuntsOffspring, () => setState(() => _maternalAuntsOffspring++), () => setState(() => _maternalAuntsOffspring--)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _calculateAdvancedInheritance,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy, 
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              icon: Icon(Icons.balance_rounded, color: goldAccent), 
              label: const Text('تشغيل محرك الفرز وحساب الأعيان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResults({required bool isMobile}) {
    return Container(
      height: isMobile ? null : double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
      ),
      child: _showResults 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: primaryNavy, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                child: Column(
                  children: [
                    Row(
                      textDirection: TextDirection.rtl, 
                      children: const [
                        Icon(Icons.assignment_rounded, color: Colors.white), 
                        SizedBox(width: 10), 
                        Text('جدول توزيع الأعيان والأصول الشرعية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))
                      ]
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(onPressed: _showExplanationDialog, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.lightbulb_outline, size: 16), label: const Text('الشرح الفقهي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
                        ElevatedButton.icon(onPressed: _printPdf, style: ElevatedButton.styleFrom(backgroundColor: goldAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.print_rounded, size: 16), label: const Text('طباعة التقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
                        ElevatedButton.icon(onPressed: _downloadPdf, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.download_rounded, size: 16), label: const Text('تحميل PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
                        ElevatedButton.icon(onPressed: _saveToArchive, style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.cloud_upload_rounded, size: 16), label: const Text('حفظ للأرشيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
                      ],
                    )
                  ],
                ),
              ),
              if (isMobile)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: _buildResultCard,
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: _buildResultCard,
                  ),
                ),
            ],
          )
        : Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(Icons.business_center_rounded, size: 80, color: Colors.grey.shade300), 
                const SizedBox(height: 12), 
                Text('قم بإدخال الأعيان وتحديد حالات الاحتياط الفقهي لعرض التقرير.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))
              ]
            ),
          ),
    );
  }

  Widget _buildResultCard(BuildContext context, int index) {
    var res = _results[index];
    bool isBlocked = res['status'].toString().contains('محجوب');
    bool isContingency = res['status'].toString().contains('موقوف'); 
    bool isWill = res['heir'] == 'أحفاد الوصية الواجبة';
    bool isRadd = res['status'] == 'قاعدة الرد';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isBlocked ? Colors.red.shade200 : (isContingency ? Colors.orange.shade300 : Colors.green.shade200))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isBlocked ? Icons.block : (isContingency ? Icons.lock_clock_rounded : (isWill ? Icons.gavel_rounded : (isRadd ? Icons.replay_circle_filled : Icons.check_circle))), color: isBlocked ? Colors.red : (isContingency ? Colors.orange.shade700 : (isWill ? goldAccent : (isRadd ? Colors.blue : Colors.green)))),
                const SizedBox(width: 8),
                Text(res['heir'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                const Spacer(),
                if (!isBlocked) Text('${(res['fraction'] * 100).toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isContingency ? Colors.orange.shade800 : primaryNavy, fontFamily: 'Cairo')),
              ]
            ),
            const SizedBox(height: 8),
            Text('الحالة الشرعية: ${res['status']} | ${res['reason'] ?? res['share']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontFamily: 'Cairo')),
            if (!isBlocked && res['breakdown'].toString().isNotEmpty) ...[
              const Divider(),
              Text(isContingency ? 'النصيب المُجمد والموقوف كأمانة:' : 'النصيب المفرز من الأعيان والأصول:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isContingency ? Colors.orange.shade900 : primaryNavy, fontFamily: 'Cairo')),
              const SizedBox(height: 4),
              Text(res['breakdown'], style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade800, height: 1.6, fontFamily: 'Cairo')),
            ]
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نظام تصفية التركات وتوزيع الأعيان', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: primaryNavy, foregroundColor: Colors.white, centerTitle: true),
      backgroundColor: Colors.grey.shade100,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800; 

          if (isMobile) {
            return SingleChildScrollView(
              child: Column(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(),
                  _buildResults(isMobile: true), 
                ],
              ),
            );
          } else {
            return Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: _buildForm(),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _buildResults(isMobile: false),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}