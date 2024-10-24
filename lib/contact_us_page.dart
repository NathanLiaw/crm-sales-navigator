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
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quest Marketing Kuching',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No. 137, A, Jalan Green,',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '93150 Kuching, Sarawak, Malaysia.',
                style: TextStyle(fontSize: 16),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1.0,
                height: 20.0,
              ),
              SizedBox(height: 16),
              Text(
                'TEL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('+6082-231 390, +60 16-878 6891'),
              SizedBox(height: 8),
              Text(
                'FAX:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('+6082-231 390'),
              SizedBox(height: 8),
              Text(
                'EMAIL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('questmarketingkch@gmail.com'),
              SizedBox(height: 16),
              Divider(
                color: Colors.grey,
                thickness: 1.0,
                height: 20.0,
              ),
              Text(
                'BUSINESS HOURS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('MONDAY - FRIDAY: 8AM - 5PM'),
              Text('SATURDAY: 8AM - 12.30PM'),
              Text('SUNDAY: CLOSED'),
              Text('PUBLIC HOLIDAY: CLOSED'),
            ],
          ),
        ),
      ),
    );
  }
}
