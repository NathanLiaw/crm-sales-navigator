import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 200,
                  height: 100,
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              const Text(
                'Increase your sales today.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Description
              const Text(
                'Transform the way you manage sales with CRM Sales Navigator, the ultimate app for sales professionals. With AI-powered tools and advanced features, this app is designed to help you close more deals, stay organized, and keep your clients satisfied. Whether you’re managing leads or placing orders on the go, CRM Sales Navigator provides everything you need for sales success, right at your fingertips.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Key Features Header
              const Text(
                'Key Features:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0175FF)),
              ),
              const SizedBox(height: 8),
              // Features List
              _buildFeatureCard('Automated Lead Management',
                  'Discover the opportunities that matter most with our automated lead creation system. Streamline your sales process by automatically generating leads, allowing you to focus on high-potential opportunities and maximize your efficiency.'),
              _buildFeatureCard('Sales Order Tracking',
                  'Keep track of all your sales orders in real-time. Get instant updates on order status, so you never miss a beat.'),
              _buildFeatureCard('Task Reminders & Notifications',
                  'Stay on top of your deadlines and tasks. The app automatically sends reminders and notifications for upcoming tasks, order updates, and lead changes.'),
              _buildFeatureCard('Advanced Search & Filters',
                  'Quickly find what you need with powerful search and filter tools. Sort through leads, orders, or products by multiple criteria, so you always have the right information at hand.'),
              _buildFeatureCard('Product Catalogue',
                  'Access the latest products on the go. Browse your product catalog anytime, anywhere, and stay updated with the most current offerings.'),
              _buildFeatureCard('Place Orders Instantly',
                  'Close deals faster by placing orders on the spot for your clients. No need to wait—submit orders directly through the app, ensuring quick and seamless transactions.'),
              _buildFeatureCard('Customer Insights',
                  'Gain a deeper understanding of your customers with our robust analytics. Access detailed customer insights to tailor your sales strategy and build stronger relationships.'),
              const SizedBox(height: 16),
              // Conclusion
              const Text(
                'With CRM Sales Navigator, you have everything you need to manage your leads, track orders, and keep clients happy—all from the convenience of your mobile device. Download today and take your sales game to the next level!',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build each feature card
  Widget _buildFeatureCard(String title, String description) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
