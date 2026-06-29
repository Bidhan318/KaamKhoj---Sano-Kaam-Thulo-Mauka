# Walkthrough - Direct Hire Flow Implementation (Updated)

Here is a walkthrough of the final implementation of the **Direct Hire / Hire Now** feature.

## Changes Made

### 1. Security-Rules-Compliant Hire Screen: `hire_worker_screen.dart`
- Form located at [hire_worker_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/worker/hire_worker_screen.dart) displays:
  - Client location at the top.
  - Target worker details (profile avatar, name, and service) under a clean header (removed the "(Fixed)" label).
  - Form fields for Job Description and Budget (NPR) with validation.
  - Submit buttons (**Confirm** and **Cancel**).
  - On **Confirm**, the job request is written to Firestore with `status = 'open'` and `assignedWorkerUid = worker.uid`. This aligns with Firestore **Condition 2** security rules (accepting an open job) without modifying database configurations.

### 2. Filtering Direct Hires from Browse Lists
- **Job List:** Updated [job_list_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/job/job_list_screen.dart) to filter out open jobs where `assignedWorkerUid != null`. This prevents direct hire requests from showing up in public browse lists for other workers.
- **Worker Map:** Updated [home_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/home/home_screen.dart)'s map stream for open jobs to ignore direct hires, ensuring other workers do not see the requested job on their maps.

### 3. Verification & Accept Button in Job Details
- Updated [job_detail_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/job/job_detail_screen.dart)'s `isOpen` condition:
  `final isOpen = job.status == 'open' && (job.assignedWorkerUid == null || job.assignedWorkerUid == auth.user!.uid);`
- This ensures only the requested worker can see the **Accept Job** button for a direct hire request, securing it in the detail view.

### 4. Dynamic Home Screen Banner & Button Offset
- Refactored [home_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/home/home_screen.dart) to listen to direct hire requests (`status == 'open'` and `assignedWorkerUid == auth.user.uid`).
- **Layout Conflict Resolved:** Positioned the bottom action buttons (like "My Location") using a dynamic offset:
  `final double bottomOffset = (_hasOngoingJob || hasRequest) ? 220.0 : 24.0;`
  This pushes the map buttons up to 220.0 whenever a notification banner (or ongoing work card) is visible at the bottom, preventing any overlap.
- **Banner Layout:** Displays the direct hire notification banner with **View Details** (opens details screen) and **Accept Job** (manually transitions status to `'assigned'` under Firestore rules) buttons. The decline button was removed to match security rules for `'open'` jobs.
