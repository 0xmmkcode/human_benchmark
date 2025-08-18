import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_logger.dart';
import '../../models/user_profile.dart';
import '../../models/user_score.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  bool _isLoading = false;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  String _sortBy = 'lastActive';
  bool _sortAscending = false;
  int _currentPage = 0;
  final int _usersPerPage = 20;

  // User detail modal
  Map<String, dynamic>? _selectedUser;
  bool _showUserModal = false;
  bool _isLoadingUserDetails = false;
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });

      if (isAdmin) {
        await _loadUsers();
      }
    } catch (e) {
      AppLogger.error('admin.checkAdminStatus', e);
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Get users from both collections
      final usersSnapshot = await firestore.collection('users').get();
      final userScoresSnapshot = await firestore
          .collection('user_scores')
          .get();

      final List<Map<String, dynamic>> allUsers = [];

      // Process users collection
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        allUsers.add({
          'uid': doc.id,
          'email': data['email'] ?? 'No email',
          'displayName': data['displayName'] ?? 'Unknown User',
          'photoURL': data['photoURL'],
          'createdAt': data['createdAt'],
          'lastActive': data['lastActive'],
          'totalGames': data['totalGames'] ?? 0,
          'migrationCompleted': data['migrationCompleted'] ?? false,
          'source': 'users',
        });
      }

      // Process user_scores collection (legacy users not yet migrated)
      for (final doc in userScoresSnapshot.docs) {
        final data = doc.data();
        // Check if user already exists in users collection
        if (!allUsers.any((user) => user['uid'] == doc.id)) {
          allUsers.add({
            'uid': doc.id,
            'email': data['email'] ?? 'No email',
            'displayName': data['displayName'] ?? 'Unknown User',
            'photoURL': data['photoURL'],
            'createdAt': data['createdAt'],
            'lastActive': data['lastActive'],
            'totalGames': data['totalGames'] ?? 0,
            'migrationCompleted': false,
            'source': 'user_scores',
          });
        }
      }

      // Sort users by last active
      allUsers.sort((a, b) {
        final aTime = a['lastActive'] as Timestamp?;
        final bTime = b['lastActive'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Most recent first
      });

      setState(() {
        _users = allUsers;
        _filteredUsers = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('admin.loadUsers', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers = _users.where((user) {
        final query = _searchQuery.toLowerCase();
        return user['email'].toString().toLowerCase().contains(query) ||
            user['displayName'].toString().toLowerCase().contains(query) ||
            user['uid'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _sortUsers(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = true;
      }

      _filteredUsers.sort((a, b) {
        dynamic aValue = a[field];
        dynamic bValue = b[field];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;

        int comparison;
        if (aValue is Timestamp && bValue is Timestamp) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Future<void> _viewUserDetails(String uid) async {
    setState(() {
      _selectedUser = _users.firstWhere((user) => user['uid'] == uid);
      _showUserModal = true;
      _isLoadingUserDetails = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Get user profile
      final userDoc = await firestore.collection('users').doc(uid).get();
      final userScoresDoc = await firestore
          .collection('user_scores')
          .doc(uid)
          .get();

      // Get game scores
      final gameScoresSnapshot = await firestore
          .collection('game_scores')
          .where('userId', isEqualTo: uid)
          .orderBy('playedAt', descending: true)
          .limit(50)
          .get();

      // Get personality results
      final personalitySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('personalityResults')
          .limit(10)
          .get();

      final Map<String, dynamic> details = {
        'profile': userDoc.exists ? userDoc.data() : null,
        'legacyScores': userScoresDoc.exists ? userScoresDoc.data() : null,
        'gameScores': gameScoresSnapshot.docs.map((doc) => doc.data()).toList(),
        'personalityResults': personalitySnapshot.docs
            .map((doc) => doc.data())
            .toList(),
        'totalGameScores': gameScoresSnapshot.docs.length,
        'hasPersonalityResults': personalitySnapshot.docs.isNotEmpty,
      };

      setState(() {
        _userDetails = details;
        _isLoadingUserDetails = false;
      });
    } catch (e) {
      AppLogger.error('admin.viewUserDetails', e);
      setState(() {
        _isLoadingUserDetails = false;
      });
    }
  }

  Future<void> _deleteUser(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user $uid? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Delete from users collection
      await firestore.collection('users').doc(uid).delete();

      // Delete from user_scores collection
      await firestore.collection('user_scores').doc(uid).delete();

      // Delete game scores
      final gameScoresSnapshot = await firestore
          .collection('game_scores')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in gameScoresSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete personality results
      final personalitySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('personalityResults')
          .get();

      for (final doc in personalitySnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove from local lists
      setState(() {
        _users.removeWhere((user) => user['uid'] == uid);
        _filteredUsers.removeWhere((user) => user['uid'] == uid);
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User $uid deleted successfully')));
    } catch (e) {
      AppLogger.error('admin.deleteUser', e);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
    }
  }

  Future<void> _updateUser(String uid) async {
    final user = _users.firstWhere((u) => u['uid'] == uid);

    final TextEditingController emailController = TextEditingController(
      text: user['email'],
    );
    final TextEditingController displayNameController = TextEditingController(
      text: user['displayName'],
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop({
              'email': emailController.text,
              'displayName': displayNameController.text,
            }),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Update in users collection
      await firestore.collection('users').doc(uid).update({
        'email': result['email'],
        'displayName': result['displayName'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in user_scores collection if exists
      final userScoresDoc = await firestore
          .collection('user_scores')
          .doc(uid)
          .get();
      if (userScoresDoc.exists) {
        await userScoresDoc.reference.update({
          'email': result['email'],
          'displayName': result['displayName'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local data
      setState(() {
        final userIndex = _users.indexWhere((u) => u['uid'] == uid);
        if (userIndex != -1) {
          _users[userIndex]['email'] = result['email'];
          _users[userIndex]['displayName'] = result['displayName'];
        }

        final filteredIndex = _filteredUsers.indexWhere((u) => u['uid'] == uid);
        if (filteredIndex != -1) {
          _filteredUsers[filteredIndex]['email'] = result['email'];
          _filteredUsers[filteredIndex]['displayName'] = result['displayName'];
        }

        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } catch (e) {
      AppLogger.error('admin.updateUser', e);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update user: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Text(
                'Admin Users',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage user accounts and permissions.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // Access Denied
              Center(
                child: Column(
                  children: [
                    Icon(Icons.block, size: 80, color: Colors.red[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin privileges required.',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Column(
            children: [
              // Search and Filter Bar
              _buildSearchAndFilterBar(),

              // Users Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUsersTable(),
              ),

              // Pagination
              _buildPagination(),
            ],
          ),

          // User Details Modal
          if (_showUserModal && _selectedUser != null)
            UserDetailsModal(
              user: _selectedUser!,
              userDetails: _userDetails,
              isLoading: _isLoadingUserDetails,
              onClose: () {
                setState(() {
                  _showUserModal = false;
                  _selectedUser = null;
                  _userDetails = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text(
            'Admin Users',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage user accounts and permissions.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Search and Filter Controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users by email, name, or UID...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                    _filterUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _sortBy,
                hint: const Text('Sort by'),
                items: [
                  DropdownMenuItem(
                    value: 'lastActive',
                    child: const Text('Last Active'),
                  ),
                  DropdownMenuItem(
                    value: 'createdAt',
                    child: const Text('Created'),
                  ),
                  DropdownMenuItem(
                    value: 'totalGames',
                    child: const Text('Total Games'),
                  ),
                  DropdownMenuItem(value: 'email', child: const Text('Email')),
                  DropdownMenuItem(
                    value: 'displayName',
                    child: const Text('Name'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _sortUsers(value);
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                  _sortUsers(_sortBy);
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: 'Sort direction',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final startIndex = _currentPage * _usersPerPage;
    final endIndex = (startIndex + _usersPerPage).clamp(
      0,
      _filteredUsers.length,
    );
    final pageUsers = _filteredUsers.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: const Text('User'),
            onSort: (columnIndex, ascending) => _sortUsers('displayName'),
          ),
          DataColumn(
            label: const Text('Email'),
            onSort: (columnIndex, ascending) => _sortUsers('email'),
          ),
          DataColumn(
            label: const Text('Games'),
            onSort: (columnIndex, ascending) => _sortUsers('totalGames'),
          ),
          DataColumn(
            label: const Text('Last Active'),
            onSort: (columnIndex, ascending) => _sortUsers('lastActive'),
          ),
          DataColumn(label: const Text('Status')),
          DataColumn(label: const Text('Actions')),
        ],
        rows: pageUsers.map((user) {
          final lastActive = user['lastActive'] as Timestamp?;
          final createdAt = user['createdAt'] as Timestamp?;
          final isMigrated = user['migrationCompleted'] == true;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user['photoURL'] != null
                          ? NetworkImage(user['photoURL'])
                          : null,
                      child: user['photoURL'] == null
                          ? Text(user['displayName'][0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user['displayName'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(user['email'], overflow: TextOverflow.ellipsis)),
              DataCell(Text(user['totalGames'].toString())),
              DataCell(
                Text(
                  lastActive != null ? _formatTimestamp(lastActive) : 'Never',
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMigrated ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMigrated ? 'Migrated' : 'Legacy',
                    style: TextStyle(
                      color: isMigrated
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _viewUserDetails(user['uid']),
                      icon: const Icon(Icons.visibility, size: 20),
                      tooltip: 'View Details',
                    ),
                    IconButton(
                      onPressed: () => _updateUser(user['uid']),
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit User',
                    ),
                    IconButton(
                      onPressed: () => _deleteUser(user['uid']),
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      tooltip: 'Delete User',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredUsers.length / _usersPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${_currentPage + 1} of $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// User Details Modal
class UserDetailsModal extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? userDetails;
  final bool isLoading;
  final VoidCallback onClose;

  const UserDetailsModal({
    super.key,
    required this.user,
    required this.userDetails,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user['photoURL'] != null
                      ? NetworkImage(user['photoURL'])
                      : null,
                  child: user['photoURL'] == null
                      ? Text(
                          user['displayName'][0].toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['displayName'],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user['email'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'UID: ${user['uid']}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (userDetails != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserStats(userDetails!),
                      const SizedBox(height: 24),
                      _buildGameHistory(userDetails!),
                      const SizedBox(height: 24),
                      _buildPersonalityResults(userDetails!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats(Map<String, dynamic> details) {
    final profile = details['profile'] as Map<String, dynamic>?;
    final legacyScores = details['legacyScores'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Games',
                    details['totalGameScores'].toString(),
                    Icons.games,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Personality Tests',
                    details['hasPersonalityResults'] ? 'Yes' : 'No',
                    Icons.psychology,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Migration Status',
                    profile != null ? 'Migrated' : 'Legacy',
                    Icons.sync,
                    profile != null ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameHistory(Map<String, dynamic> details) {
    final gameScores = details['gameScores'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Game History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (gameScores.isEmpty)
              const Text('No game history available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gameScores.length,
                itemBuilder: (context, index) {
                  final game = gameScores[index];
                  return ListTile(
                    leading: Icon(_getGameIcon(game['gameType'] ?? 'unknown')),
                    title: Text(game['gameType'] ?? 'Unknown Game'),
                    subtitle: Text('Score: ${game['score']}'),
                    trailing: Text(
                      _formatGameTimestamp(game['playedAt']),
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityResults(Map<String, dynamic> details) {
    final personalityResults = details['personalityResults'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personality Test Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (personalityResults.isEmpty)
              const Text('No personality test results available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: personalityResults.length,
                itemBuilder: (context, index) {
                  final result = personalityResults[index];
                  return ListTile(
                    leading: const Icon(Icons.psychology),
                    title: Text('Test ${index + 1}'),
                    subtitle: Text(
                      'Completed: ${_formatGameTimestamp(result['completedAt'])}',
                    ),
                    trailing: Text('Score: ${result['totalScore'] ?? 'N/A'}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'reaction_time':
        return Icons.timer;
      case 'number_memory':
        return Icons.memory;
      case 'decision_making':
        return Icons.speed;
      case 'personality':
        return Icons.psychology;
      default:
        return Icons.games;
    }
  }

  String _formatGameTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final time = timestamp.toDate();
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}';
    }
    return 'Unknown';
  }
}
