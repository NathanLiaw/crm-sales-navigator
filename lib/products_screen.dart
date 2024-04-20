import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
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

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String searchQuery = '';
  late Map<int, String> area = {};
  static late int selectedAreaId;

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

      // Retrieve the currently selected areaId from preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedAreaId = prefs.getInt('areaId');

      // Set selectedAreaId to the stored areaId if available, otherwise set it to the first areaId from the query
      if (storedAreaId != null && areaMap.containsKey(storedAreaId)) {
        setState(() {
          selectedAreaId = storedAreaId;
        });
      } else if (areaMap.isNotEmpty) {
        setState(() {
          selectedAreaId = areaMap.keys.first;
          // Store the initial selectedAreaId in SharedPreferences
          prefs.setInt('areaId', selectedAreaId);
        });
      }
    } catch (e) {
      print('Error fetching area: $e');
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
          title: InkWell(
            onTap: () {},
            child: Container(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search',
                  suffixIcon: Icon(Icons.search),
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(80),
                  ),
                ),
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
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryButton(
                  buttonnames: 'Categories',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return CategoryScreen();
                        }));
                  },
                ),
                CategoryButton(
                  buttonnames: 'Brands',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return BrandScreen();
                        }));
                  },
                ),
              ],
            ),
            Row(
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
                                    SortPopUp(),
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
                const SizedBox(width: 330),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      IconButton(
                        iconSize: 38,
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                                return FilterCategoriesScreen();
                              }));
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
                child: ItemsWidget(searchQuery: searchQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
