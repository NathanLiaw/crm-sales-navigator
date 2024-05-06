import 'package:flutter/material.dart';

class ContactUs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff004c87),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: Text(
          'Contact Us',
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
            Text(
              'Fong Yuan Hung Imp and Exp Sdn Bhd (622210-M)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No.7, Lorong 1, Muara Tabuan Light Industrial Estate,',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Off Jalan Setia Raja, 93450, Kuching, Sarawak,',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Malaysia.',
              style: TextStyle(fontSize: 16),
            ),
            Divider(
              color: Colors.grey, // Customize the color of the divider
              thickness: 1.0, // Set the thickness of the divider
              height: 20.0, // Set the height of the divider
            ),
            SizedBox(height: 16),
            Text(
              'TEL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('+60-82362333, 3626666, 362999'),
            SizedBox(height: 8),
            Text(
              'FAX:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('+60-82365180, 3630302, 370227'),
            SizedBox(height: 8),
            Text(
              'EMAIL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('FYHKCH@HOTMAIL.COM'),
            SizedBox(height: 16),
            Divider(
              color: Colors.grey, // Customize the color of the divider
              thickness: 1.0, // Set the thickness of the divider
              height: 20.0, // Set the height of the divider
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
    );
  }
}
