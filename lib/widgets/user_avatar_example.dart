import 'package:flutter/material.dart';
import 'user_avatar.dart';

class UserAvatarExample extends StatelessWidget {
  const UserAvatarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Avatar Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Avatar Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Example 1: With photo
            const Text(
              'With Profile Photo:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(
                  radius: 30,
                  photoURL: 'https://example.com/photo.jpg',
                  displayName: 'John Doe',
                  email: 'john@example.com',
                ),
                const SizedBox(width: 16),
                const Text('John Doe (with photo)'),
              ],
            ),
            const SizedBox(height: 20),

            // Example 2: Without photo, with name
            const Text(
              'Without Photo, With Name:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(
                  radius: 30,
                  displayName: 'Jane Smith',
                  email: 'jane@example.com',
                ),
                const SizedBox(width: 16),
                const Text('Jane Smith (shows "JS")'),
              ],
            ),
            const SizedBox(height: 20),

            // Example 3: Without photo, with email only
            const Text(
              'Without Photo, Email Only:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(radius: 30, email: 'user@example.com'),
                const SizedBox(width: 16),
                const Text('user@example.com (shows "U")'),
              ],
            ),
            const SizedBox(height: 20),

            // Example 4: Custom styling
            const Text(
              'Custom Styling:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(
                  radius: 30,
                  displayName: 'Custom User',
                  backgroundColor: Colors.purple,
                  textColor: Colors.white,
                  borderColor: Colors.purple.shade300,
                  borderWidth: 3,
                ),
                const SizedBox(width: 16),
                const Text('Custom User (purple theme)'),
              ],
            ),
            const SizedBox(height: 20),

            // Example 5: Different sizes
            const Text(
              'Different Sizes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                UserAvatar(radius: 20, displayName: 'Small'),
                const SizedBox(width: 16),
                UserAvatar(radius: 30, displayName: 'Medium'),
                const SizedBox(width: 16),
                UserAvatar(radius: 40, displayName: 'Large'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
