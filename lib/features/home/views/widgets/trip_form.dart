// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TripForm extends StatefulWidget {
  final String tripCategory;
  final String vehicleType;
  final bool isSubmittingTrip;
  final TextEditingController errandDetailsController;
  final TextEditingController errandEstimatedCostController;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final Color primaryGreen;
  final Color accentGold;
  final Function(String) onCategoryChanged;
  final Function(String) onVehicleChanged;
  final Function(String) onOpenMapSelection;
  final VoidCallback onSubmit;

  const TripForm({
    super.key,
    required this.tripCategory,
    required this.vehicleType,
    required this.isSubmittingTrip,
    required this.errandDetailsController,
    required this.errandEstimatedCostController,
    required this.pickupController,
    required this.destinationController,
    required this.priceController,
    required this.priceFocusNode,
    required this.primaryGreen,
    required this.accentGold,
    required this.onCategoryChanged,
    required this.onVehicleChanged,
    required this.onOpenMapSelection,
    required this.onSubmit,
  });

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // 🟢 دالة الاستماع للصوت وتحويله لنص بالتحديث الأخير للمكتبة
  void _listenToSpeech() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            widget.errandDetailsController.text = val.recognizedWords;
          }),
          // 🟢 الحل للتحذير: استخدام SpeechListenOptions بدلاً من localeId المباشر
          listenOptions: stt.SpeechListenOptions(
            localeId: 'ar_EG',
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. اختيار نوع الرحلة (داخلي / طلبات)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryChip('داخلي', Icons.local_taxi_rounded),
                SizedBox(width: 15.w),
                _buildCategoryChip('طلبات', Icons.shopping_bag_rounded),
              ],
            ),
            SizedBox(height: 15.h),

            // 2. اختيار نوع المركبة (يظهر فقط في الداخلي)
            if (widget.tripCategory == 'داخلي') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVehicleChip('سيارة', Icons.directions_car_rounded),
                  SizedBox(width: 10.w),
                  _buildVehicleChip('موتوسيكل', Icons.motorcycle_rounded),
                  SizedBox(width: 10.w),
                  _buildVehicleChip('توكتوك', Icons.electric_rickshaw_rounded),
                ],
              ),
              SizedBox(height: 15.h),
            ],

            // 3. نقطة الانطلاق
            _buildInputField(
              controller: widget.pickupController,
              label: 'موقعك الحالي / مكان الاستلام',
              icon: Icons.my_location_rounded,
              iconColor: widget.accentGold,
              readOnly: true,
              onTap: () => widget.onOpenMapSelection('pickup'),
            ),
            SizedBox(height: 12.h),

            // 4. نقطة الوصول
            _buildInputField(
              controller: widget.destinationController,
              label: 'مكان الوصول / تسليم الطلب',
              icon: Icons.location_on_rounded,
              iconColor: widget.primaryGreen,
              readOnly: true,
              onTap: () => widget.onOpenMapSelection('destination'),
            ),
            SizedBox(height: 12.h),

            // 5. حقول خاصة بقسم "طلبات" (مع المايكروفون الذكي)
            if (widget.tripCategory == 'طلبات') ...[
              // حقل التفاصيل بالصوت
              TextFormField(
                controller: widget.errandDetailsController,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'تفاصيل الطلبات (اكتب أو سجل صوتك)',
                  labelStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.list_alt_rounded, color: widget.primaryGreen),
                  suffixIcon: GestureDetector(
                    onTap: _listenToSpeech,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.red : widget.accentGold,
                        size: 26.sp,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: widget.accentGold, width: 2)),
                ),
              ),
              SizedBox(height: 12.h),

              // حقل التكلفة التقريبية للطلبات
              _buildInputField(
                controller: widget.errandEstimatedCostController,
                label: 'سعر الطلبات التقريبي (للشراء)',
                icon: Icons.receipt_long_rounded,
                iconColor: widget.primaryGreen,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
            ],

            // 6. سعر التوصيل (الأجرة)
            _buildInputField(
              controller: widget.priceController,
              focusNode: widget.priceFocusNode,
              label: 'أجرة التوصيل للكابتن',
              icon: Icons.payments_rounded,
              iconColor: widget.accentGold,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.h),

            // 7. زر الإرسال
            SizedBox(
              height: 55.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                ),
                onPressed: widget.isSubmittingTrip ? null : widget.onSubmit,
                child: widget.isSubmittingTrip
                    ? SizedBox(width: 25.w, height: 25.w, child: CircularProgressIndicator(color: widget.accentGold, strokeWidth: 3))
                    : Text(
                        widget.tripCategory == 'طلبات' ? 'إرسال طلب المشتروات للكابتن' : 'إرسال الطلب للكابتن',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
              ),
            ),
            // مسافة أمان للكيبورد
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20.h : 0),
          ],
        ),
      ),
    );
  }

  // 🟢 ودجت مساعدة لشكل حقول الإدخال
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: widget.accentGold, width: 2)),
      ),
    );
  }

  // 🟢 ودجت مساعدة لشكل اختيار نوع الرحلة
  Widget _buildCategoryChip(String title, IconData icon) {
    bool isSelected = widget.tripCategory == title;
    return InkWell(
      onTap: () => widget.onCategoryChanged(title),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? widget.primaryGreen : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: isSelected ? widget.accentGold : Colors.grey.shade600),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 ودجت مساعدة لشكل اختيار نوع المركبة
  Widget _buildVehicleChip(String title, IconData icon) {
    bool isSelected = widget.vehicleType == title;
    return InkWell(
      onTap: () => widget.onVehicleChanged(title),
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? widget.accentGold.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: isSelected ? widget.accentGold : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: isSelected ? widget.primaryGreen : Colors.grey.shade500),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: isSelected ? widget.primaryGreen : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}