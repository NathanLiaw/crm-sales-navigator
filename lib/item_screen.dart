import "package:flutter/material.dart";
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/item_variations_screen.dart';
import 'components/item_app_bar.dart';
import "package:google_fonts/google_fonts.dart";
import 'dart:convert';
import 'package:sales_navigator/components/item_bottom_bar.dart';

class ItemScreen extends StatelessWidget {
  final String productName;
  final String itemAssetName;
  final Blob itemDescription;
  final String priceByUom;

  const ItemScreen({
    required this.productName,
    required this.itemAssetName,
    required this.itemDescription,
    required this.priceByUom, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    final priceData = jsonDecode(priceByUom);
    final firstEntry = priceData.entries.first;
    final variationName = firstEntry.key;
    final variationPrices = firstEntry.value;

    final uom = variationPrices.keys.elementAt(1);
    final price = variationPrices[uom];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: ListView(
        children: [
          ItemAppBar(),
          Container(
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 6),
                ],
                border: Border.all(
                  width: 1,
                  color: const Color.fromARGB(255, 0, 76, 135),
                )),
            child: Image.asset(
              itemAssetName,
              height: 446,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 364,
                      child: Text(
                        productName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 364,
                      child: Text(
                        '$uom',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  iconSize: 38,
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                ),
              ],
            ),
          ),
          const Divider(
            height: 24,
            thickness: 1,
            color: const Color.fromARGB(255, 202, 202, 202),
          ),
          Container(
            margin: const EdgeInsets.only(
              left: 10,
            ),
            child: Text(
              "Item Variations",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 25, 23, 49),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Card(
              color: Colors.white,
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ItemVariationsScreen(
                      productName: productName,
                      itemAssetName: itemAssetName,
                      priceByUom: priceByUom,
                    );
                  }));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 364,
                              child: Text(
                                productName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 25, 23, 49),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 364,
                              child: Text(
                                '$uom',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color.fromARGB(255, 25, 23, 49),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      IconButton(
                        iconSize: 30,
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(
            height: 24,
            thickness: 1,
            color: const Color.fromARGB(255, 202, 202, 202),
          ),
          Container(
            margin: const EdgeInsets.only(
              left: 10,
            ),
            child: Text(
              "Item Descriptions",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 25, 23, 49),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10, top: 14),
            child: Container(
              margin: EdgeInsets.only(bottom: 28),
              child: HtmlWidget(
                itemDescription.toString(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ItemBottomNavBar(),
    );
  }
}



/*

ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount:
                jsonDecode(priceByUom).length, // Decode the JSON string here
            itemBuilder: (context, index) {
              final variationData =
                  jsonDecode(priceByUom).entries.elementAt(index);
              final variationName = variationData.key;
              final variationPrices = variationData.value;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Card(
                  color: Colors.white,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 20),
                      child: Row(
                        children: [
                          // Add Image or Icon here
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variationName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 25, 23, 49),
                                  ),
                                ),
                                SizedBox(height: 4),
                                ...variationPrices.entries.map((entry) {
                                  final uom = entry.key;
                                  final price = entry.value;
                                  return Text(
                                    '$uom: RM $price',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          const Color.fromARGB(255, 25, 23, 49),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            iconSize: 30,
                            onPressed: () {},
                            icon: const Icon(Icons.arrow_forward_ios),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),



*/