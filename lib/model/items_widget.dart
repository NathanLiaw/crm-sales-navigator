import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mysql1/mysql1.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/item_screen.dart';

class ItemsWidget extends StatelessWidget {
  Future<List<String>> getProductNames() async {
    final conn = await connectToDatabase();
    final results =
        await conn.query('SELECT product_name FROM product WHERE status = 1');
    await conn.close();

    return results.map((row) => row['product_name'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getProductNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final productNames = snapshot.data ?? [];

        return SingleChildScrollView(
          child: GridView.count(
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 0.68,
            crossAxisCount: 2,
            shrinkWrap: true,
            children: productNames.map((productName) {
              return Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Navigate to the item_screen.dart page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ItemScreen()),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 1,
                            color: Color.fromARGB(255, 0, 76, 135),
                          ),
                        ),
                        child: Image.asset(
                          'assets/photos/5dbcdd7610b2d.jpg', // Use photo1 here
                          height: 166,
                          width: 166,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  productName, // Display product name
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 25, 23, 49),
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            iconSize: 28,
                            onPressed: () {},
                            icon: const Icon(Icons.thumb_up_alt_outlined),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Product Sub", // You can update this as needed
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
