import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/category_data.dart';
import 'package:sales_navigator/data/sub_category_data.dart';
import 'package:sales_navigator/db_connection.dart';

class CategoryScreen extends StatefulWidget {
  CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() {
    return _CategoryScreenState();
  }
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];
  int _expandedIndex = -1;

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
          'Categories',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
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
                          return ListTile(
                            title: Text(
                              _subCategories[index][subIndex].subCategory,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(
                                  context, _subCategories[index][subIndex].id);
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


/*

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/category_data.dart';
import 'package:sales_navigator/data/sub_category_data.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() {
    return _CategoryScreenState();
  }
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];

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
          'Categories',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: _categories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return ExpansionPanelList(
                  elevation: 1,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _categories[panelIndex].isExpanded = !isExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text(_categories[index].category),
                        );
                      },
                      body: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subCategories[index].length,
                        itemBuilder: (context, subIndex) {
                          return ListTile(
                            title: Text(
                                _subCategories[index][subIndex].subCategory),
                          );
                        },
                      ),
                      isExpanded: _categories[index].isExpanded,
                    ),
                  ],
                );
              },
            ),
    );
  }
}


*/