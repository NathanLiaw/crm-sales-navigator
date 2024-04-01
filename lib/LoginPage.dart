import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text('F.Y.H'),
      //   backgroundColor: Colors.white,
      // ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  // alignment: Alignment.topCenter,
                  'asset/logo/fyh_logo.png',
                  width: 300,
                  height: 300,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left: 20,
                ),
                child: Text(
                  'Salesman',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Container(
                margin:
                    EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    // hintText: 'fyh@mail.com',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                child: TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Implement sign-in logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff0069BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Implement forgot password logic here
                },
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
