# 🎓 BMS EDGE: A Social & Management Platform for Academic Institutions

**BMS EDGE** is a comprehensive, role-based social and management application designed specifically for academic institutions.  
Built with **Flutter** and **Firebase**, this platform streamlines communication, automates administrative workflows, and provides faculty with a unified hub for their daily professional lives.

The application is fully responsive, offering a seamless experience on **mobile (iOS/Android)** and the **web**.

---

## ✨ Key Features

### 📢 Social & Communication
- **LinkedIn-Style Feed**: A central feed displaying achievements and events in a unified, chronological timeline.  
- **Interactive Posts**: Faculty can post achievements with text and multiple images (horizontally scrollable gallery).  
- **Advanced Reactions**: Long-press on "React" reveals a menu of emoji reactions (👍 🎉 ❤️ 💡 😂).  
- **Comments & Reposts**: Full commenting system and one-click repost feature.  
- **@Mentions**: Faculty can tag colleagues in posts, linking directly to their profile.  

### 🏛️ Management & Hierarchy
- **Role-Based Adaptive UI**: The app adapts its interface based on the user's role (Faculty, Cluster Head, HOD).  
- **Multi-Step Leave Approval**:
  1. Faculty apply for leave → routed to Cluster Head.  
  2. Cluster Head approves/rejects → if approved, it goes to HOD.  
  3. HOD final approval → automatically updates leave balance.  
- **Hierarchical Team Management**:
  - HODs can appoint Cluster Heads and manage faculty assignments.  
  - Managers have a **Team tab** to view reports and handle approvals.  
- **Task Assignment**: Assign tasks with deadlines and details to individuals or groups.  

### 📅 Productivity & Personalization
- **Personalized Calendar**: Dual view—month/week with event markers and a detailed daily timetable.  
- **Unified Daily Agenda**: Consolidated view of classes, tasks, events, leaves, and holidays.  
- **Smart Search**: Case-insensitive, intent-aware search (by name or role).  

### 🤖 AI & Support
- **Personalized AI Chatbot**: Integrated assistant powered by **Google Gemini API**.  
- **RAG (Retrieval-Augmented Generation)**: Chatbot uses Firestore context (college policies + personal data) for accurate, contextual answers.  

---

## 🛠️ Tech Stack & Architecture

**Frontend:** Flutter  
**Backend & Database:** Firebase (Auth, Firestore, Cloud Functions, Storage)  
**AI Engine:** Google Gemini API  

**Key Flutter Packages:**
- `flutter_riverpod` → scalable state management  
- `table_calendar` → personalized calendar UI  
- `rxdart` → combining streams  
- `audioplayers` → UI sound effects  

**Architectural Highlights:**
- **Role-Based Adaptive UI**: Single codebase → multiple role-specific experiences.  
- **Automated Backend**: Cloud Functions for new user setup, cleanup, and optimized search fields.  
- **Optimistic UI**: Instant feedback for actions like reacting/reposting while database updates in background.  

---

## 🚀 Getting Started

### ✅ Prerequisites
- Flutter SDK installed  
- Firebase CLI installed:  
  ```bash
  npm install -g firebase-tools
