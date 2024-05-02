import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/brands_screen.dart';
import 'package:sales_navigator/categories_screen.dart';
import 'package:sales_navigator/filter_categories_screen.dart';
import 'package:sales_navigator/model/area_select_popup.dart';
import 'package:sales_navigator/search_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/category_button.dart';
import 'package:sales_navigator/model/Sort_popup.dart';
import 'model/items_widget.dart';
import 'db_connection.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late Map<int, String> area = {};
  static late int selectedAreaId;
  String searchQuery = '';
  static int? _selectedBrandId;
  int? _selectedSubCategoryId;
  List<int> _selectedSubCategoryIds = [];
  List<int> _selectedBrandIds = [];
  String _currentSortOrder = 'By Name (A to Z)';
  int _currentPage = 1;
  int _totalPages = 1;
  int _selectedTabIndex = 0;
  bool _isFeatured = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    selectedAreaId = -1;
    fetchAreaFromDb();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<int> _getTotalPages() async {
    try {
      final conn = await connectToDatabase();
      String query = 'SELECT COUNT(*) as total FROM product WHERE status = 1';
      List<dynamic> parameters = [];

      if (_selectedBrandId != null) {
        query += ' AND brand = ?';
        parameters.add(_selectedBrandId);
      } else if (_selectedSubCategoryId != null) {
        query += ' AND sub_category = ?';
        parameters.add(_selectedSubCategoryId);
      }

      final results = await conn.query(query, parameters);
      await conn.close();

      final totalProducts = results.first['total'] as int;
      final limit = 50; // Change this if you want a different limit per page
      final totalPages = (totalProducts / limit).ceil();

      return totalPages;
    } catch (e) {
      print('Error fetching total pages: $e');
      return 1;
    }
  }

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
      print('Error fetching area: $e');
    }
  }

  void _updateSelectedTab(int index) {
    _tabController.index = index;
    setState(() {
      _isFeatured = false;
      _selectedBrandId = null;
      _selectedSubCategoryId = null;
      _currentSortOrder = 'By Name (A to Z)';

      switch (index) {
        case 1:
          _isFeatured = true;
          break;
        case 2:
          _currentSortOrder = 'Uploaded Date (New to Old)';
          break;
        case 3:
          _currentSortOrder = 'Most Popular in 3 Months';
          break;
      }
    });
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
        _selectedSubCategoryIds = result['selectedSubCategoryIds'];
        _selectedBrandIds = result['selectedBrandIds'];
        _currentPage = 1;
      });
    }
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
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 76, 135),
          leading: IconButton(
            icon: Icon(
              Icons.location_on,
              size: 34,
              color: Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
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
                MaterialPageRoute(builder: (context) => SearchScreen()),
              ).then((value) {
                if (value != null) {
                  setState(() {
                    searchQuery = value as String;
                  });
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              height: 40.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
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
              icon: Icon(
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
            SizedBox(height: 2),

            Divider(
              color: Color.fromARGB(255, 0, 76, 135),
            ),
            SizedBox(
              height: 24,
              width: 316,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
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
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sort),
                            SizedBox(width: 4),
                            Text(
                              'Sort',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 25, 23, 49),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    color: Colors.grey,
                  ),
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
                            SizedBox(
                              width: 48,
                            ),
                            Icon(Icons.filter_alt),
                            SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 25, 23, 49),
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
            Divider(
              color: Color.fromARGB(255, 0, 76, 135),
            ),

            Expanded(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color.fromARGB(255, 12, 119, 206),
                      labelColor: const Color.fromARGB(255, 12, 119, 206),
                      isScrollable: true,
                      labelStyle: TextStyle(fontSize: 14),
                      unselectedLabelColor: Colors.black,
                      tabs: [
                        Tab(text: 'All products'),
                        Tab(text: 'Featured Products'),
                        Tab(text: 'New Products'),
                        Tab(text: 'Most Popular'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ItemsWidget(
                            brandIds: _selectedBrandIds,
                            subCategoryId: _selectedSubCategoryId,
                            subCategoryIds: _selectedSubCategoryIds,
                            isFeatured: false,
                            sortOrder: _currentSortOrder == 'By Name (A to Z)'
                                ? 'By Name (A to Z)'
                                : _currentSortOrder,
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
                            sortOrder: _currentSortOrder ==
                                    'Uploaded Date (New to Old)'
                                ? 'Uploaded Date (New to Old)'
                                : _currentSortOrder,
                          ),
                          ItemsWidget(
                            brandIds: _selectedBrandIds,
                            subCategoryId: _selectedSubCategoryId,
                            subCategoryIds: _selectedSubCategoryIds,
                            isFeatured: false,
                            sortOrder:
                                _currentSortOrder == 'Most Popular in 3 Months'
                                    ? 'Most Popular in 3 Months'
                                    : _currentSortOrder,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //tab bar
          ],
        ),
      ),
    );
  }
}


/*
  Widget _buildTab(int index) {
    // Define the tab names
    List<String> tabNames = [
      'All products',
      'Featured products',
      'New products',
      'Most Popular'
    ];

    // Determine if the tab is selected
    bool isSelected = _selectedTabIndex == index;

    // Define the style for the selected and unselected tabs
    return GestureDetector(
      onTap: () => _updateSelectedTab(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 12, 119, 206)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tabNames[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

*/


/*


            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryButton(
                  buttonnames: 'Most Popular',
                  onTap: () {
                    setState(() {
                      // Reset the brand ID to show all products
                    });
                  },
                ),
                CategoryButton(
                  buttonnames: 'Categories',
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
                  buttonnames: 'Brands',
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


            */



//previous item widgets

/*

  Flexible(
              child: SingleChildScrollView(
                child: FutureBuilder<int>(
                  future: _getTotalPages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    _totalPages = snapshot.data ?? 1;

                    return Column(
                      children: [
                        ItemsWidget(
                          brandIds: _selectedBrandIds,
                          subCategoryId: _selectedSubCategoryId,
                          subCategoryIds: _selectedSubCategoryIds,
                          isFeatured: _isFeatured,
                          sortOrder: _currentSortOrder,
                          currentPage: _currentPage,
                          totalPages: _totalPages,
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 4, 108, 169),
                                  foregroundColor: Colors.white),
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                              child: Text('Previous'),
                            ),
                            SizedBox(width: 16),
                            Text('Page $_currentPage of $_totalPages'),
                            SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 4, 108, 169),
                                  foregroundColor: Colors.white),
                              onPressed: _currentPage < _totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  : null,
                              child: Text('Next'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16)
                      ],
                    );
                  },
                ),
              ),
            ),


*/