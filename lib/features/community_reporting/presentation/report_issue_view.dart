import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartsan_app/app.dart';
import 'package:smartsan_app/main.dart';
import 'dart:io';
import 'package:smartsan_app/services/report_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb check and platform-specific file handling

void main() {
  runApp(const CommunityApp());
}

class CommunityApp extends StatelessWidget {
  const CommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Clean',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainHomePage(),
    );
  }
}

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Impact',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const ReportIssuePage();
      case 1:
        return const ImpactPage();
      case 2:
        return const AchievementsPage();
      default:
        return const ReportIssuePage();
    }
  }
}

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  // Service instance
  final ReportService _reportService = ReportService();
  
  // State variables
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  String? _selectedCategory;
  String? _selectedPriority;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<String, String> _categories = {
    'Overflowing': 'Overflowing bins or containers',
    'Illegal Littering': 'Illegal dumping or littering',
    'Damaged Infrastructure': 'Damaged public infrastructure',
    'Blocked Drainage': 'Blocked drains or waterways',
    'Other': 'Other issues',
  };

  final List<String> _prioritiesList = [
    "Low - Can wait",
    "Medium - Address soon",
    "High - Urgent"

  ];

  // --- NEW: Image Upload Function ---
  Future<String?> _uploadImageToStorage(XFile file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      
      // Create a unique path for the image (e.g., reports/timestamp_filename)
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final imageRef = storageRef.child('reports/$fileName');

      // Platform specific upload: web uses bytes, mobile/desktop uses file path
      SettableMetadata? metadata;
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        metadata = SettableMetadata(contentType: file.mimeType);
        uploadTask = imageRef.putData(bytes, metadata);
      } else {
        uploadTask = imageRef.putFile(File(file.path));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;

    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${e.message}')),
        );
      }
      return null;
    }
  }
  
  // --- EXISTING: Image Picker ---
  Future<void> _pickImage() async {
    try {
      // NOTE: This existing logic only allows one image at a time, but the list supports multiple.
      // We will only upload the *first* selected image in the submit logic for now.
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.clear(); // Clear old ones if only one is allowed
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // --- NEW: Report Submission Logic ---
  void _submitReport() async {
    // 1. Basic validation
    if (_selectedCategory == null || _selectedPriority == null || _selectedImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category, priority, and at least one photo.')),
        );
      }
      return;
    }
    
    if (_locationController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in the location and description.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Upload the primary image
      final imageUrl = await _uploadImageToStorage(_selectedImages.first);
      
      if (imageUrl == null) {
        // Image upload failed, error already shown
        return;
      }

      // 3. Extract data for Cloud Function
      final priority = _selectedPriority!.split(' - ').first; // Extracts "Low", "Medium", or "High"
      
      // NOTE: Replace these placeholder coordinates with actual location data from a geolocation package
      const double placeholderLat = 34.0522; 
      const double placeholderLng = -118.2437; 
      
      // Call the Report Service, which executes the 'submitReport' Cloud Function
      await _reportService.submitReport(
        description: _descriptionController.text.trim(),
        category: _selectedCategory!, // You need to update ReportService to accept category
        priority: priority, // You need to update ReportService to accept priority
        imageUrl: imageUrl,
        locationString: _locationController.text.trim(), // You need to update ReportService to accept locationString
        lat: placeholderLat, 
        lng: placeholderLng,
      );

      // 4. Success handling
      _showSubmissionSuccessDialog();

    } catch (e) {
      // 5. Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed. Check your network or permissions.')),
        );
      }
    } finally {
      // 6. Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to show success dialog and clear the form
  void _showSubmissionSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Submitted'),
        content: const Text('Thank you! Your report is being processed for AI prioritization.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear form
              setState(() {
                _selectedCategory = null;
                _selectedPriority = null;
                _locationController.clear();
                _descriptionController.clear();
                _selectedImages.clear();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {
          // NOTE: Ensure 'DashBoard()' is correctly imported and available.
          Navigator.push(context, MaterialPageRoute(builder: (context) => DashBoard())); 
        }, icon: Icon(Icons.arrow_back)),
        title: const Text('Report an Issue'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help keep your community clean and earn rewards',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submit a Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Issue Category
            const Text(
              'Issue Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                hintText: 'Select category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _categories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Location
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter or select location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Priority Level
            const Text(
              'Priority Level',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                hintText: 'Select priority',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _prioritiesList.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Add Photos
            const Text(
              'Add Photos (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    const Text(
                      'Click to upload or drag and drop',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PNG, JPG up to 10MB',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Selected Images
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          // Use FileImage for mobile/desktop, or NetworkImage for web after upload
                          image: DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(image.path) as ImageProvider<Object>
                                : FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Disable button when loading
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, 
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ImpactPage extends StatelessWidget {
  const ImpactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Impact'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Points and Level
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Total Points',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '245',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Level Progress
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level 3',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '245/300',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 245 / 300,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '55 points to Level 4',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Reports Submitted', '24', Icons.description),
                    const Divider(),
                    _buildStatRow('Issues Resolved', '18', Icons.check_circle),
                    const Divider(),
                    _buildStatRow('Current Streak', '7 days', Icons.local_fire_department),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  _ActivityItem(
                    title: 'Illegal Littering Report',
                    points: '+10 points',
                    time: '2 hours ago',
                  ),
                  _ActivityItem(
                    title: 'Overflowing Bin Resolved',
                    points: '+15 points',
                    time: '1 day ago',
                  ),
                  _ActivityItem(
                    title: 'Damaged Infrastructure Report',
                    points: '+10 points',
                    time: '2 days ago',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String points;
  final String time;

  const _ActivityItem({
    required this.title,
    required this.points,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.eco, color: Colors.green[700]),
        ),
        title: Text(title),
        subtitle: Text(time),
        trailing: Text(
          points,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Achievements'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Achievements List
            Expanded(
              child: ListView(
                children: const [
                  AchievementCard(
                    title: 'Community Hero',
                    description: '10 reports in a week',
                    icon: Icons.people,
                    achieved: true,
                  ),
                  AchievementCard(
                    title: 'Early Reporter',
                    description: 'First to report an issue',
                    icon: Icons.access_time,
                    achieved: true,
                  ),
                  AchievementCard(
                    title: 'Clean Streak',
                    description: 'Report for 30 consecutive days',
                    icon: Icons.local_fire_department,
                    achieved: false,
                  ),
                  AchievementCard(
                    title: 'Issue Solver',
                    description: 'Get 50 issues resolved',
                    icon: Icons.check_circle,
                    achieved: false,
                  ),
                  AchievementCard(
                    title: 'Community Leader',
                    description: 'Reach Level 5',
                    icon: Icons.leaderboard,
                    achieved: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool achieved;

  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      color: achieved ? Colors.green[50] : Colors.grey[100],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: achieved ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          radius: 24,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: achieved ? Colors.green[800] : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: achieved ? Colors.green[600] : Colors.grey[500],
          ),
        ),
        trailing: achieved
            ? const Icon(Icons.verified, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}