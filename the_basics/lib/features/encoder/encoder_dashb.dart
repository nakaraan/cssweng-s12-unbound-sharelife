import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_basics/core/widgets/top_navbar.dart';
import 'package:the_basics/core/widgets/side_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_basics/core/utils/themes.dart';

class EncoderDashboard extends StatefulWidget {
  const EncoderDashboard({super.key});

  @override
  State<EncoderDashboard> createState() => _EncoderDashboardState();
}

class _EncoderDashboardState extends State<EncoderDashboard> {
  int _pendingApplications = 0;
  int _pendingApproval = 0;
  int _approvedApplications = 0;
  int _totalEncodedApplications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Get current encoder's staff ID (not strictly required for counts but keep check)
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch pending applications (status = 'Pending')
      final pendingResp = await supabase
          .from('loan_application')
          .select('application_id')
          .eq('status', 'Pending');

      // Fetch approved applications from approved_loans
      final approvedResp = await supabase
          .from('approved_loans')
          .select('application_id');

      // Total encoded is all loan_application entries
      final totalResp = await supabase
          .from('loan_application')
          .select('application_id');

      // defensive counts: responses sometimes aren't Lists on error
      int pendingCount = 0;
      int approvedCount = 0;
      int totalCount = 0;

      try {
        pendingCount = (pendingResp as List).length;
      } catch (_) {}
      try {
        approvedCount = (approvedResp as List).length;
      } catch (_) {}
      try {
        totalCount = (totalResp as List).length;
      } catch (_) {}

      debugPrint('[EncoderDashboard] counts -> pending: $pendingCount, approved: $approvedCount, total: $totalCount');

      if (mounted) {
        setState(() {
          _pendingApplications = pendingCount;
          _pendingApproval = pendingCount; // Same as pending for now
          _approvedApplications = approvedCount;
          _totalEncodedApplications = totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[EncoderDashboard] Error loading statistics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/imgs/bg_in.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(
        children: [
          TopNavBar(splash: "Encoder"),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SideMenu(role: "Encoder"),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Overview",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppThemes.pageTitle),
                          ),
                          SizedBox(height: 24),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2,
                              children: [
                                SummaryCard(
                                  title: "Pending Applications", 
                                  desc: "Applications currently awaiting review, decision, or further action", 
                                  value: "$_pendingApplications", 
                                  icon: Icons.pending_actions),
                                SummaryCard(
                                  title: "Pending Approval", 
                                  desc: "Encoded applications that are awaiting administrator approval", 
                                  value: "$_pendingApproval", 
                                  icon: CupertinoIcons.hourglass),
                                SummaryCard(
                                  title: "Approved Applications", 
                                  desc: "Applications that have been reviewed and approved", 
                                  value: "$_approvedApplications", 
                                  icon: Icons.check_circle),
                                SummaryCard(
                                  title: "Total Encoded Applications", 
                                  desc: "The total number of applications that have been encoded", 
                                  value: "$_totalEncodedApplications", 
                                  icon: Icons.checklist),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String desc;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.desc,
    required this.value,
    this.icon = Icons.access_time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppThemes.lightcreme,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 200, color: CupertinoColors.placeholderText),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600), 
                    softWrap: true,
                    overflow: TextOverflow.visible),
                  SizedBox(height: 2),
                  Text(
                    desc, 
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                    softWrap: true,
                    overflow: TextOverflow.visible),
                  SizedBox(height: 8),
                  Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}