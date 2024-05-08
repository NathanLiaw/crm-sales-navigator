import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/branddata.dart';
import 'package:sales_navigator/data/categorydata.dart';
import 'package:sales_navigator/data/sub_categorydata.dart';
import 'package:sales_navigator/db_connection.dart';

class FilterCategoriesScreen extends StatefulWidget {
  final List<int> initialSelectedSubCategoryIds;
  final List<int> initialSelectedBrandIds;

  FilterCategoriesScreen({
    required this.initialSelectedSubCategoryIds,
    required this.initialSelectedBrandIds,
  });

  @override
  _FilterCategoriesScreenState createState() => _FilterCategoriesScreenState();
}

class _FilterCategoriesScreenState extends State<FilterCategoriesScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];
  late List<BrandData> _brands = [];
  int _expandedIndex = -1;
  List<int> selectedSubCategoryIds = [];
  List<int> _selectedBrandIds = [];

  @override
  void initState() {
    super.initState();
    selectedSubCategoryIds = List.from(widget.initialSelectedSubCategoryIds);
    _selectedBrandIds = List.from(widget.initialSelectedBrandIds);
    _loadData();
  }

  Future<void> _loadData() async {
    final conn = await connectToDatabase();
    _categories = await fetchCategories(conn);
    _subCategories = await fetchSubCategories(conn);
    _brands = await fetchBrands(conn); // Fetch brands from the database
    await conn.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Filter Categories',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: _categories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Display categories and subcategories
                ..._categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isExpanded = index == _expandedIndex;
                  return ExpansionTile(
                    title: Text(
                      category.category,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : -1;
                      });
                    },
                    children: [
                      if (isExpanded)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _subCategories[index].length,
                          itemBuilder: (context, subIndex) {
                            final subCategoryData =
                                _subCategories[index][subIndex];
                            return CheckboxListTile(
                              title: Text(
                                subCategoryData.subCategory,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              value: selectedSubCategoryIds
                                  .contains(subCategoryData.id),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected!) {
                                    selectedSubCategoryIds
                                        .add(subCategoryData.id);
                                  } else {
                                    selectedSubCategoryIds
                                        .remove(subCategoryData.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                    ],
                  );
                }).toList(),
                // Display brands
                ExpansionTile(
                  title: Text(
                    'Brands',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: _brands.map((brand) {
                    return CheckboxListTile(
                      title: Text(brand.brand),
                      value: _selectedBrandIds.contains(brand.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            _selectedBrandIds.add(brand.id);
                          } else {
                            _selectedBrandIds.remove(brand.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        color: Color.fromARGB(255, 255, 255, 255),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSubCategoryIds.clear();
                  _selectedBrandIds.clear();
                });
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 38),
                backgroundColor: Color.fromARGB(255, 184, 10, 39),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context, {
                    'selectedSubCategoryIds': selectedSubCategoryIds,
                    'selectedBrandIds': _selectedBrandIds,
                  });
                });
              },
              child: Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 38),
                backgroundColor: const Color.fromARGB(255, 4, 108, 169),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
