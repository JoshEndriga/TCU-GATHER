import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const TcuGatherApp());
}

// Global one-time notification flag (persists across account switches)
bool _hasRequestedNotificationPermission = false;

// -------------------------------------------------------------
// MODELS
// -------------------------------------------------------------

class UserAccount {
  final String username; // 'unverified', 'cba', 'cict', 'cet', 'ssc'
  final String studentNumber;
  String password;
  String fullName;
  String college; // 'CICT', 'CBA', 'CET', 'CAS', 'University-Wide'
  bool isVerified; // True if attended TCU Orientation AND orientation has ended
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
  final String orgName; // POSTER (ORGANIZATION NAME ONLY)
  final String targetAudience; // 'All', 'CICT', 'CBA', 'CET', 'CAS'
  final String venue;
  final String dateTime;
  final String bannerCategory; // 'orientation', 'tech', 'business', 'assembly', 'workshop'
  final bool isEvent; // True = Event Announcement, False = Normal Announcement
  final bool isOrientation;
  bool isEnded; // True if the event has concluded (Verification requirement!)
  bool isApproved;
  final String approvalStatus;
  List<String> surveyQuestions;
  int attendeesCount;
  double averageRating;
  List<String> attendeeFeedbackList;

  CampusAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.orgId,
    required this.orgName,
    required this.targetAudience,
    this.venue = '',
    this.dateTime = '',
    this.bannerCategory = 'tech',
    this.isEvent = true,
    this.isOrientation = false,
    this.isEnded = false,
    this.isApproved = true,
    this.approvalStatus = 'Cleared by Mother Org',
    this.surveyQuestions = const [],
    this.attendeesCount = 0,
    this.averageRating = 5.0,
    this.attendeeFeedbackList = const [],
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
    _users = [
      // 1. Unverified Freshman (CICT)
      UserAccount(
        username: 'unverified',
        studentNumber: '2026-00001-TG-0',
        password: '123',
        fullName: 'Paul Samuel Del Valle',
        college: 'CICT',
        isVerified: false,
        orgMemberships: [],
      ),

      // 2. Verified Student from CBA
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

      // 3. Multi-Org Officer (CICT + SSC + GDSC)
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

      // 4. CET Engineering Officer
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

      // 5. SSC Mother Org President
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

    // Seeded check-in: Tech Summit check-in recorded for verified demo accounts
    _checkedInEventIds.add('ev-tech-summit');

    _announcements = [
      CampusAnnouncement(
        id: 'ev-orientation',
        title: 'TCU Grand Student Orientation 2026',
        description:
            'Mandatory university orientation for new freshmen and transferees. Students must check in at the venue. Your account is officially verified once the orientation event concludes.',
        orgId: 'ssc',
        orgName: 'Supreme Student Council (Mother Org)',
        targetAudience: 'All',
        venue: 'TCU Main Auditorium',
        dateTime: 'November 10, 2026 | 8:30 AM',
        bannerCategory: 'orientation',
        isEvent: true,
        isOrientation: true,
        isEnded: false, // Starts as ongoing/upcoming
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: [
          'How clear were the university campus guidelines?',
          'How helpful was the tour of college departments?',
        ],
        attendeesCount: 320,
        averageRating: 4.9,
        attendeeFeedbackList: [
          'The campus orientation was very clear and informative!',
          'Glad to learn about our department facilities and student services.',
          'Sound system in the balcony could be louder, but overall great experience.',
        ],
      ),
      CampusAnnouncement(
        id: 'ev-tech-summit',
        title: 'CICT Tech Summit & Coding Fair',
        description:
            'Annual innovation and software exhibition organized by CICT. Open to all Computer Science and IT majors, featuring expert keynotes, software demos, and project competitions.',
        orgId: 'cict_sc',
        orgName: 'Computer Studies Student Council (CICT)',
        targetAudience: 'CICT',
        venue: 'Main AVR (4th Floor)',
        dateTime: 'November 14, 2026 | 9:00 AM – 3:00 PM',
        bannerCategory: 'tech',
        isEvent: true,
        isEnded: true, // Ended event (Ready for Evaluation survey in Notifications!)
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: [
          'Rate the technical depth of the masterclass',
          'Were the hands-on project demos useful?',
        ],
        attendeesCount: 142,
        averageRating: 4.8,
        attendeeFeedbackList: [
          'Great industry speakers and live Flutter code walk-throughs!',
          'Hope there are more workshops on AI integration next semester.',
          'Well organized registration and badge system.',
        ],
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
        isEnded: false,
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
        surveyQuestions: ['Was the financial modeling seminar helpful?'],
        attendeesCount: 98,
        averageRating: 4.9,
        attendeeFeedbackList: [
          'Very relevant insights for young business majors.',
        ],
      ),
      CampusAnnouncement(
        id: 'ann-general-advisory',
        title: 'Midterm Campus Clearance Advisory',
        description:
            'General advisory from the Supreme Student Council. All student organizations and class representatives must submit mid-term activity reports prior to the clearance window.',
        orgId: 'ssc',
        orgName: 'Supreme Student Council (Mother Org)',
        targetAudience: 'All',
        venue: '',
        dateTime: '',
        bannerCategory: 'assembly',
        isEvent: false, // Normal Announcement!
        isApproved: true,
        approvalStatus: 'Cleared by Mother Org',
      ),
      CampusAnnouncement(
        id: 'ev-cyber-workshop',
        title: 'CICT Cyber Security & Ethical Hacking Workshop',
        description:
            'Hands-on network defense, penetration testing, and vulnerability auditing workshop for CICT students.',
        orgId: 'cict_sc',
        orgName: 'Computer Studies Student Council (CICT)',
        targetAudience: 'CICT',
        venue: 'Computer Lab 3',
        dateTime: 'November 22, 2026 | 10:00 AM',
        bannerCategory: 'workshop',
        isEvent: true,
        isEnded: false,
        isApproved: false, // PENDING Mother Org clearance!
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

  void _endEvent(String eventId) {
    setState(() {
      final idx = _announcements.indexWhere((a) => a.id == eventId);
      if (idx != -1) {
        _announcements[idx].isEnded = true;
        // If this was orientation, verify any user who attended!
        if (_announcements[idx].isOrientation &&
            _checkedInEventIds.contains(eventId) &&
            _currentUser != null) {
          _currentUser!.isVerified = true;
        }
      }
    });
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
          isEnded: old.isEnded,
          isApproved: true,
          approvalStatus: 'Cleared by Mother Org',
          surveyQuestions: old.surveyQuestions,
          attendeesCount: old.attendeesCount,
          averageRating: old.averageRating,
          attendeeFeedbackList: old.attendeeFeedbackList,
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
              onEndEvent: _endEvent,
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
// 1. AUTHENTICATION SCREEN
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
      isVerified: false,
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
            'Notice: New accounts are tagged Unverified. You must attend the TCU Student Orientation and the event must conclude to unlock your department access.',
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
// 2. MAIN APPLICATION SHELL
// -------------------------------------------------------------

class MainAppShell extends StatefulWidget {
  final UserAccount user;
  final List<CampusAnnouncement> announcements;
  final Set<String> checkedInEventIds;
  final Set<String> completedSurveyEventIds;
  final VoidCallback onLogout;
  final VoidCallback onVerifyUser;
  final ValueChanged<String> onEndEvent;
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
    required this.onEndEvent,
    required this.onAddAnnouncement,
    required this.onApproveAnnouncement,
    required this.onCheckIn,
    required this.onCompleteSurvey,
  });

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _navIndex = 0; // 0: Home Feed, 1: QR Scanner, 2: More/Account
  late String _selectedCollegeFilter;

  @override
  void initState() {
    super.initState();
    // DEFAULT FILTER: Set to user's college department by default!
    _selectedCollegeFilter = widget.user.college == 'University-Wide'
        ? 'All'
        : widget.user.college;

    // Check one-time notification permission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRequestedNotificationPermission) {
        _hasRequestedNotificationPermission = true;
        _requestNativeNotificationPermission();
      }
    });
  }

  void _requestNativeNotificationPermission() {
    // Shows genuine one-time system notice (never repeated on account switch)
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
                'Allow Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7A0C16)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Allow TCU: GATHER to send you notifications on this device?\n\nYou will receive timely updates for upcoming college events, urgent student notices, and post-event survey clearances.',
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
                  content: Text('Notifications enabled for TCU: GATHER.'),
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

  // Pending evaluations: Attended events that have ENDED and haven't had survey submitted yet
  List<CampusAnnouncement> _getPendingEvaluations() {
    return widget.announcements.where((a) {
      return a.isEvent &&
          a.isEnded &&
          widget.checkedInEventIds.contains(a.id) &&
          !widget.completedSurveyEventIds.contains(a.id);
    }).toList();
  }

  // Upcoming events
  List<CampusAnnouncement> _getUpcomingEvents() {
    return widget.announcements.where((a) {
      if (!a.isApproved) return false;
      if (widget.user.college == 'University-Wide') return true;
      return a.targetAudience == 'All' || a.targetAudience == widget.user.college;
    }).toList();
  }

  void _openSurveyScreen(CampusAnnouncement ann) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationSurveyScreen(
          user: widget.user,
          announcement: ann,
          onComplete: () {
            widget.onCompleteSurvey(ann.id);
          },
        ),
      ),
    );
  }

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
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                        'Campus Notices & Evaluation Forms',
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // PENDING EVALUATIONS
                  Row(
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 18, color: maroonColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Evaluations (Action Required)',
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
                              'No pending evaluations! All attended events have been surveyed.',
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
                              Text(
                                'Pending Evaluation: ${ann.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7A0C16),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You checked in to this event. Please accomplish the evaluation form to credit your clearance.',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
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
                                    _openSurveyScreen(ann);
                                  },
                                  icon: const Icon(Icons.assignment, size: 16),
                                  label: const Text(
                                    'Open Evaluation Form',
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

                  // UPCOMING EVENTS
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
                            title: Text(
                              ann.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${ann.orgName}\n${ann.dateTime.isNotEmpty ? "${ann.dateTime} • " : ""}${ann.venue}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
    final orientationAnn = widget.announcements.firstWhere((a) => a.isOrientation);
    final hasCheckedInOrientation = widget.checkedInEventIds.contains(orientationAnn.id);

    // Filter logic:
    // 1. If unverified, ONLY orientation is visible.
    // 2. If verified: Filter matches user's department OR 'All'.
    // If an announcement was for whole student body ('All'), it ALSO shows up in user's department!
    final visibleAnnouncements = widget.announcements.where((a) {
      if (!widget.user.isVerified) {
        return a.isOrientation;
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
          // UNVERIFIED STATUS BANNER
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
                  if (!hasCheckedInOrientation) ...[
                    Text(
                      'Welcome, ${widget.user.fullName}! To verify your account, you must attend the TCU Student Orientation and check in with your QR code. (Your account will be verified once the orientation event concludes).',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _navIndex = 1),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Check In at Orientation (QR Scanner)'),
                    ),
                  ] else if (!orientationAnn.isEnded) ...[
                    Text(
                      'Attendance Recorded for TCU Student Orientation! Your account will be verified as soon as the orientation event concludes.',
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    // Quick Action to simulate orientation concluding for demo
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: maroonColor),
                      ),
                      onPressed: () {
                        widget.onEndEvent(orientationAnn.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Orientation has ended! Account is now Verified.')),
                        );
                      },
                      icon: const Icon(Icons.flag, size: 16, color: maroonColor),
                      label: const Text('Simulate Orientation Concluding', style: TextStyle(fontSize: 11.5, color: maroonColor)),
                    ),
                  ] else ...[
                    const Text(
                      'Orientation has ended! Your account is now verified.',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Department Filter Chips (Defaulted to user's college)
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

          if (visibleAnnouncements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No announcements found for this department filter.'),
              ),
            ),

          // Render cards: EXACT REQUESTED HIERARCHY ONLY
          ...visibleAnnouncements.map((ann) => _buildAnnouncementCard(ann)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ANNOUNCEMENT CARD: STRICT HIERARCHY ONLY
  // 1. Name of org that posted at the top
  // 2. Below that: The image
  // 3. Below that: Title of announcement/post
  // 4. Below that: Date and time
  // 5. Below that: Location
  // NO VISIBLE TAGS, NO APPROVAL PILLS, NO SURVEY BUTTONS!
  // ----------------------------------------------------------------------
  Widget _buildAnnouncementCard(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openFullEventDetails(ann),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. NAME OF ORG THAT POSTED THE ANNOUNCEMENT AT THE TOP
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Text(
                ann.orgName, // Poster (Organization Name ONLY)
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: maroonColor,
                ),
              ),
            ),

            // 2. BELOW THAT IS THE IMAGE (CLEAN BANNER, NO REDUNDANT TEXT/TAGS)
            _buildEventBannerImage(ann),

            // 3. BELOW THAT IS THE TITLE OF THE ANNOUNCEMENT/POST
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                ann.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // 4. BELOW THAT IS DATE AND TIME (IF APPLICABLE)
            if (ann.dateTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      ann.dateTime,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),

            // 5. BELOW THAT IS LOCATION (IF APPLICABLE)
            if (ann.venue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      ann.venue,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Clean Event Banner Image (No redundant text or tags)
  Widget _buildEventBannerImage(CampusAnnouncement ann) {
    List<Color> gradientColors;
    IconData visualIcon;

    switch (ann.bannerCategory) {
      case 'orientation':
        gradientColors = const [Color(0xFF7A0C16), Color(0xFF420409)];
        visualIcon = Icons.school;
        break;
      case 'tech':
        gradientColors = const [Color(0xFF0F2027), Color(0xFF2C5364)];
        visualIcon = Icons.terminal;
        break;
      case 'business':
        gradientColors = const [Color(0xFF0D324D), Color(0xFF7F5A83)];
        visualIcon = Icons.trending_up;
        break;
      case 'assembly':
        gradientColors = const [Color(0xFF141E30), Color(0xFF243B55)];
        visualIcon = Icons.account_balance;
        break;
      case 'workshop':
      default:
        gradientColors = const [Color(0xFF232526), Color(0xFF414345)];
        visualIcon = Icons.security;
        break;
    }

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          visualIcon,
          size: 58,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MODAL WHEN CARD IS CLICKED:
  // THE ONLY THING IN THE MODAL IS:
  // 1. Poster
  // 2. Title
  // 3. Image
  // 4. Date and Time
  // 5. Venue
  // 6. Description
  // NO OTHER STUFF! NO SURVEY BUTTON/LINK, NO TAGS!
  // ----------------------------------------------------------------------
  void _openFullEventDetails(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 1. POSTER (ORGANIZATION NAME ONLY)
                Text(
                  ann.orgName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: maroonColor),
                ),
                const SizedBox(height: 6),

                // 2. TITLE
                Text(
                  ann.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 3. IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildEventBannerImage(ann),
                ),
                const SizedBox(height: 14),

                // 4. DATE AND TIME
                if (ann.dateTime.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: maroonColor),
                      const SizedBox(width: 8),
                      Text(
                        ann.dateTime,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // 5. VENUE
                if (ann.venue.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: maroonColor),
                      const SizedBox(width: 8),
                      Text(
                        ann.venue,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // 6. DESCRIPTION
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  ann.description,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                ),
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
                    'Point camera at the official event QR code at the venue door.',
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Orientation Checked In!'),
            ],
          ),
          content: Text(
            'Attendance recorded for ${widget.user.fullName}!\n\nAs required by TCU policy, your account will become fully verified once the Student Orientation concludes.',
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
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } else {
      widget.onCheckIn('ev-tech-summit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance recorded! Post-event survey unlocked in Notifications.'),
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

            // Clicking whole card opens org hub directly!
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

  // Org card: Click container to open hub (NO "Open Hub" button!)
  Widget _buildOrgCard(OrgMembership m) {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOrgWorkspace(m), // Entire card is clickable to open Hub!
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: maroonColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups, color: maroonColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.orgName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('Affiliation: ${m.collegeAffiliation} • Role: ${m.role}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
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
          onEndEvent: widget.onEndEvent,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. ORGANIZATION WORKSPACE (OFFICER SCREEN)
// -------------------------------------------------------------

class OrgWorkspaceScreen extends StatefulWidget {
  final UserAccount user;
  final OrgMembership org;
  final List<CampusAnnouncement> announcements;
  final ValueChanged<CampusAnnouncement> onAddAnnouncement;
  final ValueChanged<String> onEndEvent;

  const OrgWorkspaceScreen({
    super.key,
    required this.user,
    required this.org,
    required this.announcements,
    required this.onAddAnnouncement,
    required this.onEndEvent,
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
        onPressed: _openCreatePostDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Post / Notice'),
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

            const Text(
              'Organization Activity Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: maroonColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap any event to view attendees, schedule, location, and evaluation survey statistics.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            if (widget.announcements.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No announcements or events published yet for this organization.'),
              ),

            // Event card on Org Screen: DOES NOT SHOW survey score or attendees!
            // Clicking opens modal showing full info & stats button!
            ...widget.announcements.map((ann) => _buildOfficerEventCard(ann)),
          ],
        ),
      ),
    );
  }

  // Org Screen Event Card: Clean, NO attendee/survey scores on card!
  Widget _buildOfficerEventCard(CampusAnnouncement ann) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOfficerEventModal(ann),
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
              if (ann.isEvent)
                Text(
                  '${ann.dateTime} • ${ann.venue}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                )
              else
                const Text(
                  'Normal Announcement (Non-event post)',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Officer Modal when event card is clicked: Full info + stats button + QR view
  void _openOfficerEventModal(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(ann.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: maroonColor)),
            const SizedBox(height: 12),

            if (ann.isEvent) ...[
              Text('Schedule: ${ann.dateTime}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Venue: ${ann.venue}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Total Attendees Recorded: ${ann.attendeesCount} Students',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text('Status: ${ann.isEnded ? "Concluded / Ended" : "Active / Ongoing"}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ann.isEnded ? Colors.blue : Colors.green)),
            ],
            const SizedBox(height: 10),
            Text(ann.description, style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4)),
            const SizedBox(height: 18),

            // BUTTON: View Form Stats Screen (GForm style analytics)
            if (ann.isEvent) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventSurveyStatsScreen(announcement: ann),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('View Evaluation Form Stats & Analytics'),
                ),
              ),
              const SizedBox(height: 10),

              // BUTTON: View Official Event QR Code (on-screen display)
              if (ann.isApproved) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: maroonColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showViewQrDialog(ann);
                    },
                    icon: const Icon(Icons.qr_code_2, size: 18, color: maroonColor),
                    label: const Text('View Event QR Code', style: TextStyle(color: maroonColor)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // View QR code on-screen (not just download)
  void _showViewQrDialog(CampusAnnouncement ann) {
    const maroonColor = Color(0xFF7A0C16);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Official Event QR Code\n${ann.title}', style: const TextStyle(fontSize: 15)),
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
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Attendees can scan this QR directly from this screen for check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
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
            label: const Text('Save to Storage'),
          ),
        ],
      ),
    );
  }

  // Create post dialog: Select between Normal Announcement vs Event Announcement!
  void _openCreatePostDialog() {
    const maroonColor = Color(0xFF7A0C16);

    bool isEventPost = true; // Selector
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final surveyCtrl = TextEditingController();
    String target = widget.org.orgId == 'ssc' ? 'All' : widget.org.collegeAffiliation;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Post / Notice', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector: Normal Announcement vs Event Announcement
                const Text('Select Post Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Normal Notice'),
                        selected: !isEventPost,
                        selectedColor: maroonColor,
                        labelStyle: TextStyle(color: !isEventPost ? Colors.white : Colors.black87, fontSize: 11),
                        onSelected: (_) => setDialogState(() => isEventPost = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Event Notice'),
                        selected: isEventPost,
                        selectedColor: maroonColor,
                        labelStyle: TextStyle(color: isEventPost ? Colors.white : Colors.black87, fontSize: 11),
                        onSelected: (_) => setDialogState(() => isEventPost = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description / Guidelines', border: OutlineInputBorder())),
                const SizedBox(height: 10),

                // If Event Announcement, require logistics and survey setup!
                if (isEventPost) ...[
                  TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue (e.g. TCU Gymnasium)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                    controller: surveyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Evaluation Survey Question',
                      hintText: 'e.g. Rate speaker relevance & clarity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Text(
                  'Audience: $target (Restricted to your authority)',
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
                  id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  orgId: widget.org.orgId,
                  orgName: widget.org.orgName,
                  targetAudience: target,
                  venue: isEventPost ? venueCtrl.text.trim() : '',
                  dateTime: isEventPost ? dateCtrl.text.trim() : '',
                  bannerCategory: isEventPost ? 'tech' : 'assembly',
                  isEvent: isEventPost,
                  isApproved: widget.org.orgId == 'ssc',
                  approvalStatus: widget.org.orgId == 'ssc'
                      ? 'Cleared by Mother Org'
                      : 'Pending Mother Org Clearance',
                  surveyQuestions: isEventPost && surveyCtrl.text.isNotEmpty ? [surveyCtrl.text.trim()] : [],
                );
                widget.onAddAnnouncement(newAnn);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.org.orgId == 'ssc'
                        ? 'Post Cleared & Published!'
                        : 'Post Submitted for Mother Org Clearance!'),
                  ),
                );
              },
              child: const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. FORM STATS & RESPONSES SCREEN (GOOGLE FORMS RESPONSES STYLE)
// -------------------------------------------------------------

class EventSurveyStatsScreen extends StatelessWidget {
  final CampusAnnouncement announcement;

  const EventSurveyStatsScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      appBar: AppBar(
        title: Text('${announcement.title} - Responses', style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: 'Export to Excel (.xlsx)',
            icon: const Icon(Icons.table_view, color: Colors.lightGreenAccent),
            onPressed: () => _exportToExcel(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Responses Count Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${announcement.attendeesCount} responses',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Accepting responses', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _exportToExcel(context),
                      icon: const Icon(Icons.file_download, size: 16),
                      label: const Text('Export Excel'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stat Card 1: Linear Satisfaction Rating
            _buildStatCard(
              title: '1. Overall Satisfaction Rating',
              subtitle: 'Average Score: ${announcement.averageRating} / 5.0 (Weighted Average)',
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProgressBar('5 Stars (Excellent)', 0.78, '78%'),
                  const SizedBox(height: 6),
                  _buildProgressBar('4 Stars (Very Good)', 0.16, '16%'),
                  const SizedBox(height: 6),
                  _buildProgressBar('3 Stars (Neutral)', 0.04, '4%'),
                  const SizedBox(height: 6),
                  _buildProgressBar('1-2 Stars (Poor)', 0.02, '2%'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stat Card 2: Relevance & Academic Value
            _buildStatCard(
              title: '2. Relevance to Academic & Career Development',
              subtitle: '${announcement.attendeesCount} responses',
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProgressBar('Highly Relevant & Informative', 0.82, '82%'),
                  const SizedBox(height: 6),
                  _buildProgressBar('Moderately Relevant', 0.14, '14%'),
                  const SizedBox(height: 6),
                  _buildProgressBar('Slightly / Not Relevant', 0.04, '4%'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stat Card 3: Qualitative Feedback / Suggestions
            _buildStatCard(
              title: '3. Student Feedback & Comments',
              subtitle: 'Recent student submissions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (announcement.attendeeFeedbackList.isEmpty)
                    const Text('No text comments recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...announcement.attendeeFeedbackList.map(
                      (feedback) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text('“$feedback”', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToExcel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_view, color: Colors.green),
            SizedBox(width: 8),
            Text('Excel Export Ready'),
          ],
        ),
        content: Text(
          'Downloaded TCU_GATHER_${announcement.id}_Responses.xlsx with ${announcement.attendeesCount} response rows.\n\nFile saved to: Downloads/TCU_GATHER_${announcement.id}_Responses.xlsx',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String subtitle, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double ratio, String percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
            Text(percentage, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7A0C16)),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 5. EVALUATION SURVEY SCREEN (WITH PHILIPPINE DATA PRIVACY CONSENT)
// -------------------------------------------------------------

class EvaluationSurveyScreen extends StatefulWidget {
  final UserAccount user;
  final CampusAnnouncement announcement;
  final VoidCallback onComplete;

  const EvaluationSurveyScreen({
    super.key,
    required this.user,
    required this.announcement,
    required this.onComplete,
  });

  @override
  State<EvaluationSurveyScreen> createState() => _EvaluationSurveyScreenState();
}

class _EvaluationSurveyScreenState extends State<EvaluationSurveyScreen> {
  int _overallRating = 5;
  String _relevanceChoice = 'Highly Relevant & Informative';
  String _organizationChoice = 'Exceeded Expectations';
  final _commentController = TextEditingController();
  bool _dataPrivacyAgreed = false; // Philippine Data Privacy Checkbox
  bool _submitted = false;

  void _submitForm() {
    if (!_dataPrivacyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the Philippine Data Privacy Consent box before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _submitted = true;
    });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const formBg = Color(0xFFF4F1F8);

    return Scaffold(
      backgroundColor: formBg,
      appBar: AppBar(
        title: const Text('Event Evaluation Form', style: TextStyle(fontSize: 16)),
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

  Widget _buildConfirmationCard() {
    const maroonColor = Color(0xFF7A0C16);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: const BoxDecoration(
              color: maroonColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.announcement.title} - Evaluation',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your response has been recorded. Thank you for completing your evaluation!',
                  style: TextStyle(fontSize: 13.5, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attendance clearance credit has been automatically verified on your TCU Student Profile.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildFormContent() {
    const maroonColor = Color(0xFF7A0C16);
    const requiredRed = Color(0xFFD93025);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Form Header Card (Using App Student Account, NOT Google)
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: maroonColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.announcement.title} - Evaluation Form',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organized by: ${widget.announcement.orgName}\nVenue: ${widget.announcement.venue}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.person_pin, size: 20, color: maroonColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student: ${widget.user.fullName} (${widget.user.studentNumber}) • ${widget.user.college}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '* Indicates required question',
                      style: TextStyle(color: requiredRed, fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. PHILIPPINE DATA PRIVACY CONSENT NOTICE CARD (RA 10173)
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: maroonColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: maroonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Philippine Data Privacy Consent Notice',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Republic Act No. 10173 (Data Privacy Act of 2012)',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Taguig City University is committed to protecting your privacy rights. In compliance with the Philippine Data Privacy Act of 2012, all responses gathered in this evaluation form will be processed strictly for attendance accreditation, student clearance, and program enhancement. Your responses will remain confidential.',
                  style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: maroonColor,
                  value: _dataPrivacyAgreed,
                  title: const Text(
                    'I have read, understood, and agree to the TCU Data Privacy Consent Agreement *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) {
                    setState(() => _dataPrivacyAgreed = val ?? false);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Question 1: Linear Scale (1 to 5)
        _buildQuestionCard(
          title: '1. Overall satisfaction with this event *',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Poor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ...List.generate(5, (index) {
                  final val = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Text('$val', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                const Text('Excellent', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. Question 2: Multiple Choice (Relevance)
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
                title: Text(option, style: const TextStyle(fontSize: 12.5)),
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

        // 5. Question 3: Multiple Choice (Organization)
        _buildQuestionCard(
          title: '3. Organization and venue accommodation *',
          child: Column(
            children: [
              'Exceeded Expectations',
              'Met Expectations',
              'Needs Improvement',
            ].map((option) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option, style: const TextStyle(fontSize: 12.5)),
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

        // 6. Question 4: Paragraph Feedback
        _buildQuestionCard(
          title: '4. Suggestions or recommendations for future TCU events',
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your comments or requested topics...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _submitForm,
            child: const Text('Submit Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
