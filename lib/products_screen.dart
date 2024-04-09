import 'package:sales_navigator/model/Sort_popup.dart';
import 'package:sales_navigator/model/items_widget.dart';
import 'package:flutter/material.dart';
import 'components/category_button.dart';
import 'package:sales_navigator/categories_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales_navigator/data/productdata.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [
    Product(id: "1", name: "Product 1", imageUrl: "url", price: 9.99),
    Product(id: "2", name: "Product 2", imageUrl: "url", price: 19.99),
    // Add more products as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 226, 226, 226),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 70,
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
                  onTap: () {},
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
                        onPressed: () {},
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
            ItemsWidget(),
          ],
        ),
      ),
    );
  }
}
