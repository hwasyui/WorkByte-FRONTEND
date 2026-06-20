// Firebase Messaging service worker stub for admin web panel.
// Full FCM push is mobile-only; this file prevents 404 errors on web.
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD8M5c8v95PvJ1x6Hqufal4lnhkcB3hUJA',
  authDomain: 'workbyte-a5280.firebaseapp.com',
  projectId: 'workbyte-a5280',
  storageBucket: 'workbyte-a5280.firebasestorage.app',
  messagingSenderId: '12893610585',
  appId: '1:12893610585:web:5f1fc6a0926b180fcb4748',
});

const messaging = firebase.messaging();
