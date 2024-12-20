import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_navigator/cached_page_manager.dart';
import 'package:sales_navigator/screens/cart/cart_page.dart';
import 'package:sales_navigator/components/navigation_provider.dart';
import 'package:sales_navigator/screens/home/home_page.dart';
import 'package:sales_navigator/model/cart_model.dart';
import 'package:sales_navigator/screens/product/products_screen.dart';
import 'package:sales_navigator/screens/profile/profile_page.dart';
import 'package:sales_navigator/screens/sales_order/sales_order_page.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  void _handleNavigation(BuildContext context, int index) {
    final navigationProvider =
        Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setSelectedIndex(index);

    final String currentRoute =
        ModalRoute.of(context)?.settings.name ?? '/home';
    String targetRoute;

    switch (index) {
      case 0:
        targetRoute = '/home';
        break;
      case 1:
        targetRoute = '/sales';
        break;
      case 2:
        targetRoute = '/product';
        break;
      case 3:
        targetRoute = '/cart';
        break;
      case 4:
        targetRoute = '/profile';
        break;
      default:
        targetRoute = '/home';
    }

    if (currentRoute != targetRoute) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: RouteSettings(name: targetRoute),
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          pageBuilder: (context, animation, secondaryAnimation) {
            Widget page = CachedPageManager.getCachedPage(targetRoute, () {
              switch (targetRoute) {
                case '/home':
                  return const HomePage();
                case '/sales':
                  return const SalesOrderPage();
                case '/product':
                  return const ProductsScreen();
                case '/cart':
                  return const CartPage();
                case '/profile':
                  return const ProfilePage();
                default:
                  return const HomePage();
              }
            });

            return FadeTransition(
              opacity: animation,
              child: page,
            );
          },
        ),
      );
    }
  }

  Widget _buildCachedPage(String route) {
    return CachedPageManager.getCachedPage(route, () {
      switch (route) {
        case '/home':
          return const HomePage();
        case '/sales':
          return const SalesOrderPage();
        case '/product':
          return const ProductsScreen();
        case '/cart':
          return const CartPage();
        case '/profile':
          return const ProfilePage();
        default:
          return const HomePage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Container(
          height: 80,
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
                onDestinationSelected: (index) =>
                    _handleNavigation(context, index),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    icon: Badge(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
        );
      },
    );
  }
}
