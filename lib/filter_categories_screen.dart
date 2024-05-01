import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/categorydata.dart';
import 'package:sales_navigator/data/sub_categorydata.dart';
import 'package:sales_navigator/db_connection.dart';

class FilterCategoriesScreen extends StatefulWidget {
  final List<int> initialSelectedSubCategoryIds;

  FilterCategoriesScreen({required this.initialSelectedSubCategoryIds});

  @override
  _FilterCategoriesScreenState createState() => _FilterCategoriesScreenState();
}

class _FilterCategoriesScreenState extends State<FilterCategoriesScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];
  int _expandedIndex = -1;
  List<int> selectedSubCategoryIds = [];

  @override
  void initState() {
    super.initState();
    selectedSubCategoryIds = List.from(widget.initialSelectedSubCategoryIds);
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
                          final subCategoryData =
                              _subCategories[index][subIndex];
                          return ListTile(
                            title: Text(
                              subCategoryData.subCategory,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            trailing: selectedSubCategoryIds
                                    .contains(subCategoryData.id)
                                ? Icon(Icons.check)
                                : null,
                            onTap: () {
                              setState(() {
                                if (selectedSubCategoryIds
                                    .contains(subCategoryData.id)) {
                                  selectedSubCategoryIds
                                      .remove(subCategoryData.id);
                                } else {
                                  selectedSubCategoryIds
                                      .add(subCategoryData.id);
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
                  Navigator.pop(context, selectedSubCategoryIds);
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


/*

TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Complete',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 4, 108, 169),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2)),
                                ),
                              )


            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedSubCategoryIds);
              },
              child: Text('Apply'),
            ),




 ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedSubCategoryIds.clear();
                });
              },
              child: Text('Remove'),
            ),

*/