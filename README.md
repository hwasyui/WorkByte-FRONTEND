# 📱 WorkByte Frontend

Flutter mobile application for **WorkByte**, providing a modern interface for clients and freelancers to interact and collaborate. A freelance job marketplace with AI-powered features.

---

## 📌 Overview

This repository contains the Flutter frontend of WorkByte, including:

* Authentication (email/OTP + Google OAuth 2.0)
* Job discovery: Most Relevant feed (profile-matched via cosine similarity) and Most Popular feed (ranked by proposals + views)
* Job browsing, search, and category filtering
* Proposal submission and contract management
* AI features: job fit analysis, CV upload & analysis
* Freelancer & client profiles with portfolio, skills, and work experience
* Direct messaging (DM) with WebSocket real-time support
* Push notifications via Firebase Cloud Messaging (FCM)
* Admin panel (web view)
* Report, appeal, and moderation flows

---

## 🏗️ Tech Stack

* **Framework**: Flutter (Dart)
* **State Management**: Provider
* **HTTP Client**: http package
* **Auth**: JWT + Google Sign-In SDK
* **Push Notifications**: Firebase Cloud Messaging (FCM)
* **Real-time**: WebSocket (DM threads)
* **Storage**: Supabase Storage (via backend)

---

## 🔗 Related Repositories

* Backend: https://github.com/hwasyui/WorkByte-BACKEND
* Database: https://github.com/hwasyui/WorkByte-DATABASE

---

## 👥 Team Members & Commit Codes

| Code  | Name           | GitHub                            |
| ----- | -------------- | --------------------------------- |
| [ASW] | hwasyui        | https://github.com/hwasyui        |
| [IKP] | tannpsy        | https://github.com/tannpsy        |
| [SKF] | sarahkimberlyy | https://github.com/sarahkimberlyy |

---

## 📝 Notes

* Configure `.env` with `BACKEND` URL before running
* Run `flutter pub get` to install dependencies
* Firebase `google-services.json` must be placed in `android/app/`

---

## 📄 License

This project is for academic (capstone) purposes.
