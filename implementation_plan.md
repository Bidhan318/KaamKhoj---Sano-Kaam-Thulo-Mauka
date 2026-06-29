# Implementation Plan - Direct Hire Feature

This plan details the implementation of the "Hire Now" feature, allowing clients to directly hire a worker from their profile screen.

## Proposed Changes

### Core Elements

---

#### [NEW] [hire_worker_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/worker/hire_worker_screen.dart)
Create a new form screen for clients to initiate a hire request for a specific worker:
- **Location Indicator on Top**: Displays the client's current address using `LocationProvider`.
- **Fixed Parameters Display**: Displays the target worker's name, profile photo, and the job type/skill (fixed based on worker's primary skill).
- **Form Fields**: Job Description and Budget (NPR) with validation.
- **Action Buttons**: Confirm (posts job with status `'requested'`, sets `assignedWorkerUid` to the worker's UID, and navigates back) and Cancel (navigates back without action).

---

#### [MODIFY] [worker_profile_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/worker/worker_profile_screen.dart)
Link the **Hire Now** action button to navigate to the new `HireWorkerScreen` instead of showing a placeholder SnackBar.

---

#### [MODIFY] [job_detail_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/job/job_detail_screen.dart)
Update the `isWorker` action condition:
- Show the "Accept Job" button if `job.status == 'requested'` (in addition to the existing `'open'` status), allowing the worker to accept the job from the detail view.

---

#### [MODIFY] [home_screen.dart](file:///c:/Users/ACER/Downloads/kaamkhoj/KaamKhoj---Sano-Kaam-Thulo-Mauka-main/lib/screens/home/home_screen.dart)
Add support for displaying direct hire request notifications:
- Listen to a stream of jobs where `assignedWorkerUid == auth.user.uid` and `status == 'requested'`.
- If a request is active and the worker has no ongoing job, display a bottom banner notifying them: *"Someone has requested to hire you."*
- Include **View** (navigates to the job details page) and **Accept** (reuses the existing acceptance logic by updating status to `'assigned'` and starting work) buttons.

## Verification Plan

### Manual Verification
1. Log in as a Client.
2. Tap on an available worker's profile.
3. Tap **Hire Now** button.
4. Fill out the Job Description and Budget on the `HireWorkerScreen` (verify that worker details and location are displayed on top).
5. Tap **Confirm** to submit.
6. Log in as the targeted Worker.
7. Observe the bottom banner notification: *"Someone has requested to hire you."*
8. Tap **View** to inspect details (verify the job detail page opens with the Accept option).
9. Tap **Accept** (from either home banner or job details) and verify that the job shifts to "Work Ongoing" with route navigation.
