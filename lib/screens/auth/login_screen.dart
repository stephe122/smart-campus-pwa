import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahsa_navigation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true; 
  bool _isObscure = true;

  // --- 1. NEW: FORGOT PASSWORD FUNCTION ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    resetEmailController.text = _emailController.text; // Pre-fill email

    showDialog(
      context: context,
      // Change to dialogContext to avoid confusing the linter
      builder: (dialogContext) => AlertDialog(
        title: Text("Reset Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter your email address and we'll send you a link to reset your password.", style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            // Use dialogContext to close
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text("Please enter an email.")));
                return;
              }
              
              // --- THE FIX: Capture the messengers and navigators BEFORE the await ---
              final dialogNav = Navigator.of(dialogContext);
              final mainMessenger = ScaffoldMessenger.of(context);
              
              try {
                // The async gap
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                
                // Safely use the captured variables (No BuildContext across async gap)
                dialogNav.pop(); 
                mainMessenger.showSnackBar(
                  const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
                );
              } catch (e) {
                // Safely use the captured messenger
                mainMessenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    
    // --- THE FIX: Capture the main screen's navigator and messenger BEFORE the await ---
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      if (_isLogin) {
        // The async gap
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // The async gap
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      
      // Safely navigate using the captured 'nav' variable
      nav.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
    } on FirebaseAuthException catch (e) {
      // Safely show error using the captured 'messenger' variable
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Authentication Failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mahsaBlue = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 80, color: mahsaBlue),
                  const SizedBox(height: 20),
                  Text(
                    "MAHSA UNIVERSITY",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mahsaBlue,
                    ),
                  ),
                  Text(
                    _isLogin ? "Student Login" : "Create Account",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email, color: mahsaBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock, color: mahsaBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  
                  // --- 2. FORGOT PASSWORD BUTTON (Only shows in Login mode) ---
                  if (_isLogin) 
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            color: mahsaBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 30), // Spacing for signup mode

                  if (_isLogin) const SizedBox(height: 10), // extra spacing after forgot password

                  // Login/Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mahsaBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLogin ? "LOGIN" : "SIGN UP",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle Button
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "New Student? Create Account"
                          : "Already have an account? Login",
                      style: const TextStyle(color: mahsaBlue),
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