import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
                  // icon: Icons.shopping_cart,
                  icon: IconData(0), // 移除原先的 icon
                  text: 'Cart',
                  leading: buildCartIcon(),
                ),
                GButton(
                  icon: Icons.person,
                  text: 'Profile',
                ),
              ],
              // selectedIndex: _selectedIndex,
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
                      Navigator.pushReplacementNamed(context, '/cart');
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
    bool isSelected = _selectedIndex == 3; // Check if cart is selected

    return Stack(
      children: [
        Icon(
          Icons.shopping_cart,
          color: isSelected
              ? Colors.white
              : Colors.grey, // Set icon color based on selection
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


//
// Old Code
//
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

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
//       child: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xff0069BA),
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//           switch (index) {
//             case 0:
//               if (ModalRoute.of(context)!.settings.name != '/home') {
//                 Navigator.pushReplacementNamed(context, '/home');
//               }
//               break;
//             case 1:
//               if (ModalRoute.of(context)!.settings.name != '/sales') {
//                 Navigator.pushReplacementNamed(context, '/sales');
//               }
//               break;
//             case 2:
//               if (ModalRoute.of(context)!.settings.name != '/product') {
//                 Navigator.pushReplacementNamed(context, '/product');
//               }
//               break;
//             case 3:
//               if (ModalRoute.of(context)!.settings.name != '/cart') {
//                 Navigator.pushReplacementNamed(context, '/cart');
//               }
//               break;
//             case 4:
//               if (ModalRoute.of(context)!.settings.name != '/profile') {
//                 Navigator.pushReplacementNamed(context, '/profile');
//               }
//               break;
//             default:
//               if (ModalRoute.of(context)!.settings.name != '/home') {
//                 Navigator.pushReplacementNamed(context, '/home');
//               }
//               break;
//           }
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//             backgroundColor:
//                 _selectedIndex == 0 ? Colors.blue : Colors.transparent,
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list),
//             label: 'Sales',
//             backgroundColor:
//                 _selectedIndex == 1 ? Colors.blue : Colors.transparent,
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_bag),
//             label: 'Product',
//             backgroundColor:
//                 _selectedIndex == 2 ? Colors.blue : Colors.transparent,
//           ),
//           BottomNavigationBarItem(
//             icon: buildCartIcon(),
//             label: 'Cart',
//             backgroundColor:
//                 _selectedIndex == 3 ? Colors.blue : Colors.transparent,
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.alternate_email),
//             label: 'Profile',
//             backgroundColor:
//                 _selectedIndex == 4 ? Colors.blue : Colors.transparent,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildCartIcon() {
//     return Stack(
//       children: [
//         Icon(Icons.shopping_cart),
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