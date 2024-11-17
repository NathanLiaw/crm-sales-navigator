// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/Components/navigation_bar.dart';
import 'package:sales_navigator/screens/product/filter_categories_screen.dart';
import 'package:sales_navigator/screens/product/area_select_popup.dart';
import 'package:sales_navigator/screens/product/search_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/model/sort_popup.dart';
import 'package:sales_navigator/model/items_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late Map<int, String> area = {};
  static late int selectedAreaId;
  static String currentAreaName = 'KCH';
  String searchQuery = '';
  int? _selectedSubCategoryId;
  List<int> _selectedSubCategoryIds = [];
  List<int> _selectedBrandIds = [];
  String _currentSortOrder = 'By Name (A to Z)';
  Key _tabBarViewKey = UniqueKey();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    selectedAreaId = -1;
    fetchAreaFromDb();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> setAreaId(int areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('areaId', areaId);
    setState(() {
      selectedAreaId = areaId;
      currentAreaName = area[selectedAreaId] ?? 'KCH';
    });
  }

  Future<void> fetchAreaFromDb() async {
    Map<int, String> areaMap = {};
    try {
      // API URL
      final apiUrl = Uri.parse(
          '${dotenv.env['API_URL']}/product_screen/get_areas.php');

      // Make the API call
      final response = await http.get(apiUrl);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        developer.log('Raw JSON Data: $jsonData'); // Debugging statement

        if (jsonData['status'] == 'success') {
          // Parse the area data
          areaMap = { for (var item in jsonData['data'])
            int.tryParse(item['id'].toString()) ?? -1 : item['area'] as String? ?? '' };

          setState(() {
            area = areaMap;
            // Log the first area's name if it exists
            if (area.isNotEmpty) {
              developer.log(area.values.first);
            }
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          int? storedAreaId = prefs.getInt('areaId');

          // Set the area ID based on stored preferences or the first area in the list
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
        } else {
          developer.log('Error: ${jsonData['message']}');
        }
      } else {
        developer.log('Failed to load area data');
      }
    } catch (e) {
      developer.log('Error fetching area: $e');
    }
  }
  
  void _openFilterCategoriesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterCategoriesScreen(
          initialSelectedSubCategoryIds: _selectedSubCategoryIds,
          initialSelectedBrandIds: _selectedBrandIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSubCategoryIds =
            result['selectedSubCategoryIds'] ?? _selectedSubCategoryIds;
        _selectedBrandIds = result['selectedBrandIds'] ?? _selectedBrandIds;
        _tabBarViewKey = UniqueKey();
      });
    }
  }

  Widget _buildTabBarView() {
    return TabBarView(
      key: _tabBarViewKey,
      controller: _tabController,
      children: [
        ItemsWidget(
          brandIds: _selectedBrandIds,
          subCategoryId: _selectedSubCategoryId,
          subCategoryIds: _selectedSubCategoryIds,
          isFeatured: false,
          sortOrder: _currentSortOrder,
        ),
        ItemsWidget(
          brandIds: _selectedBrandIds,
          subCategoryId: _selectedSubCategoryId,
          subCategoryIds: _selectedSubCategoryIds,
          isFeatured: true,
          sortOrder: _currentSortOrder,
        ),
        ItemsWidget(
          brandIds: _selectedBrandIds,
          subCategoryId: _selectedSubCategoryId,
          subCategoryIds: _selectedSubCategoryIds,
          isFeatured: false,
          sortOrder: _currentSortOrder,
        ),
        ItemsWidget(
          brandIds: _selectedBrandIds,
          subCategoryId: _selectedSubCategoryId,
          subCategoryIds: _selectedSubCategoryIds,
          isFeatured: false,
          sortOrder: _currentSortOrder,
        ),
      ],
    );
  }

  void refreshTabBarView() {
    setState(() {});
  }

  void refreshScreen() {
    setState(() {
      // This will trigger a rebuild of the screen
      fetchAreaFromDb();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xff0175FF),
          leadingWidth: 80, // Width for the column layout
          leading: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Select Area',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          AreaSelectPopUp(
                            onAreaSelected: setAreaId,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentAreaName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
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
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(240, 243, 243, 243),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              alignment: Alignment.center,
              color: const Color(0xff0175FF),
              height: 42,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 380,
                              width: double.infinity,
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'Sort',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SortPopUp(
                                    onSortChanged: (newSortOrder) {
                                      setState(() {
                                        _currentSortOrder = newSortOrder; // Update the sort order
                                        _tabBarViewKey = UniqueKey(); // Change the key to force rebuild
                                      });
                                      Navigator.pop(context); // Close the bottom sheet
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sort,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sort',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        _openFilterCategoriesScreen();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.filter_alt,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color.fromARGB(255, 12, 119, 206),
                      labelColor: const Color.fromARGB(255, 12, 119, 206),
                      isScrollable: true,
                      labelStyle: const TextStyle(fontSize: 14),
                      unselectedLabelColor: Colors.black,
                      tabs: const [
                        Tab(text: 'All products'),
                        Tab(text: 'Featured Products'),
                        Tab(text: 'New Products'),
                        Tab(text: 'Most Popular'),
                      ],
                    ),
                    Expanded(
                      child: _buildTabBarView(),
                    ),
                  ],
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
