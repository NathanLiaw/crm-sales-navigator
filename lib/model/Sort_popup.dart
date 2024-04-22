import 'package:flutter/material.dart';
import 'package:sales_navigator/data/sortlistdata.dart';
import 'package:google_fonts/google_fonts.dart';

class SortPopUp extends StatefulWidget {
  final Function(String) onSortChanged;

  SortPopUp({Key? key, required this.onSortChanged}) : super(key: key);

  @override
  State<SortPopUp> createState() => _SortPopUp();
}

class _SortPopUp extends State<SortPopUp> {
  static String currentSortList = sortLists[0];
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          RadioListTile(
            title: Text(
              sortLists[0],
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: sortLists[0],
            groupValue: currentSortList,
            onChanged: (value) {
              setState(() {
                currentSortList = value.toString();
              });
              widget.onSortChanged(
                  currentSortList); // Add this line to notify the parent widget
            },
          ),
          RadioListTile(
            title: Text(
              sortLists[1],
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: sortLists[1],
            groupValue: currentSortList,
            onChanged: (value) {
              setState(() {
                currentSortList = value.toString();
              });
              widget.onSortChanged(
                  currentSortList); // Add this line to notify the parent widget
            },
          ),
          RadioListTile(
            title: Text(
              sortLists[2],
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: sortLists[2],
            groupValue: currentSortList,
            onChanged: (value) {
              setState(() {
                currentSortList = value.toString();
              });
              widget.onSortChanged(
                  currentSortList); // Add this line to notify the parent widget
            },
          ),
          RadioListTile(
            title: Text(
              sortLists[3],
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: sortLists[3],
            groupValue: currentSortList,
            onChanged: (value) {
              setState(() {
                currentSortList = value.toString();
              });
              widget.onSortChanged(
                  currentSortList); // Add this line to notify the parent widget
            },
          ),
          RadioListTile(
            title: Text(
              sortLists[4],
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: sortLists[4],
            groupValue: currentSortList,
            onChanged: (value) {
              setState(() {
                currentSortList = value.toString();
              });
              widget.onSortChanged(
                  currentSortList); // Add this line to notify the parent widget
            },
          ),
        ],
      ),
    );
  }
}
