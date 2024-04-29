import 'package:flutter/material.dart';

class ItemSearchAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color.fromARGB(255, 0, 76, 135),
        padding: EdgeInsets.all(14),
        child: Row(children: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              )),
          Spacer(),
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 30,
              )),
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Colors.white,
                size: 30,
              ))
        ]));
  }
}
