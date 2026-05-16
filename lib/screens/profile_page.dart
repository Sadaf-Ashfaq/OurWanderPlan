import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  Map<String, dynamic>? _userData;
  bool _loadingData = true;
  bool _uploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _auth.getUserData();
    if (mounted) {
      setState(() { 
        _userData = data; 
        _loadingData = false;
        _profileImageUrl = data?['profileImage'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Show options: Camera or Gallery
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imagePickerOption(Icons.camera_alt, 'Camera', () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                }),
                _imagePickerOption(Icons.photo_library, 'Gallery', () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _uploadingImage = true);
        
        // Upload to Firebase Storage
        final file = File(pickedFile.path);
        final userId = _auth.currentUser?.uid;
        
        if (userId == null) return;
        
        // Create reference
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('$userId.jpg');
        
        // Upload file
        await storageRef.putFile(file);
        
        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();
        
        // Save URL to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profileImage': downloadUrl});
        
        // Update local state
        setState(() {
          _profileImageUrl = downloadUrl;
          _userData?['profileImage'] = downloadUrl;
          _uploadingImage = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _auth.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _userData?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _userData?['phone'] ?? '');
    final bioCtrl = TextEditingController(text: _userData?['bio'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final error = await _auth.updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                    );
                  } else {
                    _loadUser();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final email = _auth.currentUser?.email ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Text('A password reset link will be sent to:\n$email'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _auth.resetPassword(email);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset email sent! Check your inbox.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAboutWanderPlan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.map_outlined, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text('WanderPlan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
            ),
            const SizedBox(height: 20),
            const Text(
              'A smart travel planning app that combines AI-powered itinerary generation, budget tracking, and cloud sync — built for students and young travelers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMid, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _aboutChip(Icons.auto_awesome, 'AI Itinerary'),
                _aboutChip(Icons.wallet_outlined, 'Budget Track'),
                _aboutChip(Icons.cloud_sync_outlined, 'Cloud Sync'),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Developed By',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Sadaf Ashfaq · Aeman Siddique · Urooj Ilyas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
            const SizedBox(height: 4),
            const Text('CSL 220 – Cloud Computing | Bahria University Karachi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }

  Widget _aboutChip(IconData icon, String label) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['name'] ?? _auth.currentUser?.displayName ?? 'User';
    final email = _userData?['email'] ?? _auth.currentUser?.email ?? '';
    final bio = _userData?['bio'] ?? '';
    final hasProfileImage = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 16),
                  
                  // Profile Picture Section - Clickable
                  GestureDetector(
                    onTap: _uploadingImage ? null : _pickAndUploadImage,
                    child: Stack(
                      children: [
                        if (hasProfileImage)
                          CircleAvatar(
                            radius: 52,
                            backgroundImage: NetworkImage(_profileImageUrl!),
                          )
                        else
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                            ),
                          ),
                        // Edit icon on profile pic
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: _uploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppTheme.textMid, fontSize: 14)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(bio, style: const TextStyle(color: AppTheme.textMid, fontSize: 13), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 32),
                  
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('${_userData?['trips'] ?? 0}', 'Trips'),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _stat('${_userData?['places'] ?? 0}', 'Places'),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _stat('${_userData?['countries'] ?? 0}', 'Countries'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ),
                  const SizedBox(height: 12),
                  _tile(Icons.person_outline, 'Edit Profile', _editProfile),
                  _tile(Icons.lock_outline, 'Change Password', _changePassword),
                  _tile(Icons.info_outline, 'About WanderPlan', _showAboutWanderPlan),
                  const SizedBox(height: 8),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }

  Widget _stat(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
  ]);

  Widget _tile(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppTheme.textDark))),
        const Icon(Icons.chevron_right, color: AppTheme.textMid),
      ]),
    ),
  );
}