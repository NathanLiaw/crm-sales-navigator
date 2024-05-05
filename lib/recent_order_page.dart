import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/db_connection.dart';

class RecentOrder extends StatefulWidget {
  @override
  _RecentOrderState createState() => _RecentOrderState();
}

class _RecentOrderState extends State<RecentOrder> {
  bool _isGridView = false;
  int _userId = 0; // Default user ID
  bool _isAscending = true; // Track sorting order

  // Define sorting methods
  final List<String> _sortingMethods = [
    'By Name (A to Z)',
    'By Name (Z to A)',
    'Uploaded Date (Old to New)',
    'Uploaded Date (New to Old)',
    'By Price (Low to High)',
    'By Price (High to Low)'
  ];

  // Selected sorting method
  String _selectedMethod = 'By Name (A to Z)';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  void _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('id') ?? 0; // Default to 0 if userId is not found
    setState(() {
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0069BA),
        title: Text(
          'Recent Order',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.sort),
                      onPressed: () {
                        _showSortingOptions(context);
                      },
                    ),
                    Text(_selectedMethod),
                  ],
                ),
                IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  // Show sorting options
  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _sortingMethods.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_sortingMethods[index]),
              onTap: () {
                setState(() {
                  _selectedMethod = _sortingMethods[index];
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No recent orders found.'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildListItem(item);
            },
          );
        }
      },
    );
  }

  Widget _buildGridView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No recent orders found.'));
        } else {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildGridItem(item);
            },
          );
        }
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return FutureBuilder<String>(
      future: _fetchProductPhoto(item['product_name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // photo part
                    Container(
                      margin: EdgeInsets.only(right: 16),
                      child: Image.asset(
                        snapshot.data!,
                        width: 100,
                        height: 100,
                      ),
                    ),
                    // text part
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow:
                                TextOverflow.ellipsis, // Add overflow handling
                            maxLines: 2, // Display up to two lines
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigateToItemScreen(item['product_name']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff0069BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      'View Item',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // No photo found for the product
          return Container(); // Return an empty container
        }
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return FutureBuilder<String>(
      future: _fetchProductPhoto(item['product_name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  snapshot.data!,
                  width: 70,
                  height: 70,
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'],
                        style: TextStyle(
                          // fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Add overflow handling
                        maxLines: 1, // Display up to two lines
                      ),
                      // SizedBox(height: 8),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle "View Item" button click
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(20, 30),
                    backgroundColor: Color(0xff0069BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child:
                      Text('View Item', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          // No photo found for the product
          return Container(); // Return an empty container
        }
      },
    );
  }

  void _navigateToItemScreen(String selectedProductName) async {
    MySqlConnection conn = await connectToDatabase();

    try {
      final productData = await readData(
        conn,
        'product',
        'status = 1 AND product_name = "$selectedProductName"',
        '',
        'id, product_name, photo1, description, sub_category, price_by_uom',
      );

      if (productData.isNotEmpty) {
        Map<String, dynamic> product = productData.first;

        int productId = product['id'];
        String productName = product['product_name'];
        String itemAssetName = product['photo1'];
        Blob description = stringToBlob(product['description']);
        String priceByUom = product['price_by_uom'];

        // Navigate to ItemScreen and pass necessary parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              productId: productId,
              productName: productName,
              itemAssetName: itemAssetName,
              itemDescription: description,
              priceByUom: priceByUom,
            ),
          ),
        );
      } else {
        print('Product not found for name: $selectedProductName');
      }
    } catch (e) {
      print('Error fetching product details: $e');
    } finally {
      await conn.close();
    }
  }

  Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
  }

  Future<List<Map<String, dynamic>>> _fetchRecentOrders() async {
    try {
      MySqlConnection conn = await connectToDatabase();
      // final results = await readData(
      //   conn,
      //   'cart c JOIN cart_item ci ON ci.session = c.session',
      //   'ci.buyer_id = $_userId AND c.buyer_user_group = "salesman"',
      //   '',
      //   'DISTINCT ci.product_id, ci.product_name', // Fetch both product_id and product_name
      // );
      final results = await readData(
        conn,
        'cart c JOIN cart_item ci ON ci.session = c.session',
        'ci.buyer_id = $_userId AND c.buyer_user_group = "salesman" GROUP BY ci.product_name, ci.product_id',
        '',
        'ci.product_id, ci.product_name, SUM(ci.total) AS total',
      );

      await conn.close();

      // Sort the results based on the selected method
      if (_selectedMethod == 'By Name (A to Z)') {
        results.sort((a, b) {
          if (_isAscending) {
            return a['product_name'].compareTo(b['product_name']);
          } else {
            return b['product_name'].compareTo(a['product_name']);
          }
        });
      } else if (_selectedMethod == 'By Name (Z to A)') {
        results.sort((a, b) {
          if (_isAscending) {
            return b['product_name'].compareTo(a['product_name']);
          } else {
            return a['product_name'].compareTo(b['product_name']);
          }
        });
      } else if (_selectedMethod == 'Uploaded Date (Old to New)') {
        results.sort((a, b) {
          if (_isAscending) {
            return a['product_id'].compareTo(b['product_id']);
          } else {
            return b['product_id'].compareTo(a['product_id']);
          }
        });
      } else if (_selectedMethod == 'Uploaded Date (New to Old)') {
        results.sort((a, b) {
          if (_isAscending) {
            return b['product_id'].compareTo(a['product_id']);
          } else {
            return a['product_id'].compareTo(b['product_id']);
          }
        });
      } else if (_selectedMethod == 'By Price (Low to High)') {
        results.sort((a, b) {
          if (_isAscending) {
            return a['total'].compareTo(b['total']);
          } else {
            return b['total'].compareTo(a['total']);
          }
        });
      } else if (_selectedMethod == 'By Price (High to Low)') {
        results.sort((a, b) {
          if (_isAscending) {
            return b['total'].compareTo(a['total']);
          } else {
            return a['total'].compareTo(b['total']);
          }
        });
      }

      return results;
    } catch (e) {
      print('Error fetching recent orders: $e');
      return [];
    }
  }

  Future<String> _fetchProductPhoto(String productName) async {
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'product',
        'product_name = "$productName"',
        '',
        'photo1',
      );
      await conn.close();
      if (results.isNotEmpty && results[0]['photo1'] != null) {
        // Ensure photo1 is not null and has a value
        String photoPath = results[0]['photo1'];
        // Check if photoPath starts with "photo/" and replace it with "asset/photo/"
        if (photoPath.startsWith('photo/')) {
          photoPath = 'photo/' + photoPath.substring(6);
        }
        return photoPath;
      } else {
        // Return a default placeholder image path if no photo found or photo1 is null
        return 'asset/no_image.jpg';
      }
    } catch (e) {
      print('Error fetching product photo: $e');
      return 'asset/no_image.jpg'; // Return empty string if an error occurs
    }
  }
}
