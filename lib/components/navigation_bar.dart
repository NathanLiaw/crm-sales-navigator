import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/components/navigation_provider.dart';
import 'package:sales_navigator/model/cart_model.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return AnimatedContainer(
          height: 80, // Set height directly; use visibility logic if needed
          duration: const Duration(milliseconds: 300),
          child: Scaffold(
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Consumer<CartModel>(
                builder: (context, cartModel, child) {
                  return NavigationBar(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    onDestinationSelected: (int index) {
                      navigationProvider.setSelectedIndex(index);
                      switch (index) {
                        case 0:
                          Navigator.pushReplacementNamed(context, '/home');
                          break;
                        case 1:
                          Navigator.pushReplacementNamed(context, '/sales');
                          break;
                        case 2:
                          Navigator.pushReplacementNamed(context, '/product');
                          break;
                        case 3:
                          Navigator.pushReplacementNamed(context, '/cart');
                          break;
                        case 4:
                          Navigator.pushReplacementNamed(context, '/profile');
                          break;
                        default:
                          Navigator.pushReplacementNamed(context, '/home');
                          break;
                      }
                    },
                    indicatorColor: const Color(0xff0175FF),
                    selectedIndex: navigationProvider.selectedIndex,
                    destinations: <Widget>[
                      const NavigationDestination(
                        selectedIcon: Icon(Icons.home, color: Colors.white),
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      const NavigationDestination(
                        selectedIcon: Icon(Icons.sell, color: Colors.white),
                        icon: Icon(Icons.sell_outlined),
                        label: 'Sales',
                      ),
                      const NavigationDestination(
                        selectedIcon: Icon(Icons.shopping_bag, color: Colors.white),
                        icon: Icon(Icons.shopping_bag_outlined),
                        label: 'Product',
                      ),
                      NavigationDestination(
                        selectedIcon: Badge(
                          label: Text(
                            cartModel.cartItemCount.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Icon(Icons.shopping_cart, color: Colors.white),
                        ),
                        icon: Badge(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          label: Text(
                            cartModel.cartItemCount.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined),
                        ),
                        label: 'Cart',
                      ),
                      const NavigationDestination(
                        selectedIcon: Icon(Icons.person, color: Colors.white),
                        icon: Icon(Icons.person_outline),
                        label: 'Profile',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
