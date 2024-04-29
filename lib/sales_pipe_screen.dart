import 'package:flutter/material.dart';
import 'package:sales_navigator/model/sales_lead_eng_widget.dart';
import 'package:sales_navigator/model/sales_lead_nego_widget.dart';

class SalesPipeScreen extends StatefulWidget {
  const SalesPipeScreen({Key? key}) : super(key: key);

  @override
  State<SalesPipeScreen> createState() => _SalesPipeScreenState();
}

class _SalesPipeScreenState extends State<SalesPipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 76, 135),
        title: Text(
          'Welcome, SalesmanTitle',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Sales Lead Pipeline',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            padding: EdgeInsets.symmetric(
              vertical: 8,
            ),
            height: 810,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: SalesLeadNegoWidget(),
          ),
        ],
      ),
    );
  }
}
