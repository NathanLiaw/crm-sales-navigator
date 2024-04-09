import "package:flutter/material.dart";
import 'components/item_app_bar.dart';
import "package:google_fonts/google_fonts.dart";

class ItemScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
              'assets/photos/5dbcdd371c0e1.jpg',
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
                        "Product Title This",
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
                        "Product Sub title",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 25, 23, 49),
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
        ],
      ),
    );
    ;
  }
}
