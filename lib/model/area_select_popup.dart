import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysql1/mysql1.dart';
import 'package:sales_navigator/db_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AreaSelectPopUp extends StatefulWidget {
  const AreaSelectPopUp({super.key});

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
      selectedAreaId = areaId;
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

      // Retrieve the currently selected areaId from preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedAreaId = prefs.getInt('areaId');

      // Set selectedAreaId to the stored areaId if available, otherwise set it
      // to the first areaId from the query
      if (storedAreaId != null && areaMap.containsKey(storedAreaId)) {
        setState(() {
          selectedAreaId = storedAreaId;
        });
      } else if (areaMap.isNotEmpty) {
        setState(() {
          selectedAreaId = areaMap.keys.first;
          // Store the initial selectedAreaId in SharedPreferences
          prefs.setInt('areaId', selectedAreaId);
        });
      }
    } catch (e) {
      developer.log('Error fetching area: $e', error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    selectedAreaId = -1;
    fetchAreaFromDb();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            setAreaId(selectedAreaId!);
          },
        );
      }).toList(),
    );
  }
}