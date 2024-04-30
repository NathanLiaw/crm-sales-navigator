import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/categorydata.dart';
import 'package:sales_navigator/data/sub_categorydata.dart';
import 'package:sales_navigator/db_connection.dart';

class FilterCategoriesScreen extends StatefulWidget {
  @override
  _FilterCategoriesScreenState createState() => _FilterCategoriesScreenState();
}

class _FilterCategoriesScreenState extends State<FilterCategoriesScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];
  int _expandedIndex = -1;
  Set<String> selectedSubCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final conn = await connectToDatabase();
    _categories = await fetchCategories(conn);
    _subCategories = await fetchSubCategories(conn);
    await conn.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isExpanded = index == _expandedIndex;
                return ExpansionTile(
                  title: Text(
                    _categories[index].category,
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
                          final subCategory =
                              _subCategories[index][subIndex].subCategory;
                          return ListTile(
                            title: Text(
                              subCategory,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            trailing:
                                selectedSubCategories.contains(subCategory)
                                    ? Icon(Icons.check)
                                    : null,
                            onTap: () {
                              setState(() {
                                if (selectedSubCategories
                                    .contains(subCategory)) {
                                  selectedSubCategories.remove(subCategory);
                                } else {
                                  selectedSubCategories.add(subCategory);
                                }
                              });
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
    );
  }
}
