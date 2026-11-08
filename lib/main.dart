import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const TcuGatherApp());
}

// -------------------------------------------------------------
// MODELS
// -------------------------------------------------------------

class UserAccount {
  final String username; // Shortcut (e.g. 'unverified', 'cba', 'cict', 'cet', 'ssc')
  final String studentNumber;
  String password;
  String fullName;
  String college; // 'CICT', 'CBA', 'CET', 'CAS', 'University-Wide'
  bool isVerified; // True if attended TCU Orientation
  List<OrgMembership> orgMemberships;

  UserAccount({
    required this.username,
    required this.studentNumber,
    required this.password,
    required this.fullName,
    required this.college,
    required this.isVerified,
    required this.orgMemberships,
  });

  bool get isSscAdmin =>
      orgMemberships.any((m) => m.orgId == 'ssc' && m.role == 'President');

  bool isOfficerIn(String orgId) =>
      orgMemberships.any((m) => m.orgId == orgId && m.role != 'Member');

  bool get hasAnyOfficerRole =>
      orgMemberships.any((m) => m.role == 'Officer' || m.role == 'President');
}

class OrgMembership {
  final String orgId;
  final String orgName;
  final String collegeAffiliation; // 'CICT', 'CBA', 'CET', 'University-Wide'
  String role; // 'Member', 'Officer', 'President'

  OrgMembership({
    required this.orgId,
    required this.orgName,
    required this.collegeAffiliation,
    required this.role,
  });
}

class CampusAnnouncement {
  final String id;
  final String title;
  final String description;
  final String orgId;
  final String orgName; // POSTER (ORGANIZATION NAME, NOT ACCOUNT)
  final String targetAudience; // 'All', 'CICT', 'CBA', 'CET', 'CAS'
  final String venue;
  final String dateTime;
  final String bannerCategory; // 'orientation', 'tech', 'business', 'assembly', 'workshop'
  final bool isEvent;
  final bool isOrientation;
  bool isApproved;
  final String approvalStatus; // 'Cleared by Mother Org', 'Pending Mother Org Clearance'
  List<String> surveyQuestions;
  int attendeesCount;
  double averageRating;

  CampusAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.orgId,
    required this.orgName,
    required this.targetAudience,
    required this.venue,
    required this.dateTime,
    this.bannerCategory = 'tech',
    this.isEvent = true,
    this.isOrientation = false,
    this.isApproved = true,
    this.approvalStatus = 'Cleared by Mother Org',
    this.surveyQuestions = const [],
    this.attendeesCount = 0,
    this.averageRating = 5.0,
  });
}

// -------------------------------------------------------------
// ROOT APPLICATION (MAROON & GOLD THEME)
// -------------------------------------------------------------

class TcuGatherApp extends StatefulWidget {
  const TcuGatherApp({super.key});

  @override
  State<TcuGatherApp> createState() => _TcuGatherAppState();
}

class _TcuGatherAppState extends State<TcuGatherApp> {
  late List<UserAccount> _users;
  UserAccount? _currentUser;
  late List<CampusAnnouncement> _announcements;

  final Set<String> _checkedInEventIds = {};
  final Set<String> _completedSurveyEventIds = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 5 Distinct Pre-seeded accounts (all password: 123)
    _users = [
      // 1. Unverified Freshman (Orientation Locked)
      UserAccount(
        username: 'unverified',
        studentNumber: '2026-00001-TG-0',
        password: '123',
        fullName: 'Paul Samuel Del Valle',
        college: 'CICT',
        isVerified: false, // UNVERIFIED: Only sees TCU Orientation!
        orgMemberships: [],
      ),

      // 2. Verified Student from CBA (Different College)
      UserAccount(
        username: 'cba',
        studentNumber: '2024-20114-TG-0',
        password: '123',
        fullName: 'Christian Dale Santos',
        college: 'CBA',
        isVerified: true,
        orgMemberships: [
          OrgMembership(
            orgId: 'jfinex',
            orgName: 'Junior Financial Executives (JFINEX - CBA)',
            collegeAffiliation: 'CBA',
            role: 'Member',
          ),
        ],
      ),

      // 3. Multi-Org Officer (CICT Council + SSC Mother Org Officer + GDSC)
      UserAccount(
        username: 'cict',
        studentNumber: '2023-10291-TG-0',
        password: '123',
        fullName: 'Justine Mendoza (Multi-Org Officer)',
        college: 'CICT',
        isVerified: true,
        orgMemberships: [
          OrgMembership(
            orgId: 'cict_sc',
            orgName: 'Computer Studies Student Council (CICT)',
            collegeAffiliation: 'CICT',
            role: 'Officer',
          ),
          OrgMembership(
            orgId: 'ssc',
            orgName: 'Supreme Student Council (Mother Org)',
            collegeAffiliation: 'University-Wide',
            role: 'Officer',
          ),
          OrgMembership(
            orgId: 'gdsc',
            orgName: 'Google Developer Student Clubs - TCU',
            collegeAffiliation: 'CICT',
            role: 'President',
          ),
        ],
      ),

      // 4. Officer from Different College (CET - Engineering)
      UserAccount(
        username: 'cet',
        studentNumber: '2023-40182-TG-0',
        password: '123',
        fullName: 'Engr. Student Officer (CET)',
        college: 'CET',
        isVerified: true,
        orgMemberships: [
          OrgMembership(
            orgId: 'aces',
            orgName: 'Association of Civil & Electrical Engineering (ACES)',
            collegeAffiliation: 'CET',
            role: 'Officer',
          ),
        ],
      ),

      // 5. Supreme Student Council President (Central Mother Org Authority)
      UserAccount(
        username: 'ssc',
        studentNumber: '2022-10001-TG-0',
        password: '123',
        fullName: 'Rowell Joshua B. Endriga (SSC President)',
        college: 'University-Wide',
        isVerified: true,
        orgMemberships: [
          OrgMembership(
            orgId: 'ssc',
            orgName: 'Supreme Student Council (Mother Org)',
            collegeAffiliation: 'University-Wide',
            role: 'President',
          ),
          OrgMembership(
            orgId: 'cso',
            orgName: 'Council of Student Organizations (CSO)',
            collegeAffiliation: 'University-Wide',
            role: 'President',
          ),
        ],
      ),
    ];

    // Seeded check-in: Pre-mark Tech Summit attendance so verified users have an immediate pending evaluation in notifications!
    _checkedInEventIds.add('ev-tech-summit');

    _announcements = [
      CampusAnnouncement(
        id: 'ev-orientation',
        title: 'TCU Grand Student Orientation 2026',
        description:
            'Mandatory university orientation for all new freshmen and transferees. Attending and scanning your QR code here verifies your account and unlocks your department access and college announcements.',
        orgId: 'ssc',
        orgName: 'Supreme Student Council (Mother Org)',
        targetAudience: 'All',
        venue: 'TCU Main Auditorium',
        dateTime: 'November 10, 2026 | 8:30 AM',
        bannerCategory: 'orientation',
        isEvent: true,
        isOrientation: true,
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: [
          'How clear were the university campus guidelines?',
          'How helpful was the tour of college departments?',
        ],
        attendeesCount: 320,
        averageRating: 4.9,
      ),
      CampusAnnouncement(
        id: 'ev-tech-summit',
        title: 'CICT Tech Summit & Coding Fair',
        description:
            'Annual innovation and software exhibition organized by CICT. Open to all Computer Science and IT majors, featuring expert keynotes, project demos, and industry partner booths.',
        orgId: 'cict_sc',
        orgName: 'Computer Studies Student Council (CICT)',
        targetAudience: 'CICT',
        venue: 'Main AVR (4th Floor)',
        dateTime: 'November 14, 2026 | 9:00 AM – 3:00 PM',
        bannerCategory: 'tech',
        isEvent: true,
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: [
          'Rate the technical depth of the masterclass',
          'Were the hands-on project demos useful?',
        ],
        attendeesCount: 142,
        averageRating: 4.8,
      ),
      CampusAnnouncement(
        id: 'ev-cba-summit',
        title: 'CBA Technopreneurship & Business Pitch',
        description:
            'Annual entrepreneurship conference for College of Business Administration students, featuring start-up founders, financial modeling workshops, and student venture competitions.',
        orgId: 'jfinex',
        orgName: 'Junior Financial Executives (JFINEX - CBA)',
        targetAudience: 'CBA',
        venue: 'TCU Mini-Theater',
        dateTime: 'November 16, 2026 | 10:00 AM',
        bannerCategory: 'business',
        isEvent: true,
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: ['Was the financial modeling seminar helpful?'],
        attendeesCount: 98,
        averageRating: 4.9,
      ),
      CampusAnnouncement(
        id: 'ev-midterm-forum',
        title: 'TCU Midterm University Assembly',
        description:
            'Campus-wide consultative forum by the Supreme Student Council discussing student welfare, campus Wi-Fi infrastructure upgrades, and semester clearance procedures.',
        orgId: 'ssc',
        orgName: 'Supreme Student Council (Mother Org)',
        targetAudience: 'All',
        venue: 'University Gymnasium',
        dateTime: 'November 18, 2026 | 1:00 PM',
        bannerCategory: 'assembly',
        isEvent: true,
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: ['Did the forum address your student concerns?'],
        attendeesCount: 450,
        averageRating: 4.7,
      ),
      CampusAnnouncement(
        id: 'ev-cyber-workshop',
        title: 'CICT Cyber Security & Ethical Hacking Workshop',
        description:
            'Hands-on network defense, penetration testing, and ethical hacking workshop for CICT students. Required bring-your-own-laptop with Kali Linux virtual machine.',
        orgId: 'cict_sc',
        orgName: 'Computer Studies Student Council (CICT)',
        targetAudience: 'CICT',
        venue: 'Computer Lab 3',
        dateTime: 'November 22, 2026 | 10:00 AM',
        bannerCategory: 'workshop',
        isEvent: true,
        isApproved: false, // PENDING MOTHER ORG APPROVAL!
        approvalStatus: 'Pending Mother Org Clearance',
        surveyQuestions: ['Overall workshop rating'],
        attendeesCount: 0,
        averageRating: 0.0,
      ),
    ];
  }

  void _login(UserAccount user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _logout() {
    setState(() {
      _currentUser = null;
    });
  }

  void _verifyCurrentUser() {
    if (_currentUser != null) {
      setState(() {
        _currentUser!.isVerified = true;
      });
    }
  }

  void _addAnnouncement(CampusAnnouncement announcement) {
    setState(() {
      _announcements.insert(0, announcement);
    });
  }

  void _approveAnnouncement(String id) {
    setState(() {
      final index = _announcements.indexWhere((a) => a.id == id);
      if (index != -1) {
        final old = _announcements[index];
        _announcements[index] = CampusAnnouncement(
          id: old.id,
          title: old.title,
          description: old.description,
          orgId: old.orgId,
          orgName: old.orgName,
          targetAudience: old.targetAudience,
          venue: old.venue,
          dateTime: old.dateTime,
          bannerCategory: old.bannerCategory,
          isEvent: old.isEvent,
          isOrientation: old.isOrientation,
          isApproved: true,
          approvalStatus: 'Cleared by Mother Org',
          surveyQuestions: old.surveyQuestions,
          attendeesCount: old.attendeesCount,
          averageRating: old.averageRating,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF7A0C16);
    const goldColor = Color(0xFFD4AF37);

    return MaterialApp(
      title: 'TCU: GATHER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: maroonColor,
          primary: maroonColor,
          secondary: goldColor,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: maroonColor,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: _currentUser == null
          ? LoginScreen(
              users: _users,
              onLogin: _login,
              onRegister: (newUser) {
                setState(() {
                  _users.add(newUser);
                  _currentUser = newUser;
                });
              },
            )
          : MainAppShell(
              user: _currentUser!,
              announcements: _announcements,
              checkedInEventIds: _checkedInEventIds,
              completedSurveyEventIds: _completedSurveyEventIds,
              onLogout: _logout,
              onVerifyUser: _verifyCurrentUser,
              onAddAnnouncement: _addAnnouncement,
              onApproveAnnouncement: _approveAnnouncement,
              onCheckIn: (eventId) {
                setState(() {
                  _checkedInEventIds.add(eventId);
                });
              },
              onCompleteSurvey: (eventId) {
                setState(() {
                  _completedSurveyEventIds.add(eventId);
                });
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// 1. AUTHENTICATION SCREEN (LOGIN WITH SHORTCUTS OR PASS 123)
// -------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  final List<UserAccount> users;
  final ValueChanged<UserAccount> onLogin;
  final ValueChanged<UserAccount> onRegister;

  const LoginScreen({
    super.key,
    required this.users,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController(text: '123');
  bool _isRegistering = false;

  final _regNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _regPasswordController = TextEditingController(text: '123');
  String _regCollege = 'CICT';

  void _submitLogin() {
    final input = _usernameController.text.trim().toLowerCase();
    final pass = _passwordController.text.trim();

    final user = widget.users.firstWhere(
      (u) =>
          (u.username.toLowerCase() == input ||
              u.studentNumber.toLowerCase() == input) &&
          u.password == pass,
      orElse: () => UserAccount(
        username: '',
        studentNumber: '',
        password: '',
        fullName: '',
        college: '',
        isVerified: false,
        orgMemberships: [],
      ),
    );

    if (user.username.isNotEmpty) {
      widget.onLogin(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials! Try: unverified, cba, cict, cet, or ssc (Password: 123)'),
          backgroundColor: Color(0xFF7A0C16),
        ),
      );
    }
  }

  void _submitRegister() {
    final name = _regNameController.text.trim();
    final num = _regNumberController.text.trim();
    final pass = _regPasswordController.text.trim();

    if (name.isEmpty || num.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all registration fields.')),
      );
      return;
    }

    final newUser = UserAccount(
      username: num.toLowerCase(),
      studentNumber: num,
      password: pass,
      fullName: name,
      college: _regCollege,
      isVerified: false, // UNVERIFIED: Must attend orientation
      orgMemberships: [],
    );

    widget.onRegister(newUser);
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF7A0C16);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TCU Maroon Seal Badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: maroonColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: maroonColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text(
                  'TCU: GATHER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: maroonColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Taguig City University • Campus Attendance & Hub',
                  style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 22),

                // Form Container
                Card(
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _isRegistering ? _buildRegisterForm() : _buildLoginForm(),
                  ),
                ),
                const SizedBox(height: 18),

                // 1-TAP DEMO SHORTCUT BUTTONS
                if (!_isRegistering) ...[
                  const Text(
                    '1-Tap Role Selector (Password: 123):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: maroonColor),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickChip('unverified', 'Freshman (Unverified)', Icons.person_outline, Colors.red.shade800),
                      _buildQuickChip('cba', 'CBA Student', Icons.business, maroonColor),
                      _buildQuickChip('cict', 'CICT (Multi-Org Officer)', Icons.developer_mode, maroonColor),
                      _buildQuickChip('cet', 'CET Officer', Icons.engineering, maroonColor),
                      _buildQuickChip('ssc', 'SSC Mother Org President', Icons.military_tech, goldColor, textColor: Colors.black87),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String username, String label, IconData icon, Color color, {Color textColor = Colors.white}) {
    final user = widget.users.firstWhere((u) => u.username == username);
    return ActionChip(
      elevation: 1,
      backgroundColor: color,
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
      onPressed: () {
        _usernameController.text = username;
        widget.onLogin(user);
      },
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Student / Officer Sign In',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0C16)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use shortcut (unverified, cba, cict, cet, ssc) or student number.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username or Student Number',
            hintText: 'e.g. cict, cba, or 2024-10842-TG-0',
            prefixIcon: Icon(Icons.person, color: Color(0xFF7A0C16)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: '123',
            prefixIcon: Icon(Icons.lock, color: Color(0xFF7A0C16)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A0C16),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submitLogin,
          child: const Text('Log In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _isRegistering = true),
          child: const Text(
            "New Student? Register here",
            style: TextStyle(color: Color(0xFF7A0C16), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Student Registration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7A0C16)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD4AF37)),
          ),
          child: const Text(
            'Notice: New accounts are tagged Unverified. You must attend the TCU Student Orientation to unlock your department access.',
            style: TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regNameController,
          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _regNumberController,
          decoration: const InputDecoration(
            labelText: 'Student Number (also your username)',
            hintText: 'e.g. 2026-88888-TG-0',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _regCollege,
          decoration: const InputDecoration(labelText: 'College Department', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'CICT', child: Text('CICT (Computer Studies)')),
            DropdownMenuItem(value: 'CBA', child: Text('CBA (Business Administration)')),
            DropdownMenuItem(value: 'CET', child: Text('CET (Engineering & Tech)')),
            DropdownMenuItem(value: 'CAS', child: Text('CAS (Arts & Sciences)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _regCollege = val);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _regPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A0C16),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _submitRegister,
          child: const Text('Create Unverified Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => setState(() => _isRegistering = false),
          child: const Text('Back to Sign In', style: TextStyle(color: Color(0xFF7A0C16))),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 2. MAIN APPLICATION SHELL (3 NAV TABS + APPBAR NOTIFICATIONS)
// -------------------------------------------------------------

class MainAppShell extends StatefulWidget {
  final UserAccount user;
  final List<CampusAnnouncement> announcements;
  final Set<String> checkedInEventIds;
  final Set<String> completedSurveyEventIds;
  final VoidCallback onLogout;
  final VoidCallback onVerifyUser;
  final ValueChanged<CampusAnnouncement> onAddAnnouncement;
  final ValueChanged<String> onApproveAnnouncement;
  final ValueChanged<String> onCheckIn;
  final ValueChanged<String> onCompleteSurvey;

  const MainAppShell({
    super.key,
    required this.user,
    required this.announcements,
    required this.checkedInEventIds,
    required this.completedSurveyEventIds,
    required this.onLogout,
    required this.onVerifyUser,
    required this.onAddAnnouncement,
    required this.onApproveAnnouncement,
    required this.onCheckIn,
    required this.onCompleteSurvey,
  });

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _navIndex = 0; // STRICTLY 3 TABS: 0: Home Feed, 1: QR Scanner, 2: More/Account
  String _selectedCollegeFilter = 'All';
  bool _notificationPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptNotificationPermission();
    });
  }

  // System notification permission dialog on initial open
  void _promptNotificationPermission() {
    if (_notificationPromptShown) return;
    _notificationPromptShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF7A0C16), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Allow Notifications?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A0C16)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Allow TCU: GATHER to send you notifications?\n\nReceive instant alerts for official college announcements, class clearance schedules, and urgent event updates.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Don\'t Allow', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A0C16),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications enabled! You will receive official campus notices.'),
                  backgroundColor: Color(0xFF7A0C16),
                ),
              );
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  // Get pending surveys list (attended events without submitted evaluation)
  List<CampusAnnouncement> _getPendingEvaluations() {
    return widget.announcements.where((a) {
      return widget.checkedInEventIds.contains(a.id) &&
          !widget.completedSurveyEventIds.contains(a.id);
    }).toList();
  }

  // Get upcoming events list matching user's college or university-wide
  List<CampusAnnouncement> _getUpcomingEvents() {
    return widget.announcements.where((a) {
      if (!a.isApproved) return false;
      if (widget.user.college == 'University-Wide') return true;
      return a.targetAudience == 'All' || a.targetAudience == widget.user.college;
    }).toList();
  }

  // Open Google Forms Survey Screen
  void _openGoogleFormsSurvey(CampusAnnouncement ann) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoogleFormsSurveyScreen(
          user: widget.user,
          announcement: ann,
          onComplete: () {
            widget.onCompleteSurvey(ann.id);
          },
        ),
      ),
    );
  }

  // Open Notification Center Bottom Sheet
  void _openNotificationCenter() {
    const maroonColor = Color(0xFF7A0C16);
    const goldColor = Color(0xFFD4AF37);
    final pendingEvals = _getPendingEvaluations();
    final upcomingEvents = _getUpcomingEvents();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: maroonColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: maroonColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications & Alerts',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                      Text(
                        'Campus Updates & Evaluation Forms',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // SECTION 1: PENDING EVALUATIONS (ACTION REQUIRED)
                  Row(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 18, color: maroonColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Action Required: Event Evaluations',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                      const Spacer(),
                      if (pendingEvals.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: goldColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingEvals.length} Due',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: maroonColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (pendingEvals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have no pending evaluations! All attended events have been surveyed and cleared.',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingEvals.map((ann) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: goldColor, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB78103), size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Attendance Recorded: ${ann.title}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7A0C16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You checked in to this event hosted by ${ann.orgName}. Complete the evaluation survey to finalize your attendance certificate and student clearance.',
                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: maroonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _openGoogleFormsSurvey(ann);
                                  },
                                  icon: const Icon(Icons.assignment, size: 16),
                                  label: const Text(
                                    'Fill Out Evaluation Survey (Google Form)',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),

                  // SECTION 2: UPCOMING CAMPUS EVENTS
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 18, color: maroonColor),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Events for ${widget.user.college} & TCU',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (upcomingEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No upcoming events scheduled right now.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    ...upcomingEvents.map((ann) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: maroonColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign, color: maroonColor, size: 20),
                            ),
                            title: Text(
                              ann.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text(
                                  '${ann.orgName} • ${ann.dateTime}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Venue: ${ann.venue}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openFullEventDetails(ann);
                            },
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF7A0C16);
    final pendingEvals = _getPendingEvaluations();

    final screens = [
      _buildHomeNewsfeedTab(),
      _buildQrScannerTab(),
      _buildMoreAccountTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school, color: maroonColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TCU: GATHER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  widget.user.isVerified
                      ? '${widget.user.college} Department'
                      : 'Unverified Student',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // REPLACED LOGOUT WITH NOTIFICATION BELL (LOGOUT IS IN MORE/ACCOUNT)
          IconButton(
            tooltip: 'Campus Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                if (pendingEvals.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${pendingEvals.length}',
                        style: const TextStyle(
                          color: maroonColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openNotificationCenter,
          ),
        ],
      ),
      body: screens[_navIndex],
      // STRICTLY 3 BOTTOM NAVIGATION BUTTONS
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        indicatorColor: maroonColor.withValues(alpha: 0.15),
        onDestinationSelected: (idx) => setState(() => _navIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper, color: maroonColor),
            label: 'Home Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: maroonColor),
            label: 'QR Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle, color: maroonColor),
            label: 'More / Account',
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TAB 1: HOME / NEWSFEED
  // -----------------------------------------------------------

  Widget _buildHomeNewsfeedTab() {
    const maroonColor = Color(0xFF7A0C16);

    // Filter logic:
    // If user is UNVERIFIED, they can ONLY see the TCU Orientation event!
    final visibleAnnouncements = widget.announcements.where((a) {
      if (!widget.user.isVerified) {
        return a.isOrientation; // ONLY ORIENTATION VISIBLE
      }
      if (!a.isApproved && !widget.user.isSscAdmin) {
        return false;
      }
      if (_selectedCollegeFilter == 'All') return true;
      return a.targetAudience == 'All' || a.targetAudience == _selectedCollegeFilter;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UNVERIFIED WARNING BANNER
          if (!widget.user.isVerified) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: maroonColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: maroonColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: maroonColor, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Account Status: UNVERIFIED',
                        style: TextStyle(
                          color: maroonColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${widget.user.fullName}! To verify your account, you must attend the TCU Student Orientation. Your ${widget.user.college} department feed and university announcements are locked until you check in.',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => _navIndex = 1), // Go to Scanner
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Scan Orientation QR to Verify'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Verified User: College Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'CICT', 'CBA', 'CET', 'CAS'].map((col) {
                  final isSel = _selectedCollegeFilter == col;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(col == 'All' ? 'All Campuses' : col),
                      selected: isSel,
                      selectedColor: maroonColor,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCollegeFilter = col),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            !widget.user.isVerified
                ? 'Mandatory Orientation Event'
                : 'Verified Campus Announcements',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: maroonColor),
          ),
          const SizedBox(height: 12),

          if (visibleAnnouncements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No announcements found for this filter.'),
              ),
            ),

          ...visibleAnnouncements.map((ann) => _buildAnnouncementCard(ann)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ANNOUNCEMENT CARD (ORDER: POSTER -> IMAGE -> TITLE -> DATE/TIME/VENUE)
  // Clicking the card opens modal about that event with full information.
  // ----------------------------------------------------------------------
  Widget _buildAnnouncementCard(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);
    final isCheckedIn = widget.checkedInEventIds.contains(ann.id);
    final isSurveyDone = widget.completedSurveyEventIds.contains(ann.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openFullEventDetails(ann),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. POSTER (ORG NAME NOT ACCOUNT)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: maroonColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.school, color: maroonColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ann.orgName, // Poster = Org Name (NOT account)
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ann.isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: ann.isApproved ? Colors.green.shade600 : Colors.orange.shade600,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                ann.approvalStatus,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: ann.isApproved ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Target: ${ann.targetAudience}',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCheckedIn && isSurveyDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 12),
                          SizedBox(width: 3),
                          Text('Cleared', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (isCheckedIn && !isSurveyDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review, color: Color(0xFF856404), size: 12),
                          SizedBox(width: 3),
                          Text('Survey Due', style: TextStyle(color: Color(0xFF856404), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 2. IMAGE (IF THERE IS AN IMAGE THEN THAT)
            _buildEventBannerImage(ann),

            // 3. TITLE OF ANNOUNCEMENT OR EVENT
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(
                ann.title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: Color(0xFF212121),
                ),
              ),
            ),

            // 4. TIME, DATE, AND LOCATION
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 15, color: maroonColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ann.dateTime,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: maroonColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ann.venue,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // CLICKING OPENS MODAL FOOTER HINT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view event description & clearance details',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual Graphic Banner for each Event / Announcement
  Widget _buildEventBannerImage(CampusAnnouncement ann) {
    List<Color> gradientColors;
    IconData bannerIcon;
    String tagLabel;

    switch (ann.bannerCategory) {
      case 'orientation':
        gradientColors = const [Color(0xFF7A0C16), Color(0xFF380308)];
        bannerIcon = Icons.school_rounded;
        tagLabel = 'TCU MANDATORY ORIENTATION';
        break;
      case 'tech':
        gradientColors = const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)];
        bannerIcon = Icons.terminal_rounded;
        tagLabel = 'CICT TECH INNOVATION';
        break;
      case 'business':
        gradientColors = const [Color(0xFF0D324D), Color(0xFF7F5A83)];
        bannerIcon = Icons.trending_up_rounded;
        tagLabel = 'CBA BUSINESS & ENTREPRENEURSHIP';
        break;
      case 'assembly':
        gradientColors = const [Color(0xFF141E30), Color(0xFF243B55)];
        bannerIcon = Icons.account_balance_rounded;
        tagLabel = 'TCU STUDENT WELFARE ASSEMBLY';
        break;
      case 'workshop':
      default:
        gradientColors = const [Color(0xFF232526), Color(0xFF414345)];
        bannerIcon = Icons.security_rounded;
        tagLabel = 'TECHNICAL WORKSHOP';
        break;
    }

    return Container(
      height: 145,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background subtle pattern watermark
          Positioned(
            right: -15,
            bottom: -20,
            child: Icon(
              bannerIcon,
              size: 150,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top tag badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tagLabel,
                    style: const TextStyle(
                      color: Color(0xFF7A0C16),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Center Title Graphic Banner
                Row(
                  children: [
                    Icon(bannerIcon, color: const Color(0xFFD4AF37), size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ann.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Bottom official stamp
                const Text(
                  'Taguig City University • Official Student Notice',
                  style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DEDICATED FULL EVENT DETAILS SHEET (OPENED ON CARD CLICK) ---
  void _openFullEventDetails(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);
    final isCheckedIn = widget.checkedInEventIds.contains(ann.id);
    final isSurveyDone = widget.completedSurveyEventIds.contains(ann.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Organization & Approval Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: maroonColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: maroonColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ann.orgName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ann.approvalStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: ann.isApproved ? Colors.green.shade700 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: maroonColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: maroonColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Target: ${ann.targetAudience}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  ann.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: maroonColor),
                ),
                const SizedBox(height: 16),

                // Logistics Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: maroonColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Venue: ${ann.venue}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: maroonColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Schedule: ${ann.dateTime}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Full Event Description / Brief
                const Text('Event Overview & Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  ann.description,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 20),

                // Stats / Info
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expected Attendees', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${ann.attendeesCount} Students', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Satisfaction Score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                                Text(' ${ann.averageRating} / 5.0', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action button inside modal
                if (ann.isEvent) ...[
                  if (!isCheckedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _navIndex = 1);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(
                          ann.isOrientation ? 'Check In at Orientation' : 'Open QR Scanner at Venue',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else if (!isSurveyDone) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openGoogleFormsSurvey(ann);
                        },
                        icon: const Icon(Icons.assignment),
                        label: const Text('Open Google Form Evaluation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade600),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Attendance & Evaluation Verified!',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Mother Org clearance button for SSC Admin
                if (!ann.isApproved && widget.user.isSscAdmin) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        widget.onApproveAnnouncement(ann.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cleared by Mother Org: ${ann.title}')),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mother Org (SSC): Approve & Clear Notice'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // TAB 2: QR SCANNER (CHECK-IN)
  // -----------------------------------------------------------

  Widget _buildQrScannerTab() {
    const maroonColor = Color(0xFF7A0C16);
    const goldColor = Color(0xFFD4AF37);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: maroonColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: maroonColor.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: maroonColor, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Point camera at the organizer QR code displayed at the entrance venue.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      if (capture.barcodes.isNotEmpty) {
                        _handleScanSuccess();
                      }
                    },
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: goldColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align QR code inside box',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: maroonColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _handleScanSuccess,
              icon: const Icon(Icons.flash_on, color: maroonColor),
              label: const Text(
                'Simulate QR Check-In (Presentation Demo)',
                style: TextStyle(fontWeight: FontWeight.bold, color: maroonColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScanSuccess() {
    const maroonColor = Color(0xFF7A0C16);

    if (!widget.user.isVerified) {
      widget.onCheckIn('ev-orientation');
      widget.onVerifyUser();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 8),
              Text('Account Verified!'),
            ],
          ),
          content: Text(
            'Congratulations, ${widget.user.fullName}!\n\nYou have attended the TCU Student Orientation. Your account is now fully verified. Access to your ${widget.user.college} department and campus announcements has been unlocked!\n\nNote: A post-orientation evaluation form is now ready in your Notifications.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _navIndex = 0);
              },
              child: const Text('Go to Campus Newsfeed'),
            ),
          ],
        ),
      );
    } else {
      widget.onCheckIn('ev-tech-summit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance Recorded! Evaluation unlocked in Notifications bell.'),
          backgroundColor: maroonColor,
        ),
      );
      setState(() => _navIndex = 0);
    }
  }

  // -----------------------------------------------------------
  // TAB 3: MORE / ACCOUNT & OFFICER WORKSPACE
  // -----------------------------------------------------------

  Widget _buildMoreAccountTab() {
    const maroonColor = Color(0xFF7A0C16);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    child: Text(
                      widget.user.fullName[0],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'ID: ${widget.user.studentNumber} • Username: ${widget.user.username}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'Department: ${widget.user.college}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.user.isVerified ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: widget.user.isVerified ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            widget.user.isVerified ? 'Verified Student' : 'Unverified (Orientation Required)',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.user.isVerified ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- OFFICER / ADMIN MULTI-ORGANIZATION WORKSPACE ---
          if (widget.user.hasAnyOfficerRole) ...[
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: maroonColor, size: 20),
                SizedBox(width: 6),
                Text(
                  'My Organizations & Officer Workspace',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: maroonColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your account has administrative officer privileges in ${widget.user.orgMemberships.where((m) => m.role != 'Member').length} organization(s):',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),

            ...widget.user.orgMemberships
                .where((m) => m.role != 'Member')
                .map((m) => _buildOrgCard(m)),
            const SizedBox(height: 20),
          ],

          const Text('Account & System Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: maroonColor),
                  title: const Text('Department Notice Alerts', style: TextStyle(fontSize: 13)),
                  trailing: Switch(value: true, activeThumbColor: maroonColor, onChanged: (_) {}),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: maroonColor),
                  title: const Text('About TCU: GATHER', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('v1.0 • Taguig City University', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'TCU: GATHER',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'General Attendance, Tracking, and Hub for Event Reporting',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgCard(OrgMembership m) {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: maroonColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.groups, color: maroonColor),
        ),
        title: Text(m.orgName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('Affiliation: ${m.collegeAffiliation} • Role: ${m.role}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          onPressed: () => _openOrgWorkspace(m),
          child: const Text('Open Hub', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  void _openOrgWorkspace(OrgMembership m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrgWorkspaceScreen(
          user: widget.user,
          org: m,
          announcements: widget.announcements.where((a) => a.orgId == m.orgId).toList(),
          onAddAnnouncement: widget.onAddAnnouncement,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. GOOGLE FORMS EVALUATION SCREEN (AUTHENTIC GFORM STYLING)
// -------------------------------------------------------------

class GoogleFormsSurveyScreen extends StatefulWidget {
  final UserAccount user;
  final CampusAnnouncement announcement;
  final VoidCallback onComplete;

  const GoogleFormsSurveyScreen({
    super.key,
    required this.user,
    required this.announcement,
    required this.onComplete,
  });

  @override
  State<GoogleFormsSurveyScreen> createState() => _GoogleFormsSurveyScreenState();
}

class _GoogleFormsSurveyScreenState extends State<GoogleFormsSurveyScreen> {
  int _overallRating = 5; // 1 to 5 linear scale
  String _relevanceChoice = 'Highly Relevant & Informative';
  String _organizationChoice = 'Exceeded Expectations';
  final _commentController = TextEditingController();
  bool _submitted = false;

  void _submitForm() {
    setState(() {
      _submitted = true;
    });
    widget.onComplete();
  }

  void _clearForm() {
    setState(() {
      _overallRating = 5;
      _relevanceChoice = 'Highly Relevant & Informative';
      _organizationChoice = 'Exceeded Expectations';
      _commentController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gformHeaderPurple = Color(0xFF673AB7);
    const gformBg = Color(0xFFEDE7F6);

    return Scaffold(
      backgroundColor: gformBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: gformHeaderPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.assignment, color: gformHeaderPurple, size: 20),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Google Forms',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _submitted ? _buildConfirmationCard() : _buildFormContent(),
          ),
        ),
      ),
    );
  }

  // Post-submission Google Form Confirmation
  Widget _buildConfirmationCard() {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent strip
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: maroonColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.announcement.title} - Post-Event Evaluation',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your response has been recorded.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attendance clearance credit has been automatically verified on your TCU Student Profile.',
                  style: TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => setState(() => _submitted = false),
                  child: const Text(
                    'Submit another response',
                    style: TextStyle(fontSize: 13, color: Color(0xFF1A73E8), decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Return to TCU: GATHER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Active Google Form Questions
  Widget _buildFormContent() {
    const maroonColor = Color(0xFF7A0C16);
    const requiredRed = Color(0xFFD93025);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. GFORM HEADER CARD
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top colored accent bar
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: maroonColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taguig City University',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.announcement.title} - Post-Event Evaluation',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Official Event Feedback & Attendance Verification Form.\nOrganized by: ${widget.announcement.orgName}\nVenue: ${widget.announcement.venue}\n\nYour candid evaluation helps our student council measure program impact and fulfills your student clearance requirement.',
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                    ),
                    const Divider(height: 24),
                    // Authenticated Account Strip
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 20, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.user.studentNumber.toLowerCase().replaceAll('-', '')}@tcu.edu.ph',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          'Switch account',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1A73E8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Draft saved', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '* Indicates required question',
                      style: TextStyle(color: requiredRed, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. QUESTION 1: LINEAR SCALE (1 to 5)
        _buildQuestionCard(
          title: '1. Overall satisfaction with this event *',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text('Poor', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                    ...List.generate(5, (index) {
                      final val = index + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          children: [
                            Text('$val', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Radio<int>(
                              value: val,
                              groupValue: _overallRating,
                              activeColor: maroonColor,
                              onChanged: (v) {
                                if (v != null) setState(() => _overallRating = v);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Excellent', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. QUESTION 2: MULTIPLE CHOICE (RELEVANCE)
        _buildQuestionCard(
          title: '2. Relevance and academic value of the topic presented *',
          child: Column(
            children: [
              'Highly Relevant & Informative',
              'Moderately Relevant',
              'Slightly Relevant',
              'Not Relevant',
            ].map((option) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option, style: const TextStyle(fontSize: 13)),
                value: option,
                groupValue: _relevanceChoice,
                activeColor: maroonColor,
                onChanged: (val) {
                  if (val != null) setState(() => _relevanceChoice = val);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // 4. QUESTION 3: MULTIPLE CHOICE (ORGANIZATION & VENUE)
        _buildQuestionCard(
          title: '3. Organization, registration flow, and venue accommodation *',
          child: Column(
            children: [
              'Exceeded Expectations',
              'Met Expectations',
              'Needs Improvement',
            ].map((option) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option, style: const TextStyle(fontSize: 13)),
                value: option,
                groupValue: _organizationChoice,
                activeColor: maroonColor,
                onChanged: (val) {
                  if (val != null) setState(() => _organizationChoice = val);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // 5. QUESTION 4: PARAGRAPH TEXT ("Your answer")
        _buildQuestionCard(
          title: '4. Suggestions, feedback, or topics you want to request for future events',
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Your answer',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: maroonColor, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 6. GFORM BUTTONS ROW
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: _submitForm,
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            TextButton(
              onPressed: _clearForm,
              child: const Text('Clear form', style: TextStyle(color: Color(0xFF1A73E8), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 7. GFORM DISCLAIMER & FOOTER
        const Center(
          child: Column(
            children: [
              Text(
                'Never submit passwords through Google Forms.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              SizedBox(height: 4),
              Text(
                'This form was created inside Taguig City University.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Google Forms',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. ORGANIZATION WORKSPACE (OFFICER SCREEN)
// -------------------------------------------------------------

class OrgWorkspaceScreen extends StatefulWidget {
  final UserAccount user;
  final OrgMembership org;
  final List<CampusAnnouncement> announcements;
  final ValueChanged<CampusAnnouncement> onAddAnnouncement;

  const OrgWorkspaceScreen({
    super.key,
    required this.user,
    required this.org,
    required this.announcements,
    required this.onAddAnnouncement,
  });

  @override
  State<OrgWorkspaceScreen> createState() => _OrgWorkspaceScreenState();
}

class _OrgWorkspaceScreenState extends State<OrgWorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF7A0C16);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.org.orgName, style: const TextStyle(fontSize: 15)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroonColor,
        foregroundColor: Colors.white,
        onPressed: _openCreateAnnouncementDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Event Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: goldColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: maroonColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Role: ${widget.org.role} • ${widget.org.orgId == 'ssc' ? 'University-Wide Authority' : '${widget.org.collegeAffiliation} Authority'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Event History & Live Evaluation Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: maroonColor)),
            const SizedBox(height: 10),

            if (widget.announcements.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No events published yet for this organization.'),
              ),

            ...widget.announcements.map((ann) => _buildOfficerEventCard(ann)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerEventCard(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ann.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ann.isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ann.isApproved ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    ann.isApproved ? 'Approved' : 'Pending Clearance',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ann.isApproved ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${ann.dateTime} • ${ann.venue}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${ann.attendeesCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: maroonColor)),
                    const Text('Total Attendees', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                        Text(' ${ann.averageRating}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Text('Survey Score', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (ann.isApproved) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: maroonColor),
                  ),
                  onPressed: () => _showDownloadQrDialog(ann),
                  icon: const Icon(Icons.qr_code, size: 16, color: maroonColor),
                  label: const Text('Download / Print Event QR', style: TextStyle(fontSize: 12, color: maroonColor)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDownloadQrDialog(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Official Event QR Code\n${ann.title}', style: const TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 8),
                ],
              ),
              child: QrImageView(
                data: 'TCU-GATHER-OFFICIAL-QR-${ann.id}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Generated specifically for this approved event.\nPrint or display this at entrance door registration.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved QR Code Image to device storage!')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Save / Print QR'),
          ),
        ],
      ),
    );
  }

  void _openCreateAnnouncementDialog() {
    const maroonColor = Color(0xFF7A0C16);

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final surveyCtrl = TextEditingController();
    String target = widget.org.orgId == 'ssc' ? 'All' : widget.org.collegeAffiliation;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Event & Survey Form', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Event Brief')),
              const SizedBox(height: 8),
              TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue (e.g. Auditorium)')),
              const SizedBox(height: 8),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date & Time')),
              const SizedBox(height: 8),
              TextField(
                controller: surveyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Evaluation Survey Question',
                  hintText: 'e.g. Rate the speaker delivery',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Target Audience: $target (Restricted to your authority)',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (titleCtrl.text.isEmpty) return;
              final newAnn = CampusAnnouncement(
                id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                orgId: widget.org.orgId,
                orgName: widget.org.orgName,
                targetAudience: target,
                venue: venueCtrl.text.trim(),
                dateTime: dateCtrl.text.trim(),
                bannerCategory: 'tech',
                isApproved: widget.org.orgId == 'ssc',
                approvalStatus: widget.org.orgId == 'ssc'
                    ? 'Cleared by Mother Org'
                    : 'Pending Mother Org Clearance',
                surveyQuestions: [surveyCtrl.text.trim()],
              );
              widget.onAddAnnouncement(newAnn);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.org.orgId == 'ssc'
                      ? 'Event Published & QR Generated!'
                      : 'Event Submitted for SSC Clearance!'),
                ),
              );
            },
            child: const Text('Submit for Approval'),
          ),
        ],
      ),
    );
  }
}
