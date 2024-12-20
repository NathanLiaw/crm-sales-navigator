// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_navigator/screens/notification/event_logger.dart';
import 'package:sales_navigator/utility_function.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AreaSelectPopUp extends StatefulWidget {
  final Function(int) onAreaSelected;

  const AreaSelectPopUp({super.key, required this.onAreaSelected});

  @override
  State<AreaSelectPopUp> createState() => _AreaSelectPopUpState();
}

class _AreaSelectPopUpState extends State<AreaSelectPopUp> {
  late Map<int, String> area = {};
  static late int selectedAreaId;
  late int salesmanId;

  Future<void> setAreaId(int areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('areaId', areaId);
    setState(() {
      selectedAreaId = areaId;
    });

    String selectedAreaName = area[areaId] ?? 'Unknown Area';
    await EventLogger.logEvent(
      salesmanId,
      'Area selected: $selectedAreaName',
      'Area Selection',
      leadId: null,
    );

    widget.onAreaSelected(areaId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Area changed to: $selectedAreaName',
          style: GoogleFonts.inter(),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> fetchAreaFromDb() async {
    Map<int, String> areaMap = {};
    String apiUrl = '${dotenv.env['API_URL']}/area/get_area.php';
    try {
      final response = await http.get(Uri.parse('$apiUrl?status=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (data['data'] is List) {
            for (var row in data['data']) {
              if (row is Map<String, dynamic>) {
                int id = row['id'] is int
                    ? row['id']
                    : int.tryParse(row['id'].toString()) ?? 0;
                String area = row['area'] is String ? row['area'] : '';
                areaMap[id] = area;
              }
            }

            setState(() {
              area = areaMap;
            });

            SharedPreferences prefs = await SharedPreferences.getInstance();
            int? storedAreaId = prefs.getInt('areaId');

            if (storedAreaId != null && areaMap.containsKey(storedAreaId)) {
              setState(() {
                selectedAreaId = storedAreaId;
              });
            } else if (areaMap.isNotEmpty) {
              setState(() {
                selectedAreaId = areaMap.keys.first;
                prefs.setInt('areaId', selectedAreaId);
              });
            }
          } else {
            developer.log('Error: data["data"] is not a List',
                error: 'Expected a list but got ${data['data']}');
          }
        } else {
          developer.log('Error: ${data['message']}', error: data['message']);
        }
      } else {
        developer.log('Failed to load areas: ${response.statusCode}',
            error: response.body);
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
    _initializeSalesmanId();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
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
          onChanged: (newAreaId) {
            setAreaId(newAreaId!);
          },
        );
      }).toList(),
    );
  }
}
