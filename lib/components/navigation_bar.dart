import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sales_navigator/db_sqlite.dart';
import 'package:sales_navigator/utility_function.dart';
import 'dart:developer' as developer;

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  static int _selectedIndex = 0;
  bool _isVisible = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        _isVisible = false;
      });
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: _isVisible ? 60 : 0,
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              tabBorderRadius: 6,
              gap: 7,
              selectedIndex: _selectedIndex,
              color: Colors.grey,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              duration: const Duration(milliseconds: 500),
              tabBackgroundColor: Color.fromARGB(255, 48, 162, 250),
              tabs: [
                const GButton(
                  icon: Icons.home,
                  text: 'Home',
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const GButton(
                  icon: Icons.sell,
                  text: 'Sales',
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const GButton(
                  icon: Icons.shopping_bag,
                  text: 'Product',
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GButton(
                  icon: const IconData(0),
                  text: 'Cart',
                  leading: buildCartIcon(),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const GButton(
                  icon: Icons.person,
                  text: 'Profile',
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    if (ModalRoute.of(context)!.settings.name != '/home') {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                    break;
                  case 1:
                    if (ModalRoute.of(context)!.settings.name != '/sales') {
                      Navigator.pushReplacementNamed(context, '/sales');
                    }
                    break;
                  case 2:
                    if (ModalRoute.of(context)!.settings.name != '/product') {
                      Navigator.pushReplacementNamed(context, '/product');
                    }
                    break;
                  case 3:
                    if (ModalRoute.of(context)!.settings.name != '/cart') {
                      Navigator.pushNamed(context, '/cart');
                    }
                    break;
                  case 4:
                    if (ModalRoute.of(context)!.settings.name != '/profile') {
                      Navigator.pushReplacementNamed(context, '/profile');
                    }
                    break;
                  default:
                    if (ModalRoute.of(context)!.settings.name != '/home') {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                    break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCartIcon() {
    bool isSelected = _selectedIndex == 3;

    return FutureBuilder<int>(
      future: getNumberOfItemsInCart(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int? countCartItem = snapshot.data;
          return Stack(
            children: [
              Icon(
                Icons.shopping_cart,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              if (countCartItem != null)
                Positioned(
                  bottom: 4,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Text(
                      '$countCartItem',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  Future<int> getNumberOfItemsInCart() async {
    final userId = await UtilityFunction.getUserId();

    try {
      const tableName = 'cart_item';
      final condition = "buyer_id = $userId AND status = 'in progress'";

      final db = await DatabaseHelper.database;

      final itemCount = await DatabaseHelper.countData(
        db,
        tableName,
        condition,
      );

      return itemCount;
    } catch (e) {
      developer.log('Error fetching count of cart items: $e', error: e);
      return 0;
    }
  }
}
