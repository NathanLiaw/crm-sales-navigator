import 'package:flutter/material.dart';

class EditItemPage extends StatefulWidget {
  const EditItemPage({Key? key}) : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Edit Item',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Image
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // Replace the child with your actual image widget
                          child: Icon(Icons.image, size: 60, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16.0),
                        // Right side: Name and Description
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item Name',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Item Description',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Text fields for Reprice and Discount
                    const Row(
                      children: [
                        // Reprice field
                        Text(
                          'Unit Price (RM)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.0), // Spacer
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '333.000',
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    const Row(
                      children: [
                        // Discount field
                        Text(
                          'Discount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 50.0), // Spacer
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '0%',
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle button 1 press
                    print('Button 1 pressed');
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0), // Adjust button padding
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the width and height of Button 1
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 46.0), // Adjust the spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    // Handle button 2 press
                    print('Button 2 pressed');
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0), // Adjust button padding
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the width and height of Button 2
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff0069ba)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0), // Adjust border radius
                      ),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
