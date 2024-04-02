import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'db_connection.dart';
import 'cart.dart';

void main() {
  runApp(MaterialApp(
    title: 'Sales Navigator',
    home: MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Map<String, String>> selectedCompanies = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Details',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(width: 10),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
          title: const Text(
            'Customer Details',
            style: TextStyle(color: Color(0xffF8F9FA)),
          ),
          backgroundColor: const Color(0xff004c87),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SelectableCardList(
                onSelectionChanged: (companies) {
                  setState(() {
                    selectedCompanies = companies;
                  });
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            print("Selected Companies: $selectedCompanies");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(companies: selectedCompanies),
              ),
            );
          },
          child: Icon(Icons.shopping_cart),
        ),
      ),
    );
  }
}

class SelectableCardList extends StatefulWidget {
  final ValueChanged<List<Map<String, String>>>? onSelectionChanged;

  const SelectableCardList({Key? key, this.onSelectionChanged}) : super(key: key);

  @override
  _SelectableCardListState createState() => _SelectableCardListState();
}

class _SelectableCardListState extends State<SelectableCardList> {
  List<Map<String, String>> companies = [];
  int? selectedIndex;
  List<Map<String, String>> selectedCompanies = [];

  @override
  void initState() {
    super.initState();
    fetchCustomers().then((value) {
      setState(() {
        companies = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: companies.asMap().entries.map((entry) {
        final index = entry.key;
        final company = entry.value;
        return GestureDetector(
         onTap: () {
          setState(() {
            // Toggle the selection state
            selectedIndex = selectedIndex == index ? null : index;
            
            if (selectedIndex != null) {
              if (selectedIndex == index) {
                // Add the selected company to the list if not already present
                if (!selectedCompanies.contains(company)) {
                  selectedCompanies.add(company);
                  print("Company added: ${company['name']}");
                }
              } else {
                // Remove the previously selected company from the list
                // We need to find the company associated with the selectedIndex
                if (selectedIndex! < selectedCompanies.length) {
                  Map<String, String> deselectedCompany = selectedCompanies[selectedIndex!];
                  selectedCompanies.remove(deselectedCompany);
                  print("Company removed: ${deselectedCompany['name']}");
                }
              }
            }
            // Call the callback with the updated selected companies list
            widget.onSelectionChanged?.call(selectedCompanies);
        });
      },  
          child: Card(
            color: selectedIndex == index ? Color(0xfff8f9fa) : Color(0xfff8f9fa),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoundRadioButton(
                        selected: selectedIndex == index,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company['name'] ?? '',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff191731),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              company['address'] ?? '',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color(0xff191731),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text(
                            company['phone'] ?? '',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff191731),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          company['email'] ?? '',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff191731),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class RoundRadioButton extends StatelessWidget {
  final bool selected;
  final double size;

  const RoundRadioButton({
    required this.selected,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8.0,
      height: size + 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(0xff004c87),
          width: 1.0,
        ),
        color: selected ? Colors.white : Colors.transparent,
      ),
      child: selected
          ? Center(
              child: Container(
                width: size - 3.0,
                height: size - 3.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xff004c87),
                ),
              ),
            )
          : null,
    );
  }
}

Future<List<Map<String, String>>> fetchCustomers() async {
  List<Map<String, String>> fetchedCompanies = [];
  try {
    MySqlConnection conn = await connectToDatabase();
    Results results = await conn.query(
        'SELECT company_name, address_line_1, contact_number, email FROM customer WHERE status=1');
    await Future.delayed(Duration(seconds: 2));
    await conn.close();

    for (var row in results) {
      fetchedCompanies.add({
        'name': row[0] as String,
        'address': row[1] as String,
        'phone': row[2] as String,
        'email': row[3] as String,
      });
    }
  } catch (e) {
    print('Error fetching customers: $e');
  }
  return fetchedCompanies;
}
