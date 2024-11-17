import 'package:flutter/material.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Quest Marketing Kuching',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xff0175FF),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No. 137, A, Jalan Green,',
                style: TextStyle(fontSize: 16),
              ),
              const Text(
                '93150 Kuching, Sarawak, Malaysia.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Contact Info Section
              const Text(
                'CONTACT US',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff0175FF),
                ),
              ),
              const SizedBox(height: 16),
              _buildContactInfo(Icons.phone, 'TEL:', '+6082-231 390, +60 16-878 6891'),
              _buildContactInfo(Icons.fax, 'FAX:', '+6082-231 390'),
              _buildContactInfo(Icons.email, 'EMAIL:', 'questmarketingkch@gmail.com'),
              const SizedBox(height: 16),

              // Business Hours Section
              const Divider(color: Colors.grey),
              const Text(
                'BUSINESS HOURS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xff0175FF),
                ),
              ),
              const SizedBox(height: 8),
              const Text('MONDAY - FRIDAY: 8AM - 5PM'),
              const Text('SATURDAY: 8AM - 12.30PM'),
              const Text('SUNDAY: CLOSED'),
              const Text('PUBLIC HOLIDAY: CLOSED'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build contact information section with icons
  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff0175FF), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
