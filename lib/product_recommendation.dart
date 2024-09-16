import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductRecommendationPage extends StatefulWidget {
  const ProductRecommendationPage({Key? key}) : super(key: key);

  @override
  State<ProductRecommendationPage> createState() =>
      _ProductRecommendationPageState();
}

class _ProductRecommendationPageState extends State<ProductRecommendationPage> {
  String? selectedCustomer;
  final List<String> customers = ['One', 'Two', 'Three', 'Four'];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              "asset/product_r_top.png",
              width: size.width * 0.4,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              "asset/product_r_bttm.png",
              width: size.width,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 42, left: 12, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Let\'s see what we can sell.',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 68),
                Text(
                  'Customer A',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Color.fromARGB(255, 214, 214, 214), width: 1)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCustomer,
                      hint: const Text("Select a customer"),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCustomer = newValue;
                        });
                      },
                      items: customers
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.inter(
                              color: Color(0xff0175FF),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Customer B',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Color.fromARGB(255, 214, 214, 214), width: 1)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCustomer,
                      hint: const Text("Select a customer"),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCustomer = newValue;
                        });
                      },
                      items: customers
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.inter(
                              color: Color(0xff0175FF),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Apply",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                          fixedSize: Size(180, 40),
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xff0175FF)),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Container(
                  alignment: Alignment.center,
                  child: Container(
                      child: Image.asset(
                    'asset/Powerer_by_ai.png',
                    width: 142,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
