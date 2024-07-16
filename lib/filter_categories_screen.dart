import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/brand_data.dart';
import 'package:sales_navigator/data/category_data.dart';
import 'package:sales_navigator/data/sub_category_data.dart';
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
    _brands = await fetchBrands(conn);
    await conn.close();
    setState(() {});
  }

  Widget _buildChips() {
    List<Widget> chips = [];

    // Add chips for selected subcategories
    for (var subCatId in selectedSubCategoryIds) {
      String subCatName = '';
      for (var subCatList in _subCategories) {
        for (var subCat in subCatList) {
          if (subCat.id == subCatId) {
            subCatName = subCat.subCategory;
            break;
          }
        }
        if (subCatName.isNotEmpty) break;
      }
      chips.add(Chip(
        label: Text(subCatName),
        onDeleted: () {
          setState(() {
            selectedSubCategoryIds.remove(subCatId);
          });
        },
      ));
    }

    // Add chips for selected brands
    for (var brandId in _selectedBrandIds) {
      String brandName = _brands.firstWhere((b) => b.id == brandId).brand;
      chips.add(Chip(
        label: Text(brandName),
        onDeleted: () {
          setState(() {
            _selectedBrandIds.remove(brandId);
          });
        },
      ));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: chips,
    );
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
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Display categories with expandable subcategories
                      ExpansionTile(
                        title: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: _categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          return ExpansionTile(
                            title: Text(
                              category.category,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children:
                                _subCategories[index].map((subCategoryData) {
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
                            }).toList(),
                          );
                        }).toList(),
                      ),
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
                ),
                // Display chips for selected items
                Container(
                  padding: EdgeInsets.all(8.0),
                  color: Colors.grey[200],
                  child: _buildChips(),
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
                Navigator.pop(context, {
                  'selectedSubCategoryIds': selectedSubCategoryIds,
                  'selectedBrandIds': _selectedBrandIds,
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
