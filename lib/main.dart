import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loja_virtual/models/user_manager.dart';
import 'package:loja_virtual/screens/address/address_screen.dart';
import 'package:loja_virtual/screens/base/base_screen.dart';
import 'package:loja_virtual/screens/cart/cart_screen.dart';
import 'package:loja_virtual/screens/checkout/checkout_screen.dart';
import 'package:loja_virtual/screens/confirmation/confirmation_screen.dart';
import 'package:loja_virtual/screens/edit_product/edit_product_screen.dart';
import 'package:loja_virtual/screens/login/login_screen.dart';
import 'package:loja_virtual/screens/product/product_screen.dart';
import 'package:loja_virtual/screens/select_product/select_product_screen.dart';
import 'package:provider/provider.dart';
import 'models/admin_orders_manager.dart';
import 'models/admin_users_manager.dart';
import 'models/cart_manager.dart';
import 'models/home_manager.dart';
import 'models/order.dart';
import 'models/orders_manager.dart';
import 'models/product.dart';
import 'models/product_manager.dart';
import 'models/stores_manager.dart';
import 'screens/signup/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => UserManager(),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => StoresManager(),
          ),
          ChangeNotifierProvider(
            create: (_) => ProductManager(),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => HomeManager(),
            lazy: false,
          ),
          ChangeNotifierProxyProvider<UserManager, CartManager>(
            create: (_) => CartManager(),
            lazy: false,
            update: (_, userManager, cartManager) =>
                cartManager..updateUser(userManager),
          ),
          ChangeNotifierProxyProvider<UserManager, AdminOrdersManager>(
            create: (_) => AdminOrdersManager(),
            lazy: false,
            update: (_, userManager, adminOrdersManager) => adminOrdersManager
              ..updateAdmin(adminEnabled: userManager.adminEnabled),
          ),
          ChangeNotifierProxyProvider<UserManager, OrdersManager>(
            create: (_) => OrdersManager(),
            lazy: false,
            update: (_, userManager, ordersManager) =>
                ordersManager..updateUser(userManager.user),
          ),
          ChangeNotifierProxyProvider<UserManager, AdminUsersManager>(
            create: (_) => AdminUsersManager(),
            lazy: false,
            update: (_, userManager, adminUsersManager) =>
                adminUsersManager..updateUser(userManager),
          )
        ],
        child: MaterialApp(
          title: 'Loja Virtual',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color.fromARGB(255, 4, 125, 141),
            scaffoldBackgroundColor: const Color.fromARGB(255, 4, 125, 141),
            appBarTheme: const AppBarTheme(elevation: 0),
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/signup':
                return MaterialPageRoute(builder: (_) => SignUpScreen());
              case '/edit_product':
                return MaterialPageRoute(
                    builder: (_) =>
                        EditProductScreen(settings.arguments as Product));

              case '/select_product':
                return MaterialPageRoute(builder: (_) => SelectProductScreen());
              case '/address':
                return MaterialPageRoute(builder: (_) => AddressScreen());
              case '/confirmation':
                return MaterialPageRoute(
                    builder: (_) =>
                        ConfirmationScreen(settings.arguments as Order));
              case '/':
                return MaterialPageRoute(
                    builder: (_) => BaseScreen(), settings: settings);
              case '/checkout':
                return MaterialPageRoute(builder: (_) => CheckoutScreen());
              case '/cart':
                return MaterialPageRoute(
                    builder: (_) => CartScreen(), settings: settings);
              case '/product':
                return MaterialPageRoute(
                    builder: (_) =>
                        ProductScreen(settings.arguments as Product));
              case '/login':
              default:
                return MaterialPageRoute(builder: (_) => LoginScreen());
            }
          },
        ));
  }
}
