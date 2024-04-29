import 'package:flutter/material.dart';

class TermsandConditions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'Welcome to FYH Online Store',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Terms and conditions stated below apply to all visitors and users of FYH Online Store website. You are bound by these terms and conditions as long as you are on fyhstore.com.my.',
            ),
            Divider(
              color: Colors.grey, // Customize the color of the divider
              thickness: 1.0, // Set the thickness of the divider
              height: 20.0, // Set the height of the divider
            ),
            SizedBox(height: 16),
            Text(
              'General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'The content of terms and conditions may be changed, moved, or deleted at any time. Please be informed that Fong Yuan Hung Imp & Exp Sdn Bhd has the rights to change contents of the terms without any notice. Immediate actions against offender(s) for violating or breaching any rules & regulations stated in the terms.',
            ),
            Divider(
              color: Colors.grey, // Customize the color of the divider
              thickness: 1.0, // Set the thickness of the divider
              height: 20.0, // Set the height of the divider
            ),
            SizedBox(height: 16),
            Text(
              'Site Contents & Copyrights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Unless otherwise stated, all materials including images, illustrations, designs, icons, photographs, video clips, written materials, and other materials that appear as part of this site (in other words, "Contents of Site") are copyrights, trademarks, trade dress, or other intellectual properties owned, controlled, or licensed by Fong Yuan Hung Imp & Exp Sdn Bhd.',
            ),
          ],
        ),
      ),
    );
  }
}
