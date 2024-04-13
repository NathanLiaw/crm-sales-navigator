// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:google_nav_bar/google_nav_bar.dart';

// class CustomNavigationBar extends StatefulWidget {
//   @override
//   _CustomNavigationBarState createState() => _CustomNavigationBarState();
// }

// class _CustomNavigationBarState extends State<CustomNavigationBar> {
//   static int _selectedIndex = 0;
//   bool _isVisible = true;

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       height: _isVisible ? 60 : 0,
//       duration: Duration(milliseconds: 300),
//       child: Scaffold(
//         bottomNavigationBar: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
//             ],
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
//             child: GNav(
//               gap: 7,
//               selectedIndex: _selectedIndex,
//               color: Colors.grey,
//               activeColor: Colors.white,
//               iconSize: 24,
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               duration: Duration(milliseconds: 500),
//               tabBackgroundColor: Color(0xff0069BA),
//               tabs: [
//                 GButton(
//                   icon: Icons.home,
//                   text: 'Home',
//                 ),
//                 GButton(
//                   icon: Icons.sell,
//                   text: 'Sales',
//                 ),
//                 GButton(
//                   icon: Icons.shopping_bag,
//                   text: 'Product',
//                 ),
//                 GButton(
//                   // icon: Icons.shopping_cart,
//                   icon: IconData(0),
//                   text: 'Cart',
//                   leading: buildCartIcon(),
//                 ),
//                 GButton(
//                   icon: Icons.person,
//                   text: 'Profile',
//                 ),
//               ],
//               // selectedIndex: _selectedIndex,
//               onTabChange: (index) {
//                 setState(() {
//                   _selectedIndex = index;
//                 });
//                 switch (index) {
//                   case 0:
//                     if (ModalRoute.of(context)!.settings.name != '/home') {
//                       Navigator.pushReplacementNamed(context, '/home');
//                     }
//                     break;
//                   case 1:
//                     if (ModalRoute.of(context)!.settings.name != '/sales') {
//                       Navigator.pushReplacementNamed(context, '/sales');
//                     }
//                     break;
//                   case 2:
//                     if (ModalRoute.of(context)!.settings.name != '/product') {
//                       Navigator.pushReplacementNamed(context, '/product');
//                     }
//                     break;
//                   case 3:
//                     if (ModalRoute.of(context)!.settings.name != '/cart') {
//                       Navigator.pushReplacementNamed(context, '/cart');
//                     }
//                     break;
//                   case 4:
//                     if (ModalRoute.of(context)!.settings.name != '/profile') {
//                       Navigator.pushReplacementNamed(context, '/profile');
//                     }
//                     break;
//                   default:
//                     if (ModalRoute.of(context)!.settings.name != '/home') {
//                       Navigator.pushReplacementNamed(context, '/home');
//                     }
//                     break;
//                 }
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildCartIcon() {
//     bool isSelected = _selectedIndex == 3; // Check if cart is selected

//     return Stack(
//       children: [
//         Icon(
//           Icons.shopping_cart,
//           color: isSelected
//               ? Colors.white
//               : Colors.grey, // Set icon color based on selection
//         ),
//         Positioned(
//           top: 0,
//           right: 0,
//           child: Container(
//             padding: EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.red,
//             ),
//             child: Text(
//               '13',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 7,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _scrollListener();
//   }

//   void _scrollListener() {
//     ScrollController _controller = ScrollController();
//     _controller.addListener(() {
//       if (_controller.position.userScrollDirection == ScrollDirection.reverse) {
//         setState(() {
//           _isVisible = false;
//         });
//       }
//       if (_controller.position.userScrollDirection == ScrollDirection.forward) {
//         setState(() {
//           _isVisible = true;
//         });
//       }
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sales_navigator/cart_page.dart';
import 'package:sales_navigator/home_page.dart';
import 'package:sales_navigator/product_page.dart';
import 'package:sales_navigator/profile_page.dart';
import 'package:sales_navigator/sales_page.dart';

class CustomNavigationBar extends StatefulWidget {
  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  static int _selectedIndex = 0;
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: _isVisible ? 60 : 0,
      duration: Duration(milliseconds: 300),
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              gap: 7,
              selectedIndex: _selectedIndex,
              color: Colors.grey,
              activeColor: Colors.white,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              duration: Duration(milliseconds: 500),
              tabBackgroundColor: Color(0xff0069BA),
              tabs: [
                GButton(
                  icon: Icons.home,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.sell,
                  text: 'Sales',
                ),
                GButton(
                  icon: Icons.shopping_bag,
                  text: 'Product',
                ),
                GButton(
                  icon: Icons.shopping_cart,
                  text: 'Cart',
                  leading: buildCartIcon(),
                ),
                GButton(
                  icon: Icons.person,
                  text: 'Profile',
                ),
              ],
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    if (ModalRoute.of(context)!.settings.name != '/home') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => HomePage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    }
                    break;
                  case 1:
                    if (ModalRoute.of(context)!.settings.name != '/sales') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => SalesPage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    }
                    break;
                  case 2:
                    if (ModalRoute.of(context)!.settings.name != '/product') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProductPage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    }
                    break;
                  case 3:
                    if (ModalRoute.of(context)!.settings.name != '/cart') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => CartPage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    }
                    break;
                  case 4:
                    if (ModalRoute.of(context)!.settings.name != '/profile') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProfilePage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    }
                    break;
                  default:
                    if (ModalRoute.of(context)!.settings.name != '/home') {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => HomePage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
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

    return Stack(
      children: [
        Icon(
          Icons.shopping_cart,
          color: isSelected ? Colors.white : Colors.grey,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: Text(
              '13',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollListener();
  }

  void _scrollListener() {
    ScrollController _controller = ScrollController();
    _controller.addListener(() {
      if (_controller.position.userScrollDirection == ScrollDirection.reverse) {
        setState(() {
          _isVisible = false;
        });
      }
      if (_controller.position.userScrollDirection == ScrollDirection.forward) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }
}
