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
                        channelId: "lamma_alerts_channel_v2", 
                        priority: "max",
                        sound: "default"
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default"
                        }
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
                        channelId: "lamma_alerts_channel_v2", 
                        priority: "max",
                        sound: "default"
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default"
                        }
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
            const tripDoc = await admin.firestore().collection('trips').doc(tripId).get();
            if (!tripDoc.exists) return null;

            const tripData = tripDoc.data();
            const driverId = tripData.driverId || '';
            const passengerId = tripData.passengerId || '';

            const receiverId = senderId === driverId ? passengerId : driverId;
            if (!receiverId) return null;

            const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
            const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
            
            if (!receiverDoc.exists || !receiverDoc.data().fcmToken) return null;
            
            const senderName = senderDoc.exists ? (senderDoc.data().name || 'مستخدم لمة') : 'مستخدم لمة';

            let bodyText = 'أرسل لك رسالة جديدة';
            if (messageData.type === 'image') bodyText = 'أرسل لك صورة 📸';
            if (messageData.type === 'audio') bodyText = 'أرسل لك مقطع صوتي 🎙️';

            const message = {
                token: receiverDoc.data().fcmToken,
                notification: {
                    title: senderName,
                    body: bodyText
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_alerts_channel_v2", 
                        priority: "max",
                        sound: "default"
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default"
                        }
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

// 9. إشعار لكل الكباتن عند طلب رحلة جديدة من العميل (الرادار) 📡
exports.notifyDriversNewTrip = functions.firestore
    .document('trips/{tripId}')
    .onCreate(async (snap, context) => {
        const tripData = snap.data();

        // التأكد إن الطلب من عميل مش كابتن بينشر رحلة
        if (tripData.isDriverPost === true) return null;

        const passengerName = tripData.passengerName || 'عميل جديد';
        const destination = tripData.destination || 'وجهة غير محددة';
        const category = tripData.tripCategory || 'رحلة';

        // تجهيز الإشعار وإرساله لكل الكباتن المشتركين في الرادار
        const message = {
            topic: 'drivers_radar', 
            notification: {
                title: `طلب ${category} جديد! 🚕`,
                body: `${passengerName} يطلب رحلة إلى ${destination}`
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "lamma_alerts_channel_v2", 
                    priority: "max",
                    sound: "default"
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default" 
                    }
                }
            },
            data: { 
                type: 'new_trip_request', 
                tripId: context.params.tripId 
            }
        };

        try {
            await admin.messaging().send(message);
            console.log('تم إرسال إشعار الرادار بنجاح');
        } catch (error) { 
            console.error('خطأ إشعار الرادار:', error); 
        }
    });

// 10. إشعارات التفاوض (البينج بونج) بين الكابتن والعميل 🏓
exports.notifyTripNegotiation = functions.firestore
    .document('trips/{tripId}')
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // 1. التأكد إن الحالة تفاوض
        if (afterData.status !== 'negotiating') return null;

        // 2. التأكد إن السعر أو المفاوض اتغير عشان مانبعتش إشعار متكرر على الفاضي
        if (beforeData.negotiationPrice === afterData.negotiationPrice && 
            beforeData.lastNegotiator === afterData.lastNegotiator) {
            return null;
        }

        const lastNegotiator = afterData.lastNegotiator;
        const price = afterData.negotiationPrice;
        const tripId = context.params.tripId;
        
        let receiverId = null;
        let title = '';
        let body = '';

        // 3. تحديد المستلم والرسالة بناءً على مين اللي فاوض
        if (lastNegotiator === 'driver') {
            // لو الكابتن اللي فاوض، المستلم هو العميل
            receiverId = afterData.passengerId; 
            title = 'عرض سعر جديد 🚕';
            body = `الكابتن اقترح سعر ${price} ج.م`;
        } 
        else if (lastNegotiator === 'passenger') {
            // لو العميل اللي فاوض، المستلم هو الكابتن
            receiverId = afterData.driverId; 
            title = 'رد من العميل 👤';
            body = `العميل اقترح سعر ${price} ج.م`;
        }

        // لو مفيش مستلم لأي سبب، نوقف الدالة
        if (!receiverId) return null;

        try {
            // 4. جلب توكن المستلم من الداتا بيز
            const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
            if (!receiverDoc.exists || !receiverDoc.data().fcmToken) return null;

            const message = {
                token: receiverDoc.data().fcmToken,
                notification: {
                    title: title,
                    body: body
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "lamma_alerts_channel_v2", 
                        priority: "max",
                        sound: "default"
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default"
                        }
                    }
                },
                data: { 
                    type: 'negotiation_offer', 
                    tripId: tripId 
                }
            };

            // 5. إرسال الإشعار
            await admin.messaging().send(message);
            console.log(`تم إرسال إشعار التفاوض بنجاح إلى ${receiverId}`);
        } catch (error) { 
            console.error('خطأ في إرسال إشعار التفاوض:', error); 
        }
    });