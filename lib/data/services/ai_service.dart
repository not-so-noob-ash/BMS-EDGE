import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import all your existing models and services
import '../models/user_model.dart';
import '../models/leave_application_model.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'leave_service.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Your API key is correctly placed here.
  final String _apiKey = "PUT YOUR API KEY HERE";
  
  final String _modelUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

  Future<String> getChatResponse(String userQuery) async {
    final user = AuthService().currentUser;
    if (user == null) return "Error: User not logged in.";

    // --- THIS IS THE FIX ---
    // The problematic 'if' block has been removed.
    // We now proceed directly to gathering context and calling the API.

    try {
      // 1. GATHER CONTEXT
      final collegeInfoDoc = await _firestore.collection('collegeInfo').doc('policies').get();
      final collegeData = collegeInfoDoc.data() ?? {};
      final UserModel? userProfile = await UserService().getUserProfile(user.uid);
      final List<LeaveApplicationModel> leaveHistory = await LeaveService().getLeaveHistory(user.uid).first;

      // 2. CONSTRUCT THE DETAILED PROMPT
      String context = """
      You are a helpful and friendly AI assistant for the faculty of BMS College. Your name is 'BMS Edge Assistant'.
      Your purpose is to answer questions based ONLY on the context provided below. Do not make up information.
      If the answer is not in the context, say "I do not have information on that topic."
      Today's date is ${DateFormat.yMMMd().format(DateTime.now())}.

      --- CONTEXT: GENERAL COLLEGE INFORMATION ---
      About the College: ${collegeData['about']}
      General Leave Policy: ${collegeData['leavePolicy']}
      Working Hours: ${collegeData['workingHours']}
      Contact Information: ${collegeData['contactInfo']}

      --- CONTEXT: THIS USER'S PERSONAL DATA ---
      User Name: ${userProfile?.name ?? 'N/A'}
      User Email: ${userProfile?.email ?? 'N/A'}
      User Department: ${userProfile?.department ?? 'Not set'}
      User Post: ${userProfile?.teacherPost ?? 'Not set'}
      Date of Joining: ${userProfile?.dateOfJoining != null ? DateFormat.yMMMd().format(userProfile!.dateOfJoining!.toDate()) : 'Not set'}
      
      User's Leave Application History (${leaveHistory.length} records):
      ${leaveHistory.isEmpty ? "No leave applications have been submitted." : leaveHistory.map((leave) => 
        "- Type: ${leave.leaveType}, From: ${DateFormat.yMMMd().format(leave.startDate)} to ${DateFormat.yMMMd().format(leave.endDate)}, Status: ${leave.status}"
      ).join('\n')}

      --- END OF CONTEXT ---

      Based strictly on the context above, answer the user's question.
      User Question: "$userQuery"
      """;
      
      // 3. CALL THE GEMINI API
      final response = await http.post(
        Uri.parse('$_modelUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': context}]}]
        }),
      );

      // 4. PROCESS THE RESPONSE
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Added safety checks for the response structure
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return "Sorry, I received an empty response from the AI.";
      } else {
        print("Error from Gemini API: ${response.body}");
        return "Sorry, I'm having trouble connecting to the AI service right now. Please try again later.";
      }
    } catch (e) {
      print("Error in getChatResponse: $e");
      return "An error occurred. Please check your internet connection and try again.";
    }
  }
}