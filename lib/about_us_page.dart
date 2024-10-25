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
              Container(
                padding: const EdgeInsets.only(top: 20, left: 70),
                margin: const EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 200,
                  height: 100,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Increase your sales today.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transform the way you manage sales with CRM Sales Navigator, the ultimate app for sales professionals. With AI-powered tools and advanced features, this app is designed to help you close more deals, stay organized, and keep your clients satisfied. Whether you’re managing leads or placing orders on the go, CRM Sales Navigator provides everything you need for sales success, right at your fingertips.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Key Features:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Automated Lead Management: Discover the opportunities that matter most with our automated lead creation system. Streamline your sales process by automatically generating leads, allowing you to focus on high-potential opportunities and maximize your efficiency.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Sales Order Tracking: Keep track of all your sales orders in real-time. Get instant updates on order status, so you never miss a beat.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '3. Task Reminders & Notifications: Stay on top of your deadlines and tasks. The app automatically sends reminders and notifications for upcoming tasks, order updates, and lead changes.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '4. Advanced Search & Filters: Quickly find what you need with powerful search and filter tools. Sort through leads, orders, or products by multiple criteria, so you always have the right information at hand.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '5. Product Catalogue: Access the latest products on the go. Browse your product catalog anytime, anywhere, and stay updated with the most current offerings.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '6. Place Orders Instantly: Close deals faster by placing orders on the spot for your clients. No need to wait—submit orders directly through the app, ensuring quick and seamless transactions.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '7. Customer Insights: Gain a deeper understanding of your customers with our robust analytics. Access detailed customer insights to tailor your sales strategy and build stronger relationships.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
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
}
