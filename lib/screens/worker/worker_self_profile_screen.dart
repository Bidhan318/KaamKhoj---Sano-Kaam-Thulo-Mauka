// lib/screens/worker/worker_self_profile_screen.dart
//
// PURPOSE: Lets a logged-in worker view how their profile looks to clients
// AND edit/save their profile. Two tabs: Preview (client view) + Edit Profile.
// Only shown to users with role='worker'.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import 'worker_profile_screen.dart';

// Common skill options for Nepal context
const List<String> _kSkillOptions = [
'Electrician',
'Plumber',
'Carpenter',
'Painter',
'Mason',
'Tutor',
'Driver',
'Cook',
'Cleaner',
'Welder',
'Mechanic',
'Gardener',
'Security Guard',
'Helper',
];

class WorkerSelfProfileScreen extends StatefulWidget {
const WorkerSelfProfileScreen({super.key});

@override
State<WorkerSelfProfileScreen> createState() =>
_WorkerSelfProfileScreenState();
}

class _WorkerSelfProfileScreenState extends State<WorkerSelfProfileScreen>
with SingleTickerProviderStateMixin {
late TabController _tabController;

@override
void initState() {
super.initState();
_tabController = TabController(length: 2, vsync: this);

// Load worker profile on open
WidgetsBinding.instance.addPostFrameCallback((_) {
final auth = context.read<AuthProvider>();
if (auth.user != null) {
context.read<WorkerProvider>().loadMyWorkerProfile(auth.user!.uid);
}
});
}

@override
void dispose() {
_tabController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final workerProvider = context.watch<WorkerProvider>();

return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
title: const Text('My Profile'),
bottom: TabBar(
controller: _tabController,
tabs: const [
Tab(icon: Icon(Icons.preview_outlined), text: 'Client View'),
Tab(icon: Icon(Icons.edit_outlined), text: 'Edit Profile'),
],
),
),
body: workerProvider.isLoading
? const Center(
child: CircularProgressIndicator(color: AppColors.primary),
)
    : workerProvider.myWorkerProfile == null
? _buildNoProfile()
    : TabBarView(
controller: _tabController,
children: [
// Tab 1: How the client sees this worker
_PreviewTab(worker: workerProvider.myWorkerProfile!),
// Tab 2: Edit form
_EditTab(
worker: workerProvider.myWorkerProfile!,
onSaved: () {
// Switch back to preview after saving
_tabController.animateTo(0);
},
),
],
),
);
}

Widget _buildNoProfile() {
return Center(
child: Padding(
padding: const EdgeInsets.all(32),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.person_off_outlined,
size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
const SizedBox(height: 16),
const Text(
'Profile not found',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: AppColors.textPrimary),
),
const SizedBox(height: 8),
const Text(
'Your worker profile could not be loaded.\nPlease try again.',
textAlign: TextAlign.center,
style: TextStyle(color: AppColors.textSecondary),
),
const SizedBox(height: 24),
ElevatedButton.icon(
onPressed: () {
final auth = context.read<AuthProvider>();
if (auth.user != null) {
context
    .read<WorkerProvider>()
    .loadMyWorkerProfile(auth.user!.uid);
}
},
icon: const Icon(Icons.refresh),
label: const Text('Retry'),
),
],
),
),
);
}
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Preview — shows the existing WorkerProfileScreen but with a banner
// and without the hire/chat buttons (replaced by "Edit Profile" button).
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewTab extends StatelessWidget {
final WorkerModel worker;
const _PreviewTab({required this.worker});

@override
Widget build(BuildContext context) {
return Stack(
children: [
// Reuse the existing client-facing profile screen widget
// We pass it as a nested widget, not a Navigator push,
// so we intercept its back button with our own tab.
_ClientViewWrapper(worker: worker),

// Top banner: "This is how clients see you"
Positioned(
top: 0,
left: 0,
right: 0,
child: Container(
color: AppColors.secondary.withValues(alpha: 0.92),
padding:
const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Row(
children: [
const Icon(Icons.visibility_outlined,
color: Colors.white, size: 16),
const SizedBox(width: 8),
const Expanded(
child: Text(
'This is how clients see your profile',
style: TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w500,
),
),
),
GestureDetector(
onTap: () {
// Scroll to edit tab — parent TabController
final tabController = DefaultTabController.maybeOf(context);
tabController?.animateTo(1);
// Find our own TabController via the state
context
    .findAncestorStateOfType<_WorkerSelfProfileScreenState>()
    ?._tabController
    .animateTo(1);
},
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.2),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: Colors.white.withValues(alpha: 0.5)),
),
child: const Text(
'Edit',
style: TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w600),
),
),
),
],
),
),
),
],
);
}
}

/// Renders the WorkerProfileScreen body inline (without its own Scaffold/AppBar)
/// so it sits inside our TabBarView. We rebuild the profile widgets directly
/// rather than Navigator.push so the tab stays intact.
class _ClientViewWrapper extends StatelessWidget {
final WorkerModel worker;
const _ClientViewWrapper({required this.worker});

@override
Widget build(BuildContext context) {
// WorkerProfileScreen is a full Scaffold — we embed it in a SizedBox
// and use a ClipRect + top padding to push content below our banner.
return Padding(
padding: const EdgeInsets.only(top: 36), // height of the banner
child: WorkerProfileScreen(
worker: worker,
 // we added this optional param below
),
);
}
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Edit Profile form
// ─────────────────────────────────────────────────────────────────────────────

class _EditTab extends StatefulWidget {
final WorkerModel worker;
final VoidCallback onSaved;

const _EditTab({required this.worker, required this.onSaved});

@override
State<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<_EditTab> {
final _formKey = GlobalKey<FormState>();
final _nameCon = TextEditingController();
final _phoneCon = TextEditingController();
final _rateCon = TextEditingController();
List<String> _skills = [];
bool _isAvailable = true;
File? _pickedImage;
String? _currentImageUrl;
bool _imageRemoved = false;

@override
void initState() {
super.initState();
_nameCon.text = widget.worker.name;
_phoneCon.text = widget.worker.phone;
_rateCon.text = widget.worker.ratePerDay.toInt().toString();
_skills = List<String>.from(widget.worker.skills);
_isAvailable = widget.worker.isAvailable;
_currentImageUrl = widget.worker.profileImage;
}

@override
void didUpdateWidget(_EditTab old) {
super.didUpdateWidget(old);
// If the worker model refreshed from outside, sync only if user hasn't
// started editing (detect via form dirty state would be complex,
// so we just sync on first load above — this is fine for our use case)
}

@override
void dispose() {
_nameCon.dispose();
_phoneCon.dispose();
_rateCon.dispose();
super.dispose();
}

Future<void> _pickImage() async {
final picker = ImagePicker();
final picked =
await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
if (picked != null) {
setState(() {
_pickedImage = File(picked.path);
_imageRemoved = false;
});
}
}

void _removeImage() {
setState(() {
_pickedImage = null;
_currentImageUrl = null;
_imageRemoved = true;
});
}

void _addSkill(String skill) {
if (!_skills.contains(skill)) {
setState(() => _skills.add(skill));
}
}

void _removeSkill(String skill) {
setState(() => _skills.remove(skill));
}

Future<void> _save() async {
if (!_formKey.currentState!.validate()) return;
if (_skills.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please add at least one skill.')),
);
return;
}

final workerProvider = context.read<WorkerProvider>();
String? imageUrl = _imageRemoved ? null : _currentImageUrl;

try {
// Upload new image if picked


final updated = WorkerModel(
  uid: widget.worker.uid,
  name: _nameCon.text.trim(),
  phone: _phoneCon.text.trim(),
  profileImage: imageUrl,
  skills: _skills,
  ratePerDay: double.tryParse(_rateCon.text.trim()) ??
      widget.worker.ratePerDay,
  rating: widget.worker.rating,
  totalReviews: widget.worker.totalReviews,
  isAvailable: _isAvailable,
  latitude: widget.worker.latitude,
  longitude: widget.worker.longitude,
  address: widget.worker.address,
);
await workerProvider.saveWorkerProfile(updated);

if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Profile saved successfully!')),
);
widget.onSaved();
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Failed to save: $e')),
);
}
}

@override
Widget build(BuildContext context) {
final isSaving = context.watch<WorkerProvider>().isLoading;

return SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ── Profile Photo ─────────────────────────────────────────────
_sectionTitle('Profile Photo'),
const SizedBox(height: 12),
Center(child: _buildPhotoSection()),
const SizedBox(height: 24),

// ── Availability toggle ───────────────────────────────────────
_buildAvailabilityToggle(),
const SizedBox(height: 24),

// ── Basic Info ────────────────────────────────────────────────
_sectionTitle('Basic Info'),
const SizedBox(height: 12),
TextFormField(
controller: _nameCon,
decoration: const InputDecoration(
labelText: 'Full Name',
prefixIcon: Icon(Icons.person_outline),
),
textCapitalization: TextCapitalization.words,
validator: (v) =>
(v == null || v.trim().isEmpty) ? 'Name is required' : null,
),
const SizedBox(height: 14),
const SizedBox(height: 14),
TextFormField(
controller: _phoneCon,
decoration: const InputDecoration(
labelText: 'Phone Number',
prefixIcon: Icon(Icons.phone_outlined),
hintText: 'e.g. 98XXXXXXXX',
),
keyboardType: TextInputType.phone,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
validator: (v) =>
(v == null || v.trim().isEmpty) ? 'Phone is required' : null,
),
const SizedBox(height: 14),
TextFormField(
controller: _rateCon,
decoration: const InputDecoration(
labelText: 'Daily Rate (NPR)',
prefixIcon: Icon(Icons.payments_outlined),
hintText: 'e.g. 1500',
),
keyboardType: TextInputType.number,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
validator: (v) {
if (v == null || v.trim().isEmpty) return 'Rate is required';
final n = int.tryParse(v.trim());
if (n == null || n <= 0) return 'Enter a valid rate';
return null;
},
),
const SizedBox(height: 24),

// ── Skills ────────────────────────────────────────────────────
_sectionTitle('Skills'),
const SizedBox(height: 4),
const Text(
'Tap to add or remove skills',
style:
TextStyle(fontSize: 12, color: AppColors.textSecondary),
),
const SizedBox(height: 12),
_buildSkillsEditor(),
const SizedBox(height: 32),

// ── Save Button ───────────────────────────────────────────────
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: isSaving ? null : _save,
icon: isSaving
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(Icons.save_outlined),
label: Text(isSaving ? 'Saving…' : 'Save Profile'),
),
),
],
),
),
);
}

Widget _buildPhotoSection() {
final hasImage = _pickedImage != null || _currentImageUrl != null;

return Column(
children: [
Stack(
children: [
Container(
width: 100,
height: 100,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: AppColors.primary.withValues(alpha: 0.1),
border: Border.all(color: AppColors.primary, width: 2),
image: _pickedImage != null
? DecorationImage(
image: FileImage(_pickedImage!),
fit: BoxFit.cover,
)
    : (_currentImageUrl != null
? DecorationImage(
image: NetworkImage(_currentImageUrl!),
fit: BoxFit.cover,
)
    : null),
),
child: (!hasImage)
? Center(
child: Text(
widget.worker.name.isNotEmpty
? widget.worker.name[0].toUpperCase()
    : '?',
style: const TextStyle(
fontSize: 40,
fontWeight: FontWeight.w600,
color: AppColors.primary,
),
),
)
    : null,
),
Positioned(
bottom: 0,
right: 0,
child: GestureDetector(
onTap: _pickImage,
child: Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: AppColors.secondary,
shape: BoxShape.circle,
border: Border.all(color: Colors.white, width: 2),
),
child: const Icon(Icons.camera_alt,
color: Colors.white, size: 16),
),
),
),
],
),
const SizedBox(height: 12),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
TextButton.icon(
onPressed: _pickImage,
icon: const Icon(Icons.photo_library_outlined, size: 16),
label: const Text('Change Photo'),
),
if (hasImage) ...[
const SizedBox(width: 8),
TextButton.icon(
onPressed: _removeImage,
icon: const Icon(Icons.delete_outline,
size: 16, color: AppColors.error),
label: const Text('Remove',
style: TextStyle(color: AppColors.error)),
),
],
],
),
],
);
}

Widget _buildAvailabilityToggle() {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: AppColors.divider),
),
child: Row(
children: [
Container(
width: 10,
height: 10,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _isAvailable ? AppColors.success : AppColors.error,
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Available for Work',
style: TextStyle(
fontWeight: FontWeight.w600,
color: AppColors.textPrimary,
fontSize: 14,
),
),
Text(
_isAvailable
? 'Clients can see and contact you'
    : 'You are hidden from client searches',
style: const TextStyle(
fontSize: 11, color: AppColors.textSecondary),
),
],
),
),
Switch(
value: _isAvailable,
onChanged: (val) => setState(() => _isAvailable = val),
activeColor: AppColors.success,
),
],
),
);
}

Widget _buildSkillsEditor() {
final remaining =
_kSkillOptions.where((s) => !_skills.contains(s)).toList();

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Current skills (removable)
if (_skills.isNotEmpty) ...[
Wrap(
spacing: 8,
runSpacing: 6,
children: _skills
    .map(
(skill) => Chip(
label: Text(skill),
deleteIcon: const Icon(Icons.close, size: 14),
onDeleted: () => _removeSkill(skill),
backgroundColor: const Color(0xFFFFF3E0),
labelStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w500,
color: Color(0xFFE65100),
),
side: const BorderSide(color: Color(0xFFFFB74D)),
deleteIconColor: const Color(0xFFE65100),
),
)
    .toList(),
),
const SizedBox(height: 12),
],

// Add skills from list
if (remaining.isNotEmpty) ...[
const Text(
'Add skills:',
style:
TextStyle(fontSize: 12, color: AppColors.textSecondary),
),
const SizedBox(height: 6),
Wrap(
spacing: 8,
runSpacing: 6,
children: remaining
    .map(
(skill) => ActionChip(
label: Text(skill),
avatar: const Icon(Icons.add, size: 14),
onPressed: () => _addSkill(skill),
backgroundColor: AppColors.background,
labelStyle: const TextStyle(
fontSize: 12, color: AppColors.textSecondary),
side: const BorderSide(color: AppColors.divider),
),
)
    .toList(),
),
],
],
);
}

Widget _sectionTitle(String title) {
return Row(
children: [
Container(
width: 3,
height: 16,
decoration: BoxDecoration(
color: AppColors.primary,
borderRadius: BorderRadius.circular(2),
),
),
const SizedBox(width: 8),
Text(
title,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: AppColors.textPrimary,
),
),
],
);
}
}
