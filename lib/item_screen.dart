import "package:flutter/material.dart";
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/item_variations_screen.dart';
import 'components/item_app_bar.dart';
import "package:google_fonts/google_fonts.dart";
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_navigator/components/item_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final List<String> itemAssetNames;
  final Blob itemDescription;
  final String priceByUom;

  const ItemScreen({
    required this.productId,
    required this.productName,
    required this.itemAssetNames,
    required this.itemDescription,
    required this.priceByUom,
  });

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  late int _areaId;
  String _uom = '';
  double _price = 0.0;
  late Map<int, Map<String, double>> _priceData;
  late String _priceDataByArea;
  int _selectedImageIndex = 0;

  Future<void> getAreaId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _areaId = prefs.getInt('areaId') ?? 0;
    });
  }

  void retrievePriceByUomUsingAreaId() {
    if (_priceData.containsKey(_areaId)) {
      Map<String, double> areaData = _priceData[_areaId]!;
      if (areaData.isNotEmpty) {
        // Assuming you want to retrieve the first entry's key and value
        MapEntry<String, double> firstEntry = areaData.entries.first;
        _uom = firstEntry.key;
        _price = firstEntry.value;
        _priceDataByArea = jsonEncode(areaData);
        print(_priceDataByArea);
      } else {
        print('No data found for area ID: $_areaId');
      }
    } else {
      print('Area ID $_areaId not found in price data.');
    }
  }

  Future<void> getPriceData() async {
    try {
      Map<String, dynamic> decodedData = jsonDecode(widget.priceByUom);
      _priceData = {};

      decodedData.forEach((key, value) {
        int areaId = int.tryParse(key) ?? 0;
        if (value is Map<String, dynamic>) {
          Map<String, double> areaPrices = {};
          value.forEach((uom, price) {
            if (price is String) {
              double parsedPrice =
                  double.tryParse(price.replaceAll(',', '')) ?? 0.0;
              areaPrices[uom] = parsedPrice;
            }
          });
          _priceData[areaId] = areaPrices;
        }
      });

      retrievePriceByUomUsingAreaId();
    } catch (e) {
      print('Error decoding price data: $e');
    }
  }

  Future<void> initializeData() async {
    await getAreaId();
    await getPriceData();
  }

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  Widget build(BuildContext context) {
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
                  blurRadius: 6,
                ),
              ],
              border: Border.all(
                width: 1,
                color: const Color.fromARGB(255, 0, 76, 135),
              ),
            ),
            child: CachedNetworkImage(
              imageUrl: widget.itemAssetNames[_selectedImageIndex],
              height: 466,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error_outline),
            ),

            /*Image.asset(
              widget.itemAssetNames[_selectedImageIndex],
              height: 446,
            ), */
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemAssetNames.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Image.network(
                      widget.itemAssetNames[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
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
                        widget.productName,
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
                        _uom,
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
            margin: const EdgeInsets.only(left: 10),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return ItemVariationsScreen(
                        productId: widget.productId,
                        productName: widget.productName,
                        itemAssetName: widget.itemAssetNames[1],
                        priceByUom: _priceDataByArea,
                      );
                    }),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.productName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 25, 23, 49),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$_uom: RM ${_price.toStringAsFixed(3)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 25, 23, 49),
                              ),
                            ),
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
          ),
          const Divider(
            height: 24,
            thickness: 1,
            color: const Color.fromARGB(255, 202, 202, 202),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
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
                widget.itemDescription.toString(),
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

