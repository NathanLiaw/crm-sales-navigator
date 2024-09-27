import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomerInsightsPage extends StatefulWidget {
  const CustomerInsightsPage({super.key});

  @override
  State<CustomerInsightsPage> createState() => _CustomerInsightsPageState();
}

class _CustomerInsightsPageState extends State<CustomerInsightsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Insights',
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff0175FF),
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              height: 262,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [Color(0xff0175FF), Color(0xffA5DBE7)])),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "icons/predictive_analytics.svg",
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          'Insights',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'KKB Construction Supplies',
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(letterSpacing: -0.8),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xff94FFDF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'High Value',
                            style: TextStyle(
                              color: Color(0xff008A64),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 22,
                      left: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 26,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          'Total spent',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    child: Text(
                      'RM 80,000,000',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 14),
                      width: MediaQuery.of(context).size.width -
                          20,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurStyle: BlurStyle.normal,
                            color: Color.fromARGB(75, 117, 117, 117),
                            spreadRadius: 0.1,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Address:',
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(letterSpacing: -0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff0175FF),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width -
                                    48,
                                child: Text(
                                  '10, Block C, Old Slipway, P.O Box 409, 90704, Sandakan Sabah',
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(letterSpacing: -0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        const Color.fromARGB(255, 25, 23, 49),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact:',
                                      style: GoogleFonts.inter(
                                        textStyle:
                                            const TextStyle(letterSpacing: -0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff0175FF),
                                      ),
                                    ),
                                    Text(
                                      '016-4567890',
                                      style: GoogleFonts.inter(
                                        textStyle:
                                            const TextStyle(letterSpacing: -0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color.fromARGB(
                                            255, 25, 23, 49),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email address:',
                                      style: GoogleFonts.inter(
                                        textStyle:
                                            const TextStyle(letterSpacing: -0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff0175FF),
                                      ),
                                    ),
                                    Text(
                                      'contact@kkbindustrialstools.com',
                                      style: GoogleFonts.inter(
                                        textStyle:
                                            const TextStyle(letterSpacing: -0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color.fromARGB(
                                            255, 25, 23, 49),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ]),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            height: 122,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              color: Color(0xFFECEDF5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      "icons/Ai_star.png",
                                      width: 16,
                                      height: 16,
                                    ),
                                  ],
                                ),
                                Text(
                                  '6 Days',
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(letterSpacing: -0.8),
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xff0066FF),
                                  ),
                                ),
                                Text(
                                  'Predicted Next Visit',
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(letterSpacing: -0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            height: 122,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              color: Color(0xFFECEDF5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      "icons/Ai_star.png",
                                      width: 16,
                                      height: 16,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Low',
                                      style: GoogleFonts.inter(
                                        textStyle:
                                            const TextStyle(letterSpacing: -0.8),
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xffFF5454),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    const Icon(
                                      Icons.south_east,
                                      size: 44,
                                      color: Color(0xffFF5454),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Total Spend Group',
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(letterSpacing: -0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 246,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              color: Color.fromARGB(255, 255, 255, 255),
                              boxShadow: [
                                BoxShadow(
                                  blurStyle: BlurStyle.normal,
                                  color: Color.fromARGB(75, 117, 117, 117),
                                  spreadRadius: 0.1,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 8, left: 10, right: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Last Spending',
                                            style: GoogleFonts.inter(
                                              textStyle: const TextStyle(
                                                  letterSpacing: -0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'RM100,000',
                                        style: GoogleFonts.inter(
                                          textStyle:
                                              const TextStyle(letterSpacing: -0.8),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xff0066FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 156,
                                  child: LineChart(
                                    LineChartData(
                                        gridData: FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(show: false),
                                        minX: 0,
                                        maxX: 10,
                                        minY: 0,
                                        maxY: 10,
                                        lineBarsData: [
                                          LineChartBarData(
                                              colors: [const Color(0xff0066FF)],
                                              isCurved: true,
                                              dotData: FlDotData(show: false),
                                              belowBarData: BarAreaData(
                                                  show: true,
                                                  colors: [
                                                    const Color(0xff001AFF),
                                                    const Color(0xffFFFFFF)
                                                  ],
                                                  gradientFrom: const Offset(0.5, 0),
                                                  gradientTo: const Offset(0.5, 1)),
                                              spots: [
                                                FlSpot(0, 3),
                                                FlSpot(3, 4),
                                                FlSpot(4, 2.5),
                                                FlSpot(6, 8),
                                                FlSpot(8, 5),
                                                FlSpot(10, 6),
                                              ])
                                        ]),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Container(
                            height: 246,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: ResizeImage(
                                    AssetImage('asset/hgh_recency.png'),
                                    width: 100,
                                    height: 72),
                                alignment: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              color: Color.fromARGB(255, 255, 255, 255),
                              boxShadow: [
                                BoxShadow(
                                  blurStyle: BlurStyle.normal,
                                  color: Color.fromARGB(75, 117, 117, 117),
                                  spreadRadius: 0.1,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 8, left: 10, right: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Recency',
                                            style: GoogleFonts.inter(
                                              textStyle: const TextStyle(
                                                  letterSpacing: -0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Image.asset(
                                            "icons/Ai_star.png",
                                            width: 16,
                                            height: 16,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: const Icon(
                                          Icons.arrow_upward,
                                          weight: 0.2,
                                          size: 74,
                                          color: Color(0xff29C194),
                                        ),
                                      ),
                                      Text(
                                        'High Recency',
                                        maxLines: 2,
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              letterSpacing: -0.8),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xff29C194),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
            )
          ],
        ),
      ),
    );
  }
}
