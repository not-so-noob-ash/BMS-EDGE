BMS EDGE: A Social & Management Platform for Academic Institutions
BMS EDGE is a comprehensive, role-based social and management application designed specifically for academic institutions. Built with Flutter and Firebase, this platform aims to streamline communication, automate administrative workflows, and provide faculty with a unified hub for their daily professional lives.

The application is designed to be fully responsive, offering a seamless experience on both mobile devices (iOS/Android) and the web.

!

✨ Key Features
This project integrates a rich set of features designed to cater to the complex needs of a modern college faculty.

Social & Communication
LinkedIn-Style Feed: A central feed displaying achievements and events in a unified, chronological timeline.

Interactive Posts: Faculty can post achievements with text and multiple image attachments (displayed in a horizontally scrollable gallery).

Advanced Reactions: A long-press on the "React" button reveals a horizontal menu of multiple emoji reactions (👍, 🎉, ❤️, 💡, 😂).

Comments & Reposts: A complete commenting system on posts and a one-click repost feature.

@Mentions: Faculty can tag their colleagues in posts, creating a clickable link to the tagged person's profile.

Management & Hierarchy
Role-Based Adaptive UI: The entire application interface intelligently adapts based on the user's role (Faculty, Cluster Head, HOD). Managers see additional tabs and options that are hidden from regular faculty.

Multi-Step Leave Approval Workflow:

Faculty apply for leave, which is routed to their Cluster Head.

The Cluster Head can approve or reject. If approved, the request is automatically forwarded to the HOD.

The HOD gives the final approval, which automatically updates the faculty's leave balance.

Hierarchical Team Management:

HODs can appoint faculty as Cluster Heads directly within the app.

HODs can assign and un-assign faculty to different clusters.

Managers have a "Team" tab to view their direct reports and manage pending approvals.

Task Assignment: Managers (and faculty) can assign tasks to one or more colleagues with deadlines and details.

Productivity & Personalization
Personalized Calendar: A two-section calendar showing a high-level month/week view with color-coded event markers, and a detailed daily timetable below.

Unified Daily Agenda: The timetable view consolidates a faculty member's entire day, including recurring classes, assigned tasks, college events, approved leaves, and public holidays, all in one scrollable timeline.

Smart Search: A powerful, case-insensitive search that automatically detects user intent. Users can search for colleagues by name ("sharma") or by their additional roles ("timetable"), and the app will intelligently display combined, categorized results.

AI & Support
Personalized AI Chatbot: An integrated AI assistant powered by the Gemini API.

Retrieval-Augmented Generation (RAG): The chatbot is provided with real-time context from Firestore—including general college policies and the user's own personal data (profile, leave history)—to provide accurate, personalized, and context-aware answers.

🛠️ Tech Stack & Architecture
Frontend: Flutter

Backend & Database: Firebase (Authentication, Firestore, Cloud Functions, Storage)

AI Engine: Google Gemini API

Key Flutter Packages:

flutter_riverpod (for scalable state management)

table_calendar (for the personalized calendar UI)

rxdart (for combining data streams)

audioplayers (for UI sound effects)

Architectural Highlights:

Role-Based Adaptive UI: A single codebase that presents a different user experience based on user permissions.

Automated Backend Processes: Cloud Functions handle critical tasks like new user setup (creating leave balances), data cleanup on user deletion, and maintaining optimized search fields.

Optimistic UI: For actions like reacting and reposting, the UI updates instantly, providing a snappy user experience while the database call completes in the background.

🚀 Getting Started
To get a local copy up and running, follow these simple steps.

Prerequisites
Flutter SDK installed.

Firebase CLI installed (npm install -g firebase-tools).

An active Firebase project with the Blaze plan (required for Cloud Functions).

Installation & Setup
Clone the repo:

git clone [https://github.com/your_username/faculty-connect.git](https://github.com/your_username/faculty-connect.git)
cd faculty-connect

Flutter Setup:

flutter pub get

Firebase Project Setup:

Create a new Firebase project.

Enable Authentication (with Google Sign-In), Firestore Database, and Storage.

Add an Android, iOS, and Web app to your Firebase project. Follow the setup instructions and add the generated google-services.json (for Android) and firebase-options.js (for Web) to your project.

Update your Firestore Security Rules and Storage Rules.

Cloud Functions Setup:

Navigate to the functions directory: cd functions

Install dependencies: npm install

Deploy the functions: firebase deploy --only functions

API Keys:

Create a Gemini API key from Google AI Studio.

Paste this key into the _apiKey variable in lib/data/services/ai_service.dart. (For a production app, it's recommended to store this in a secure way, e.g., using a .env file or a Cloud Function).

Run the App:

flutter run

🛣️ Future Roadmap
Full Appointment Scheduling: Implement the UI for faculty to set availability and for others to book appointments with conflict detection.

Messaging: Build out the real-time one-on-one and group messaging feature.

Document Management: Implement the "Upload Document" feature with sharing and versioning.

This project was developed as a comprehensive solution to enhance the digital ecosystem of an academic institution.
