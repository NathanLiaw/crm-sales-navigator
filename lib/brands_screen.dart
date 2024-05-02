import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/brand_data.dart';
import 'package:sales_navigator/db_connection.dart';

class BrandScreen extends StatefulWidget {
  @override
  _BrandScreenState createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  late List<BrandData> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final conn = await connectToDatabase();
    _brands = await fetchBrands(conn);
    await conn.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Brands',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: _brands.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _brands.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        _brands[index].brand,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        // Handle brand selection
                        // You can navigate to a new screen or perform any desired action
                        Navigator.pop(context, _brands[index].id);
                        print('Selected brand: ${_brands[index].brand}');
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
