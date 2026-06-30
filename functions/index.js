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

// 6. إشعار للكابتن عند حجز مقعد جديد 💺
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
        } catch (error) { console.error('خطأ إشعار الكابتن:', error); }
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
                    body: 'الكابتن قبل طلب حجز مقاعدك، رحلة سعيدة!'
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

// [هنا ضع الدوال الخمس السابقة الخاصة بالمحادثات والرحلات كما هي في ملفك]