const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();

function getCurrentTimeFormatted() {
    return new Date().toLocaleString('ar-EG', { 
        timeZone: 'Africa/Cairo', 
        year: 'numeric', month: 'numeric', day: 'numeric', 
        hour: '2-digit', minute: '2-digit', hour12: true 
    });
}

// 6. إشعار للسائق عند حجز مقعد جديد 💺
exports.notifyDriverNewBooking = functions.firestore
    .document('trip_bookings/{bookingId}')
    .onCreate(async (snap, context) => {
        const bookingData = snap.data();
        const driverId = bookingData.driverId;
        const passengerId = bookingData.passengerId;
        const seats = bookingData.seats;

        try {
            const driverDoc = await admin.firestore().collection('users').doc(driverId).get();
            const passengerDoc = await admin.firestore().collection('users').doc(passengerId).get();
            
            if (!driverDoc.exists || !driverDoc.data().fcmToken) return null;
            const passengerName = passengerDoc.exists ? passengerDoc.data().name : 'عميل جديد';

            const message = {
                token: driverDoc.data().fcmToken,
                notification: {
                    title: 'طلب حجز مقعد جديد! 💺',
                    body: `${passengerName} حجز ${seats} مقاعد في رحلتك.`
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        priority: "max",
                        sound: "default"
                    }
                },
                data: { type: 'new_booking', bookingId: context.params.bookingId }
            };
            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ إشعار السائق:', error); }
    });

// 7. إشعار للعميل عند قبول طلبه 🏁
exports.notifyPassengerBookingStatus = functions.firestore
    .document('trip_bookings/{bookingId}')
    .onUpdate(async (change, context) => {
        const afterData = change.after.data();
        if (afterData.status !== 'accepted') return null;

        try {
            const passengerDoc = await admin.firestore().collection('users').doc(afterData.passengerId).get();
            if (!passengerDoc.exists || !passengerDoc.data().fcmToken) return null;

            const message = {
                token: passengerDoc.data().fcmToken,
                notification: {
                    title: 'تم قبول طلبك! 🎉',
                    body: 'السائق قبل طلب حجز مقاعدك، رحلة سعيدة!'
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        priority: "max",
                        sound: "default"
                    }
                },
                data: { type: 'booking_accepted', bookingId: context.params.bookingId }
            };
            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ إشعار العميل:', error); }
    });

// 8. إشعار المحادثات اللحظية (الشات) 💬
exports.sendChatNotification = functions.firestore
    .document('trips/{tripId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const messageData = snap.data();
        const tripId = context.params.tripId;
        const senderId = messageData.senderId;

        if (!senderId) return null;

        try {
            // 1. جلب بيانات الرحلة لمعرفة الطرف الآخر
            const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
            if (!tripDoc.exists) return null;

            const tripData = tripDoc.data();
            const driverId = tripData.driverId || '';
            const passengerId = tripData.passengerId || '';

            // 2. تحديد المستلم
            const receiverId = senderId === driverId ? passengerId : driverId;
            if (!receiverId) return null;

            // 3. جلب بيانات المستلم (للحصول على التوكن) والمرسل (للحصول على الاسم)
            const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
            const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
            
            if (!receiverDoc.exists || !receiverDoc.data().fcmToken) return null;
            
            const senderName = senderDoc.exists ? (senderDoc.data().name || 'مستخدم لمة') : 'مستخدم لمة';

            // 4. تجهيز نص الرسالة
            let bodyText = 'أرسل لك رسالة جديدة';
            if (messageData.type === 'image') bodyText = 'أرسل لك صورة 📷';
            if (messageData.type === 'audio') bodyText = 'أرسل لك مقطع صوتي 🎤';

            // 5. تجهيز الإشعار بنفس إعدادات تطبيق لمة
            const message = {
                token: receiverDoc.data().fcmToken,
                notification: {
                    title: senderName,
                    body: bodyText
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_final_sound",
                        priority: "max",
                        sound: "default"
                    }
                },
                data: { 
                    type: 'chat', 
                    tripId: tripId 
                }
            };

            await admin.messaging().send(message);
        } catch (error) { console.error('خطأ إشعار الشات:', error); }
    });