import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/item_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/db_connection.dart';
import 'dart:developer' as developer;

class RecentOrder extends StatefulWidget {
  const RecentOrder({
    super.key,
    required this.customerId,
  });

  final int customerId;
  @override
  _RecentOrderState createState() => _RecentOrderState();
}

class _RecentOrderState extends State<RecentOrder> {
  bool _isGridView = false;
  int _userId = 0;
  final bool _isAscending = true;
  int numberOfItems = 0;

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
    int userId = prefs.getInt('id') ?? 0;
    setState(() {
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        title: const Text(
          'Recent Order',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      icon: const Icon(Icons.sort),
                      onPressed: () {
                        _showSortingOptions(context);
                      },
                    ),
                    Text(_selectedMethod),
                    SizedBox(width: 10),
                    Text('$numberOfItems item(s)'),
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent orders found.'));
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent orders found.'));
        } else {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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
                      margin: const EdgeInsets.only(right: 16),
                      child: (snapshot.data != null && Uri.parse(snapshot.data!).isAbsolute) ?
                      Image.network(
                        snapshot.data!,
                        height: 100,
                        width: 100,
                      ) : Image.asset(
                        'asset/no_image.jpg',
                        height: 100,
                        width: 100,
                      ),
                    ),
                    // text part
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
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
                      backgroundColor: const Color(0xff0069BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
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
          return Container();
        }
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return FutureBuilder<String>(
      future: _fetchProductPhoto(item['product_name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (snapshot.data != null && Uri.parse(snapshot.data!).isAbsolute) ?
                Image.network(
                  snapshot.data!,
                  height: 70,
                  width: 70,
                ) : Image.asset(
                  'asset/no_image.jpg', // Correct the path to the asset folder
                  height: 70,
                  width: 70,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'],
                        style: const TextStyle(
                          // fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    minimumSize: const Size(20, 30),
                    backgroundColor: const Color(0xff0069BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child:
                      const Text('View Item', style: TextStyle(color: Colors.white)),
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
        List<String> itemAssetNames = [product['photo1'], product['photo2'], product['photo3'], product['photo4']];
        Blob description = stringToBlob(product['description']);
        String priceByUom = product['price_by_uom'];

        // Navigate to ItemScreen and pass necessary parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              productId: productId,
              productName: productName,
              itemAssetNames: itemAssetNames,
              itemDescription: description,
              priceByUom: priceByUom,
            ),
          ),
        );
      } else {
        developer.log('Product not found for name: $selectedProductName', level: 1);
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
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
      String condition = 'ci.buyer_id = $_userId AND c.buyer_user_group = "salesman" GROUP BY '
          'ci.product_name, ci.product_id';
      if (widget.customerId > 0){
        condition = 'ci.buyer_id = $_userId AND c.buyer_user_group = "salesman"'
            'AND ci.customer_id = ${widget.customerId} GROUP BY ci.product_name, ci.product_id';
      }
      final results = await readData(
        conn,
        'cart c JOIN cart_item ci ON ci.session = c.session OR ci.cart_id = c.id',
        condition,
        '',
        'ci.product_id, ci.product_name, SUM(ci.total) AS total',
      );

      numberOfItems = results.length;

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
      developer.log('Error fetching recent orders: $e', error: e);
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
          photoPath = 'https://haluansama.com/crm-sales/photo/${photoPath.substring(6)}';
        }
        return photoPath;
      } else {
        // Return a default placeholder image path if no photo found or photo1 is null
        return 'asset/no_image.jpg';
      }
    } catch (e) {
      developer.log('Error fetching product photo: $e', error: e);
      return 'asset/no_image.jpg';
    }
  }
}
