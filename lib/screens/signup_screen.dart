// ignore_for_file: use_build_context_synchronously

import 'package:event_manager/components/components.dart';
import 'package:event_manager/components/constants.dart';
import 'package:event_manager/screens/login_screen.dart';

import 'package:event_manager/shared/functions.dart';
import 'package:event_manager/shared/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'package:loading_overlay/loading_overlay.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signup_screen';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  late String _email = "";
  late String _password = "";
  late String _confirmPass = "";
  late String _username = "";
  late String _contactno = "";
  late String _bankdetails = "";
  late String _account = "";
  bool _saving = false;
  void _saveUsernameToFirestore() async {
    try {
      await SignIn.saveUserData(
          _username, _email, _contactno, _account, _bankdetails);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successfull')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _saving,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TopScreenImage(screenImageName: 'logo.png'),
                  Flexible(
                    fit: FlexFit.loose,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ScreenTitle(title: 'Sign Up'),
                          CustomTextField(
                            textField: TextField(
                              onChanged: (value) {
                                _email = value;
                              },
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Email',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: CustomTextField(
                              textField: TextField(
                                onChanged: (value) {
                                  _username = value;
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                  hintText: 'User Name',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: CustomTextField(
                              textField: TextField(
                                obscureText: true,
                                onChanged: (value) {
                                  _password = value;
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                  hintText: 'Password',
                                ),
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _confirmPass = value;
                              },
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Confirm Password',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: CustomTextField(
                              textField: TextField(
                                onChanged: (value) {
                                  _contactno = value;
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                  hintText: 'Contact No.',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: CustomTextField(
                              textField: TextField(
                                onChanged: (value) {
                                  _bankdetails = value;
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                  hintText:
                                      'Payment Method (easypaisa , jazz cash , bank)',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            child: CustomTextField(
                              textField: TextField(
                                onChanged: (value) {
                                  _account = value;
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                decoration: kTextInputDecoration.copyWith(
                                  hintText: 'Account Number (for Admin Only)',
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: CustomBottomScreen(
                              textButton: 'Sign Up',
                              heroTag: 'signup_btn',
                              question: 'Have an account? Login',
                              buttonPressed: () async {
                                FocusManager.instance.primaryFocus?.unfocus();

                                if (_confirmPass == _password &&
                                    _email.isNotEmpty &&
                                    _password.isNotEmpty &&
                                    _confirmPass.isNotEmpty &&
                                    _password.length >= 6) {
                                  _saveUsernameToFirestore();
                                  try {
                                    setState(() {
                                      _saving = true;
                                    });
                                    await _auth.createUserWithEmailAndPassword(
                                      email: _email,
                                      password: _password,
                                    );

                                    if (context.mounted) {
                                      signUpAlert(
                                        context: context,
                                        title: 'Success!',
                                        desc: 'You can login now',
                                        btnText: 'Login Now',
                                        onPressed: () {
                                          setState(() {
                                            _saving = false;
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SignUpScreen()),
                                            );
                                          });
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LoginScreen()),
                                          );
                                        },
                                      ).show();
                                      setState(() {
                                        _saving = false;
                                      });
                                    }
                                  } catch (e) {
                                    signUpAlert(
                                      context: context,
                                      onPressed: () {
                                        setState(() {
                                          _saving = false;
                                        });
                                        SystemNavigator.pop();
                                      },
                                      title: 'SOMETHING WRONG',
                                      desc: 'Close the app and try again',
                                      btnText: 'Close Now',
                                    );
                                  }
                                } else if (_email.isEmpty ||
                                    _password.isEmpty ||
                                    _confirmPass.isEmpty) {
                                  setState(() {
                                    _saving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All fields are required.'),
                                    ),
                                  );
                                } else if (_password.length < 6) {
                                  setState(() {
                                    _saving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Password should be greater than 6'),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _saving = false;
                                  });
                                  showAlert(
                                    context: context,
                                    title: 'WRONG PASSWORD',
                                    desc:
                                        'Make sure that you write the same password twice',
                                    onPressed: () {
                                      setState(() {
                                        _saving = false;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ).show();
                                }
                              },
                              questionPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
