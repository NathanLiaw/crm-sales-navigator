import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/brands_screen.dart';
import 'package:sales_navigator/categories_screen.dart';
import 'package:sales_navigator/filter_categories_screen.dart';
import 'package:sales_navigator/model/area_select_popup.dart';
import 'package:sales_navigator/search_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/category_button.dart';
import 'model/sort_popup.dart';
import 'model/items_widget.dart';
import 'db_connection.dart';
import 'dart:developer' as developer;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Map<int, String> area = {};
  static late int selectedAreaId;
  String searchQuery = '';
  static int? _selectedBrandId;
  int? _selectedSubCategoryId;
  String _currentSortOrder = 'By Name (A to Z)';

  Future<void> setAreaId(int areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('areaId', areaId);
    setState(() {
      selectedAreaId = areaId; // Update the selected area ID
    });
  }

  Future<void> fetchAreaFromDb() async {
    Map<int, String> areaMap = {};
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'area',
        'status=1',
        '',
        'id, area',
      );
      await conn.close();

      areaMap = Map.fromEntries(results.map((row) => MapEntry<int, String>(
        row['id'],
        row['area'] ?? '',
      )));

      setState(() {
        area = areaMap;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedAreaId = prefs.getInt('areaId');

      if (storedAreaId != null && areaMap.containsKey(storedAreaId)) {
        setState(() {
          selectedAreaId = storedAreaId;
        });
      } else if (areaMap.isNotEmpty) {
        setState(() {
          selectedAreaId = areaMap.keys.first;
          prefs.setInt('areaId', selectedAreaId);
        });
      }
    } catch (e) {
      developer.log('Error fetching area: $e', error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    selectedAreaId = -1;
    fetchAreaFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 76, 135),
          leading: IconButton(
            icon: const Icon(
              Icons.location_on,
              size: 34,
              color: Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          child: Text(
                            'Select Area',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        AreaSelectPopUp(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ).then((value) {
                if (value != null) {
                  setState(() {
                    searchQuery = value as String;
                  });
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 40.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 10.0),
                  Text(
                    'Search',
                    style: TextStyle(fontSize: 16.0, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.notifications,
                size: 34,
                color: Colors.white,
              ),
              onPressed: () {
                // Add your onPressed logic here
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(240, 243, 243, 243),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryButton(
                  buttonNames: 'All Products',
                  onTap: () {
                    setState(() {
                      _selectedBrandId = null;
                      _selectedSubCategoryId =
                          null; // Reset the brand ID to show all products
                    });
                  },
                ),
                CategoryButton(
                  buttonNames: 'Categories',
                  onTap: () async {
                    final selectedSubCategoryId = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoryScreen()),
                    );
                    if (selectedSubCategoryId != null) {
                      setState(() {
                        _selectedSubCategoryId = selectedSubCategoryId as int;
                      });
                    }
                  },
                ),
                CategoryButton(
                  buttonNames: 'Brands',
                  onTap: () async {
                    final selectedBrandId = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BrandScreen()),
                    );
                    if (selectedBrandId != null) {
                      setState(() {
                        // Assuming you have a variable to hold the selected brand ID
                        // Update the state with the new brand ID
                        _selectedBrandId = selectedBrandId as int;
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      IconButton(
                        iconSize: 38,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: 380,
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Sort',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SortPopUp(
                                      onSortChanged: (newSortOrder) {
                                        setState(() {
                                          _currentSortOrder =
                                              newSortOrder; // Update the sort order
                                        });
                                        Navigator.pop(
                                            context); // Close the bottom sheet
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.sort),
                      ),
                      Text(
                        'Sort',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      IconButton(
                        iconSize: 38,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FilterCategoriesScreen()),
                          );
                        },
                        icon: const Icon(Icons.filter_alt),
                      ),
                      Text(
                        'Filter',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: ItemsWidget(
                  brandId: _selectedBrandId,
                  subCategoryId: _selectedSubCategoryId,
                  sortOrder: _currentSortOrder,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
