const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();

// ⏰ دالة مساعدة لجلب الوقت والتاريخ الحالي بتوقيت القاهرة
function getCurrentTimeFormatted() {
    return new Date().toLocaleString('ar-EG', { 
        timeZone: 'Africa/Cairo', 
        year: 'numeric', month: 'numeric', day: 'numeric', 
        hour: '2-digit', minute: '2-digit', hour12: true 
    });
}

// ============================================================================
// 1. إشعارات المحادثات في قسم التوصيل (الرحلات) 🚖
// ============================================================================
exports.sendTripMessageNotification = functions.firestore
    .document('trips/{tripId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const messageData = snap.data();
        const timeString = getCurrentTimeFormatted();

        try {
            const tripDoc = await admin.firestore().collection('trips').doc(context.params.tripId).get();
            if (!tripDoc.exists) return null;
            
            const tripData = tripDoc.data();
            const driverId = tripData.driverId;
            const passengerId = tripData.passengerId || tripData.customerId;

            let receiverId = messageData.senderId === driverId ? passengerId : driverId;
            let senderName = messageData.senderId === driverId ? (tripData.driverName || 'الكابتن') : (tripData.passengerName || tripData.customerName || 'العميل');

            if (!receiverId) return null;

            const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
            if (!userDoc.exists || !userDoc.data().fcmToken) return null;

            const message = {
                token: userDoc.data().fcmToken,
                notification: {
                    title: `رسالة جديدة من ${senderName}`,
                    body: `${messageData.text || 'رسالة جديدة'} | 🕒 ${timeString}`
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                data: { 
                    type: 'trip_chat', 
                    tripId: context.params.tripId 
                }
            };

            await admin.messaging().send(message);
            console.log('تم إرسال إشعار رسالة الرحلة بنجاح');
        } catch (error) { 
            console.error('خطأ في إرسال إشعار رسالة الرحلة:', error); 
        }
    });

// ============================================================================
// 2. إشعارات المحادثات في قسم الاستشارات القانونية ⚖️
// ============================================================================
exports.sendLegalMessageNotification = functions.firestore
    .document('legal_requests/{requestId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const messageData = snap.data();
        const timeString = getCurrentTimeFormatted();

        try {
            const reqDoc = await admin.firestore().collection('legal_requests').doc(context.params.requestId).get();
            if (!reqDoc.exists) return null;
            
            const reqData = reqDoc.data();
            const clientId = reqData.clientId; 
            const lawyerId = reqData.lawyerId || reqData.providerId || reqData.acceptedBy; 

            if (!clientId || !lawyerId) return null;

            let receiverId = messageData.senderId === clientId ? lawyerId : clientId;
            let senderName = messageData.senderId === clientId ? (reqData.clientName || 'العميل') : 'المحامي';

            const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
            if (!userDoc.exists || !userDoc.data().fcmToken) return null;

            const messageBody = messageData.text ? messageData.text : (messageData.imageUrl ? '📎 أرسل مرفقاً' : 'رسالة جديدة');

            const message = {
                token: userDoc.data().fcmToken,
                notification: {
                    title: `رسالة استشارة من ${senderName}`,
                    body: `${messageBody} | 🕒 ${timeString}`
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                data: { 
                    type: 'legal_chat', 
                    requestId: context.params.requestId 
                }
            };

            await admin.messaging().send(message);
            console.log('تم إرسال إشعار رسالة الاستشارة بنجاح');
        } catch (error) { 
            console.error('خطأ في إرسال إشعار رسالة الاستشارة:', error); 
        }
    });

// ============================================================================
// 3. إشعارات الطلبات القانونية الجديدة للمحامين 📢
// ============================================================================
exports.sendNewRequestNotification = functions.firestore
    .document('legal_requests/{requestId}')
    .onCreate(async (snap, context) => {
        const requestData = snap.data();
        const timeString = getCurrentTimeFormatted();

        try {
            const lawyersSnapshot = await admin.firestore().collection('users').where('roles', 'array-contains', 'lawyer').get();
            if (lawyersSnapshot.empty) return null;

            const tokens = [];
            lawyersSnapshot.forEach(doc => {
                if (doc.data().fcmToken) tokens.push(doc.data().fcmToken);
            });

            if (tokens.length === 0) return null;

            const message = {
                tokens: tokens,
                notification: {
                    title: 'طلب استشارة قانونية جديد ⚖️',
                    body: `النوع: ${requestData.serviceType || 'غير محدد'} | 🕒 ${timeString}`
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                data: { 
                    type: 'new_legal_request', 
                    requestId: context.params.requestId 
                }
            };

            await admin.messaging().sendEachForMulticast(message);
            console.log('تم إرسال إشعار الطلب القانوني الجديد بنجاح');
        } catch (error) { 
            console.error('خطأ في إرسال إشعار الطلب القانوني الجديد:', error); 
        }
    });

// ============================================================================
// 4. إشعارات طلبات المشاوير/التوصيل الجديدة للكباتن 🚖
// ============================================================================
exports.sendNewTripNotification = functions.firestore
    .document('trips/{tripId}')
    .onCreate(async (snap, context) => {
        const tripData = snap.data();
        const timeString = getCurrentTimeFormatted();

        try {
            // البحث عن الكباتن اللي دورهم driver
            const driversSnapshot = await admin.firestore().collection('users').where('roles', 'array-contains', 'driver').get();
            if (driversSnapshot.empty) {
                console.log('لم يتم العثور على كباتن (driver) لإرسال الإشعار');
                return null;
            }

            const tokens = [];
            driversSnapshot.forEach(doc => {
                if (doc.data().fcmToken) tokens.push(doc.data().fcmToken);
            });

            if (tokens.length === 0) {
                console.log('تم العثور على كباتن ولكن بدون fcmToken');
                return null;
            }

            // اقتراح السعر لو موجود، أو كلمة "غير محدد"
            const price = tripData.offeredPrice || tripData.price || tripData.fare || 'غير محدد';

            const message = {
                tokens: tokens,
                notification: {
                    title: 'طلب مشوار جديد متاح! 🚖',
                    body: `السعر المقترح: ${price} ج | 🕒 ${timeString}`
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                data: { 
                    type: 'new_trip_request', 
                    tripId: context.params.tripId 
                }
            };

            await admin.messaging().sendEachForMulticast(message);
            console.log(`تم إرسال إشعار المشوار الجديد بنجاح إلى ${tokens.length} كابتن`);
        } catch (error) { 
            console.error('خطأ في إرسال إشعار المشوار الجديد:', error); 
        }
    });