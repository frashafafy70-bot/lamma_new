// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:typed_data';

class LegalChatPage extends StatefulWidget {
  final String requestId;
  const LegalChatPage({super.key, required this.requestId});

  @override
  State<LegalChatPage> createState() => _LegalChatPageState();
}

class _LegalChatPageState extends State<LegalChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);
  
  bool _isUploading = false; 
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) return;
    String textToSend = _messageController.text.trim();
    _messageController.clear(); 

    await FirebaseFirestore.instance.collection('legal_requests').doc(widget.requestId).collection('messages').add({
      'text': textToSend,
      'imageUrl': imageUrl, 
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      setState(() => _isUploading = true);

      Uint8List imageBytes = await image.readAsBytes();
      String fileName = 'legal_chats/${widget.requestId}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(imageUrl: downloadUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء رفع المستند ⚠️', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openAttachment(String url) async {
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح هذا المرفق ⚠️', style: TextStyle(fontFamily: 'Cairo'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محادثة الاستشارة ⚖️', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Directionality(
        textDirection: TextDirection.rtl, 
        child: Column(
          children: [
            if (_isUploading) LinearProgressIndicator(color: goldAccent, backgroundColor: primaryNavy),
              
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('legal_requests').doc(widget.requestId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryNavy));
                  var messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('ابدأ المحادثة الآن واطرح استفسارك..', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontFamily: 'Cairo')),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msg = messages[index].data() as Map<String, dynamic>;
                      bool isMe = msg['senderId'] == userId;
                      bool hasImage = msg.containsKey('imageUrl') && msg['imageUrl'] != null;
                      bool hasText = msg.containsKey('text') && msg['text'].toString().trim().isNotEmpty;

                      // 🕒 الحل السحري لمشكلة الوقت
                      DateTime dt;
                      if (msg['timestamp'] != null) {
                        dt = (msg['timestamp'] as Timestamp).toDate();
                      } else {
                        dt = DateTime.now();
                      }
                      String period = dt.hour >= 12 ? 'م' : 'ص';
                      int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                      String minute = dt.minute.toString().padLeft(2, '0');
                      String timeText = '$hour:$minute $period';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? primaryNavy : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            ),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            border: isMe ? null : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasImage)
                                GestureDetector(
                                  onTap: () => _openAttachment(msg['imageUrl']), 
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      msg['imageUrl'],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(height: 150, width: double.infinity, child: Center(child: CircularProgressIndicator(color: isMe ? goldAccent : primaryNavy)));
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 120, width: double.infinity,
                                          decoration: BoxDecoration(color: isMe ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: isMe ? Colors.white30 : Colors.grey.shade300)),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_rounded, color: isMe ? Colors.white70 : Colors.grey.shade500, size: 40),
                                              const SizedBox(height: 8),
                                              Text('اضغط لعرض المرفق 📎', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              if (hasImage && hasText) const SizedBox(height: 8),
                              if (hasText) Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                              const SizedBox(height: 4),
                              Text(timeText, style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontFamily: 'Cairo', fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.attach_file_rounded, color: primaryNavy, size: 28), onPressed: _isUploading ? null : _pickAndUploadImage),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isUploading,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isUploading ? Colors.grey : goldAccent,
                    radius: 24,
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _isUploading ? null : () => _sendMessage()),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}