import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductRecommendationResultsPage extends StatefulWidget {
  const ProductRecommendationResultsPage({Key? key}) : super(key: key);

  @override
  State<ProductRecommendationResultsPage> createState() =>
      _ProductRecommendationResultsState();
}

class _ProductRecommendationResultsState
    extends State<ProductRecommendationResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Recommendation',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0175FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  child: Image.asset(
                    'asset/result_ai.png',
                    width: 700,
                    height: 78,
                    fit: BoxFit.cover,
                  )),
              Container(
                height: 78,
                padding: EdgeInsets.only(left: 12, bottom: 2),
                child: Column(
                  children: [
                    Spacer(),
                    Row(
                      children: [
                        Text(
                          'Results',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(letterSpacing: -0.8),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(right: 10, bottom: 8),
                          child: Image.asset(
                            'asset/Powerer_by_ai.png',
                            width: 122,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  'Customer A might like this..',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(letterSpacing: -0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
