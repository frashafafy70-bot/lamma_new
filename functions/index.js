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
                data: { type: 'trip_chat', tripId: context.params.tripId }
            };

            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ في إرسال إشعار رسالة الرحلة:', error); }
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
                data: { type: 'legal_chat', requestId: context.params.requestId }
            };

            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ في إرسال إشعار رسالة الاستشارة:', error); }
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
                data: { type: 'new_legal_request', requestId: context.params.requestId }
            };

            await admin.messaging().sendEachForMulticast(message);
        } catch (error) { console.error('خطأ في إرسال إشعار الطلب القانوني الجديد:', error); }
    });

// ============================================================================
// 4. إشعارات طلبات المشاوير/التوصيل الجديدة للكباتن 🚖
// ============================================================================
exports.sendNewTripNotification = functions.firestore
    .document('trips/{tripId}')
    .onCreate(async (snap, context) => {
        const tripData = snap.data();
        if (tripData.isDriverPost === true) return null; // لا ترسل إشعار إذا كانت رحلة سفر من الكابتن

        const timeString = getCurrentTimeFormatted();

        try {
            const price = tripData.offeredPrice || tripData.price || tripData.suggestedPrice || 'غير محدد';

            const message = {
                topic: 'drivers_radar',
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
                data: { type: 'new_trip_request', tripId: context.params.tripId }
            };

            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ في إرسال إشعار المشوار الجديد:', error); }
    });

// ============================================================================
// 5. إشعارات إلغاء الرحلة (جديد 🚀)
// ============================================================================
exports.sendTripCancellationNotification = functions.firestore
    .document('trips/{tripId}')
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // نتحقق إذا كانت الحالة تحولت إلى ملغي
        if (beforeData.status !== 'canceled' && afterData.status === 'canceled') {
            const timeString = getCurrentTimeFormatted();
            const canceledBy = afterData.canceledBy; // 'driver' أو 'passenger'
            
            let receiverId = null;
            let title = '';
            let body = `تم إلغاء الرحلة المتفق عليها | 🕒 ${timeString}`;

            if (canceledBy === 'passenger' && afterData.driverId) {
                // العميل لغى، نبلغ الكابتن
                receiverId = afterData.driverId;
                title = 'تم إلغاء الطلب من قبل العميل 🚫';
            } else if (canceledBy === 'driver' && afterData.passengerId) {
                // الكابتن لغى، نبلغ العميل
                receiverId = afterData.passengerId;
                title = 'اعتذر الكابتن عن المشوار 🚫';
            }

            if (!receiverId) return null; // لو مفيش طرف تاني متبعتش حاجة

            try {
                const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
                if (!userDoc.exists || !userDoc.data().fcmToken) return null;

                const message = {
                    token: userDoc.data().fcmToken,
                    notification: {
                        title: title,
                        body: body
                    },
                    android: {
                        priority: "high",
                        notification: {
                            channelId: "lamma_final_sound",
                            sound: "default",
                            clickAction: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    data: { type: 'trip_canceled', tripId: context.params.tripId }
                };

                await admin.messaging().send(message);
            } catch (error) {
                console.error('خطأ في إرسال إشعار الإلغاء:', error);
            }
        }
        return null;
    });