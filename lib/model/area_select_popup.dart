import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AreaSelectPopUp extends StatefulWidget {
  AreaSelectPopUp({Key? key}) : super(key: key);

  @override
  State<AreaSelectPopUp> createState() => _AreaSelectPopUpState();
}

class _AreaSelectPopUpState extends State<AreaSelectPopUp> {
  late Map<int, String> area = {};
  static late int selectedAreaId;

  Future<void> setAreaId(int areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('areaId', areaId);
    setState(() {
      selectedAreaId = areaId; // Update the selected area ID
    });
  }

  Future<void> fetchAreaFromDb() async {
    Map<int, String> areaMap = {};
    try {
      MySqlConnection conn = await connectToDatabase();
      final results = await readData(
        conn,
        'area',
        'status=1',
        '',
        'id, area',
      );
      await conn.close();

      areaMap = Map.fromEntries(results.map((row) => MapEntry<int, String>(
        row['id'],
        row['area'] ?? '',
      )));

      setState(() {
        area = areaMap;
      });

    } catch (e) {
      print('Error fetching area: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAreaFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: area.entries.map((entry) {
          int areaId = entry.key;
          String areaName = entry.value;

          return RadioListTile<int>(
            title: Text(
              areaName,
              style: GoogleFonts.inter(
                fontSize: 18,
              ),
            ),
            value: areaId,
            groupValue: selectedAreaId,
            onChanged: (selectedAreaId) {
              setState(() {
                setAreaId(selectedAreaId!);
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
