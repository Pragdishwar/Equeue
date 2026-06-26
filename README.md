# Equeue — Smart Queue Management System

**Equeue** is a modern, virtual token-based queue management application built to eliminate physical waiting lines. Users can browse service branches, join queues remotely, monitor their position in real time with live countdowns, and check-in contactless via QR code. 

Features a comprehensive, real-time Admin Management console for branch operators to manage customer flow, call next tokens, analyze daily traffic, and update branch configurations.

---

## 🚀 Key Features

### 👤 Customer App
* **Remote Token Generation:** Browse nearby branches and join a queue for any service instantly.
* **Live Queue Tracking:** View your exact position ("3rd in line") and real-time estimated wait times.
* **Smart Notifications:** Receive turn reminders and queue updates instantly.
* **QR Check-in:** Scan your generated ticket's QR code at the service counter to check in.
* **Token History:** Track past visits and queue statuses (Served, Skipped, Cancelled).

### 💼 Admin Console
* **Queue Controller:** Call the next customer, skip no-shows, complete sessions, and manage queues in real time.
* **QR Scanner:** Integrated camera-based scanner to check in arriving customers instantly.
* **Branch & Service CRUD:** Manage multiple branch locations, set active status, and configure average service times.
* **Analytics Reports:** Visualize peak hours, service statistics, and daily completion/cancellation rates.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter SDK (Dart) — Supports Web, Windows, Android, and iOS.
* **State Management:** Riverpod (Clean Provider architecture).
* **Navigation:** GoRouter (Declarative shell routing and role-based redirect guards).
* **Backend:** Supabase (Auth, PostgreSQL database, and Realtime channels for instant UI updates).
* **Design:** Custom dark-mode theme utilizing glassmorphism and modern HSL colors.

---

## 📂 Project Structure

```text
lib/
├── app.dart                   # Main MaterialApp.router setup
├── main.dart                  # App entry point & Supabase initialization
├── config/
│   ├── constants.dart         # Table names, enums, & API credentials
│   └── theme.dart             # Dark-mode glassmorphism design system
├── models/                    # Data models (UserProfile, Branch, Service, Token, etc.)
├── providers/                 # Riverpod state providers
├── router/                    # GoRouter navigational shell & route configurations
├── screens/                   # Screen modules
│   ├── admin/                 # Admin dashboard, queue management, reports, branch setup
│   ├── auth/                  # Validated login & register screens
│   ├── onboarding/            # App introduction sliders
│   ├── splash/                # Startup splash animation
│   └── user/                  # Customer home, branches, live queue tracking, notifications
├── services/                  # Business logic (Auth, Supabase, QR, Branch, Queue operations)
└── widgets/                   # Reusable premium widgets (Common, Queue, Admin-specific)
```

---

## 🏁 Getting Started

### Prerequisites
* Flutter SDK (configured in PATH)
* Visual Studio (with C++ Desktop development tools) or a Web browser (Google Chrome)

### Step 1: Clone the Project
```bash
git clone https://github.com/Pragdishwar/Equeue.git
cd Equeue
```

### Step 2: Configure Supabase
1. Create a free project on the [Supabase Console](https://supabase.com/).
2. Run the database migration script in [supabase/migrations/001_initial_schema.sql](file:///c:/Users/pragd/Desktop/Git%20Projects/Equeue/supabase/migrations/001_initial_schema.sql) in your Supabase SQL Editor.
3. Open your project settings, copy your API URL and public anon key, and update the config file:
   [lib/config/constants.dart](file:///c:/Users/pragd/Desktop/Git%20Projects/Equeue/lib/config/constants.dart)
   ```dart
   static const String url = 'https://your-project.supabase.co';
   static const String anonKey = 'your-public-anon-key';
   ```

### Step 3: Run the Application
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Launch the application:
   * **For Google Chrome (Web):**
     ```bash
     flutter run -d chrome
     ```
   * **For Windows Desktop:**
     ```bash
     flutter run -d windows
     ```

---

## 🔒 Row-Level Security (RLS) & Triggers
Database tables are secured with custom PostgreSQL policies:
* Users can only read and write their own tokens/profiles.
* Trigger function `public.handle_new_user()` automatically provisions a public profile record when a user signs up.
* Admin operations are secured using the `public.is_admin()` database helper to avoid recursive policy loops.