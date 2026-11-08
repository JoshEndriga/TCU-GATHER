# TCU: GATHER
### Taguig City University: General Attendance, Tracking, and Hub for Event Reporting

An integrated campus event management, automated QR attendance tracking, mother-organization clearance validation, and Google Forms-style post-event evaluation platform designed for Taguig City University (TCU).

---

## 🌟 Key Features

1. **Structured Campus Newsfeed**
   - **Poster Hierarchy:** All announcements display official Student Organization posters (e.g., *Supreme Student Council*, *CICT Student Council*) with clearance verification badges.
   - **Visual Event Banners:** Dynamic category banners for mandatory orientations, technology fairs, business summits, and campus assemblies.
   - **Logistics Overview:** Schedules, dates, and campus venues clearly organized.
   - **Detailed Briefing Modal:** Tap any card to access full event guidelines, registration requirements, expected attendee counts, and satisfaction scores.

2. **Centralized Notification Center**
   - Located at the top-right of the AppBar with an unread badge counter.
   - **Action Required:** Direct alerts for events attended that require post-event evaluation before clearance/certificates are issued.
   - **Upcoming Events:** Department-targeted and university-wide announcements.

3. **Google Forms Evaluation Survey (`GoogleFormsSurveyScreen`)**
   - High-fidelity recreation of the mobile Google Forms interface.
   - Distinct question cards, required question markers (`*`), linear satisfaction rating scales (1–5), multiple-choice radio options, and feedback fields.
   - Automated attendance clearance crediting upon submission.

4. **Automated QR Code Check-In**
   - Built with camera-based QR detection (`mobile_scanner`) and 1-tap presentation simulation.
   - Automatic freshman orientation clearance unlocking departmental feeds.

5. **Multi-Organization Officer Workspace**
   - Multi-role permissions for student leaders across councils and collegiate clubs.
   - Live attendee and survey score tracking.
   - Instant generation and export of unique, official Event QR codes (`qr_flutter`).

---

## 👥 Demo Test Accounts

All accounts use the temporary demo password: **`123`**

| Shortcut / Username | Role / Department | Access Level & Highlights |
| :--- | :--- | :--- |
| `unverified` | Freshman Student (CICT) | Account unverified; feed restricted to Mandatory Orientation until check-in. |
| `cict` | Multi-Org Officer (CICT Council + SSC Officer + GDSC) | Department officer with pending evaluation alert and officer management tools. |
| `cba` | CBA Student | Verified business student with access to university & CBA feeds. |
| `cet` | CET Engineering Officer | Engineering student leader with ACES organization tools. |
| `ssc` | SSC Mother Org President | University-wide authority with announcement clearance approvals. |

---

## 🛠️ Built With

- **Framework:** [Flutter](https://flutter.dev/) (Material 3 Theme)
- **Language:** Dart
- **Camera & Scanner:** `mobile_scanner: ^7.5.0`
- **QR Generation:** `qr_flutter: ^4.1.0`
- **Design System:** Taguig City University Maroon (`#7A0C16`) & Gold (`#D4AF37`)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.24+ / 3.47+)
- Android SDK 34+
- Java 17+

### Running the App
```bash
# Clone the repository
git clone https://github.com/JoshEndriga/TCU-GATHER.git

# Navigate to project directory
cd TCU-GATHER

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Build APK
```bash
flutter build apk --debug
```
The compiled APK will be located at `build/app/outputs/flutter-apk/app-debug.apk`.
