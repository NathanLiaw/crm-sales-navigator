import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:sales_navigator/item_screen.dart';
import 'dart:developer' as developer;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  List<String> _searchResults = [];

  Future<void> _performSearch(String query) async {
    MySqlConnection conn = await connectToDatabase();

    try {
      List<String> conditions = [];

      // Step 1: Check if the search query matches any subcategory name
      final subCategoryResults = await conn.query(
        'SELECT id FROM sub_category WHERE sub_category LIKE ?',
        ['%$query%'],
      );

      if (subCategoryResults.isNotEmpty) {
        final subCategoryId = subCategoryResults.first.fields['id'] as int;
        conditions.add('p.sub_category = $subCategoryId');
      }

      // Step 2: Check if the search query matches any brand name
      final brandResults = await conn.query(
        'SELECT id FROM brand WHERE brand LIKE ?',
        ['%$query%'],
      );

      if (brandResults.isNotEmpty) {
        final brandId = brandResults.first.fields['id'] as int;
        conditions.add('p.brand = $brandId');

        // Add an additional condition to prioritize specific brand products
        // containing the search term
        conditions.add('p.product_name LIKE \'%$query%\'');
      }

      // Construct the WHERE clause based on the conditions
      String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' OR ')}' : '';

      // Step 3: Execute the final query based on the constructed conditions
      final results = await conn.query(
        '''
      SELECT p.product_name
      FROM product p
      $whereClause
      ORDER BY 
        CASE 
          WHEN p.product_name LIKE '$query%' THEN 1 
          ELSE 2
        END
      ''',
      );

      setState(() {
        _searchResults = results.map((result) => result['product_name'] as String).toList();
      });
    } catch (e) {
      developer.log('Error performing search: $e', error: e);
    } finally {
      await conn.close();
    }
  }

  void _onSearchTextChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _performSearch(query);
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

  Future<List<Map<String, dynamic>>> getProductData(String searchQuery) async {
    try {
      final conn = await connectToDatabase();
      final results = await conn.query(
        'SELECT id, product_name, photo1, description, sub_category, '
            'price_by_uom FROM product WHERE status = 1 AND product_name LIKE ?',
        ['%$searchQuery%'],
      );
      await conn.close();

      return results.map((row) {
        return {
          'id': row['id'],
          'product_name': row['product_name'],
          'photo1': row['photo1'],
          'description': row['description'],
          'sub_category': row['sub_category'],
          'price_by_uom': row['price_by_uom'],
        };
      }).toList();
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchTextChanged,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Perform search when the search button is pressed
              _performSearch(_searchQuery);
            },
          ),
        ],
      ),
      body: _searchResults.isEmpty
          ? Center(
        child: Text(
          _searchQuery.isEmpty ? 'Start typing to search' : 'No results found',
          style: const TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final productName = _searchResults[index];
          return ListTile(
            title: Text(productName),
            onTap: () {
              _navigateToItemScreen(productName);
            },
          );
        },
      ),
    );
  }
}