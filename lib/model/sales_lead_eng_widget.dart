import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

final List<String> items = [
  'Item1',
  'Item2',
  'Item3',
  'Item4',
];
String? selectedValue;

class SalesLeadEngWidget extends StatefulWidget {
  const SalesLeadEngWidget({Key? key}) : super(key: key);

  @override
  State<SalesLeadEngWidget> createState() => _SalesLeadEngWidgetState();
}

class _SalesLeadEngWidgetState extends State<SalesLeadEngWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        Container(
          margin: EdgeInsets.only(
            bottom: 8,
          ),
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 205, 229, 242),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                        margin: EdgeInsets.only(
                          left: 10,
                        ),
                        child: Text(
                          'Customer A',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        )),
                    Spacer(),
                    Container(
                      margin: EdgeInsets.only(right: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          hint: Text(
                            'Select Item',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          items: items
                              .map((String item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          value: selectedValue,
                          onChanged: (String? value) {
                            setState(() {
                              selectedValue = value;
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 32,
                              width: 140,
                              decoration: BoxDecoration(color: Colors.white)),
                          menuItemStyleData: const MenuItemStyleData(
                            height: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: 8,
                ),
                height: 100,
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        left: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.phone_outlined),
                              const SizedBox(
                                width: 8,
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 6),
                                child: const Text(
                                  '+019-231 3043',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined),
                              const SizedBox(
                                width: 8,
                              ),
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(bottom: 6),
                                child: const Text(
                                  'testlongermaill@gmail.com',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const VerticalDivider(
                      color: Colors.grey,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Hasn't purchased since 30 days ago",
                              style: TextStyle(fontSize: 14),
                            ),
                            Container(
                              decoration: BoxDecoration(),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 32,
                        ),
                        Container(
                          width: 248,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: Text(
                                  "Created on: 04/03/2024",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Spacer(),
                              TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Complete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: TextButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 4, 108, 169),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(2))))
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 8,
              ),
            ],
          ),
        )
      ],
    );
  }
}
