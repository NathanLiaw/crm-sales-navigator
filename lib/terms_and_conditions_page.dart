import 'package:flutter/material.dart';

class TermsandConditions extends StatelessWidget {
  const TermsandConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Welcome to Sales Navigator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0175FF),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The following terms and conditions apply to all visitors and users '
                    'of the Sales Navigator application. By using the app, you agree to be '
                    'bound by these terms as long as you are utilizing Sales Navigator.',
                style: TextStyle(fontSize: 16),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1.0,
                height: 20.0,
              ),
              SizedBox(height: 16),
              Text(
                'General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0175FF),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The content of these terms and conditions may be updated, modified, or '
                    'removed at any time. Please note that Sales Navigator reserves the right '
                    'to alter these terms without prior notice. Immediate action may be taken '
                    'against any user who violates or breaches the rules and regulations outlined herein.',
                style: TextStyle(fontSize: 16),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1.0,
                height: 20.0,
              ),
              SizedBox(height: 16),
              Text(
                'App Contents & Copyrights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0175FF),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Unless otherwise stated, all materials including images, illustrations, '
                    'designs, icons, photographs, video clips, written materials, and other content '
                    'that appear as part of this application (collectively referred to as "Contents") are '
                    'copyrighted, trademarked, or otherwise protected intellectual properties owned, '
                    'controlled, or licensed by Sales Navigator.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
