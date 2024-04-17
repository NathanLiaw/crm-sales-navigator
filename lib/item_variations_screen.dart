import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysql1/mysql1.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class ItemVariationsScreen extends StatefulWidget {
  const ItemVariationsScreen({
    Key? key,
    required this.productName,
    required this.itemAssetName,
    required this.priceByUom,
  }) : super(key: key);

  final String productName;
  final String itemAssetName;
  final String priceByUom;

  @override
  State<ItemVariationsScreen> createState() => _ItemVariationsScreenState();
}

class _ItemVariationsScreenState extends State<ItemVariationsScreen> {
  @override
  Widget build(BuildContext context) {
    final priceData = jsonDecode(widget.priceByUom);
    final firstEntry = priceData.entries.first;
    final variationName = firstEntry.key;
    final variationPrices = firstEntry.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Variations',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: ListView.builder(
        itemCount: variationPrices.length,
        itemBuilder: (context, idx) {
          final uom = variationPrices.keys.elementAt(idx);
          final price = variationPrices[uom];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: Color.fromARGB(255, 0, 76, 135),
                            ),
                          ),
                          child: Image.asset(
                            widget.itemAssetName,
                            height: 118,
                            width: 118,
                          ),
                        ),
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 248,
                                          child: Text(
                                            widget.productName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 248,
                                          child: Text(
                                            '$uom',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    iconSize: 28,
                                    onPressed: () {},
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    '1',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  IconButton(
                                    iconSize: 28,
                                    onPressed: () {},
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        left: 10,
                        bottom: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM $price',
                            style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                backgroundColor:
                                    Color.fromARGB(255, 4, 124, 189),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(
                                'Add To Cart',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ))
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}






















/*
class ItemVariationsScreen extends StatefulWidget {
  const ItemVariationsScreen(
      {super.key,
      required this.productName,
      required this.itemAssetName,
      required this.priceByUom});

  final String productName;
  final String itemAssetName;
  final String priceByUom;

  @override
  State<ItemVariationsScreen> createState() {
    return _ItemVariationsScreenState();
  }
}

class _ItemVariationsScreenState extends State<ItemVariationsScreen> {
  @override
  Widget build(BuildContext context) {
    final priceData = jsonDecode(widget.priceByUom);
    final firstEntry = priceData.entries.first;
    final variationName = firstEntry.key;
    final variationPrice = firstEntry.value;

    print(variationName);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Variations',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width: 1,
                          color: Color.fromARGB(255, 0, 76, 135),
                        ),
                      ),
                      child: Image.asset(
                        'photo/5d2d92ea8fff2.jpg',
                        height: 118,
                        width: 118,
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.productName,
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    variationName.toString(),
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )),
                          SizedBox(
                            height: 28,
                          ),
                          Row(
                            children: [
                              IconButton(
                                iconSize: 28,
                                onPressed: () {},
                                icon: const Icon(Icons.remove),
                              ),
                              Text(
                                '1',
                                style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                iconSize: 28,
                                onPressed: () {},
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 10,
                    bottom: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        variationPrice.toString(),
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            backgroundColor: Color.fromARGB(255, 4, 124, 189),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: Text(
                            'Add To Cart',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

*/

/*
class ItemVariationsScreen extends StatefulWidget {
  const ItemVariationsScreen(
      {super.key,
      required this.productName,
      required this.itemAssetName,
      required this.priceByUom});

  final String productName;
  final String itemAssetName;
  final String priceByUom;

  @override
  State<ItemVariationsScreen> createState() {
    return _ItemVariationsScreenState();
  }
}

class _ItemVariationsScreenState extends State<ItemVariationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Variations',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color.fromARGB(255, 0, 76, 135),
      ),
      body: ListView.builder(
        itemCount: jsonDecode(widget.priceByUom).length,
        itemBuilder: (context, index) {
          final variationData =
              jsonDecode(widget.priceByUom).entries.elementAt(index);
          final variationName = variationData.key;
          final variationPrices = variationData.value;

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variationName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: variationPrices.length,
                  itemBuilder: (context, idx) {
                    final uom = variationPrices.keys.elementAt(idx);
                    final price = variationPrices[uom];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UOM: $uom',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Price: RM $price',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (idx < variationPrices.length - 1)
                          SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

*/