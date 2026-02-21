# Nizam - نظام

<a href='https://play.google.com/store/apps/details?id=com.badawi.smartStudent'><img alt='Get it on Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png' width=200/></a>

A powerful, offline-first student and class management system built with Flutter. Designed for tutors and educational centers, Nizam offers seamless data synchronization across multiple devices.

---

## 🌟 Key Features

-   **Automatic Cloud Sync:** Built a smart synchronization service using **Firebase** to automatically keep data consistent across all user devices. Any change on one device is reflected on others.
-   **Offline-First Architecture:** Leverages the **Hive** database for incredibly fast, local, and offline data operations. The app is fully functional without an internet connection.
-   **Advanced Data Import/Export:**
    -   **CSV Import:** A robust CSV import feature with an advanced **conflict resolution dialog**, allowing the user to granularly select which records to update or skip.
    -   **Secure JSON Backup:** Google Play-compliant local backup/restore functionality using the Storage Access Framework (`FilePicker`), requiring no invasive storage permissions.
-   **Comprehensive Management:** Full CRUD (Create, Read, Update, Delete) operations for Students, Classes, and Groups.
-   **Efficient Payment Tracking:**
    -   Track student payment statuses (Paid, Expired, Never Paid).
    -   Integrated **QR Code scanning** (`mobile_scanner`) for quick student lookups and payment registration.
    -   Batch payment updates for multiple students at once.
-   **Insightful Dashboard:** An analytics dashboard featuring charts (`fl_chart`) to visualize monthly revenue and student distribution.
-   **Intuitive User Experience:**
    -   Clean, responsive UI with dynamic theming (Light/Dark).
    -   Swipe actions (`flutter_slidable`) for quick access to common operations like calling a parent or deleting a student.
    -   Multi-select functionality for performing batch actions.
    -   Powerful search and filtering capabilities.

---

## 🛠️ Tech Stack & Architecture

-   **Framework:** Flutter
-   **Architecture:** Feature-Driven Directory Structure
-   **State Management:** `flutter_bloc`
-   **Database:**
    -   **Local/Offline:** `hive`
    -   **Cloud/Sync:** `cloud_firestore`
-   **Authentication:** `firebase_auth`
-   **Asynchronous Tasks:** `workmanager` for background synchronization.
-   **Hardware Integration:** `mobile_scanner` (Camera), `permission_handler`
-   **File Handling:** `file_picker`, `csv`, `pdf` (for potential future reports)
-   **UI & Theming:** `adaptive_theme`, `fl_chart`, `google_fonts`

---

## 🚀 Getting Started

**1. Clone the repository:**

```bash
git clone https://github.com/AhmeddElshiekh/student_manager.git
cd student_manager
```

**2. Set up Firebase:**

-   Create a new project on the [Firebase Console](https://console.firebase.google.com/).
-   Add an Android and/or iOS app to your Firebase project.
-   Follow the instructions to add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files to the project.
-   Enable **Authentication** (Email/Password) and **Firestore Database**.

**3. Install dependencies:**

```bash
flutter pub get
```

**4. Run the app:**

```bash
flutter run
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/AhmeddElshiekh/student_manager/issues).

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
