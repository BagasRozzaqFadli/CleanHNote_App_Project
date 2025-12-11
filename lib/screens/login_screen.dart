import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import '../utils/logger.dart';
import '../widgets/safe_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.log('LoginScreen initState called', tag: 'LoginScreen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
    AppLogger.log('LoginScreen disposed', tag: 'LoginScreen');
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.log(
        'Attempting login for: ${_emailController.text}',
        tag: 'LoginScreen',
      );
      await context.read<AuthService>().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      AppLogger.log(
        'Login successful for: ${_emailController.text}',
        tag: 'LoginScreen',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Login failed: $e',
        tag: 'LoginScreen',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String error) {
    String title;
    String message;
    IconData icon;
    Color color;

    // Parse Firebase error codes
    if (error.contains('invalid-credential') ||
        error.contains('wrong-password')) {
      title = '❌ Login Gagal';
      message =
          'Email atau password yang Anda masukkan salah.\n\nSilakan coba lagi!';
      icon = Icons.lock_outline;
      color = Colors.red;
    } else if (error.contains('user-not-found')) {
      title = '👤 Akun Tidak Ditemukan';
      message =
          'Email "${_emailController.text}" belum terdaftar.\n\nSilakan daftar terlebih dahulu!';
      icon = Icons.person_off;
      color = Colors.orange;
    } else if (error.contains('invalid-email')) {
      title = '📧 Email Tidak Valid';
      message =
          'Format email yang Anda masukkan tidak benar.\n\nContoh: nama@email.com';
      icon = Icons.email_outlined;
      color = Colors.orange;
    } else if (error.contains('user-disabled')) {
      title = '🚫 Akun Diblokir';
      message =
          'Akun Anda telah diblokir oleh administrator.\n\nHubungi admin untuk bantuan.';
      icon = Icons.block;
      color = Colors.red.shade900;
    } else if (error.contains('network')) {
      title = '📡 Koneksi Bermasalah';
      message =
          'Tidak dapat terhubung ke server.\n\nPeriksa koneksi internet Anda!';
      icon = Icons.wifi_off;
      color = Colors.blue;
    } else {
      title = '⚠️ Terjadi Kesalahan';
      message = 'Maaf, terjadi kesalahan.\n\nSilakan coba lagi!';
      icon = Icons.error_outline;
      color = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.log('Attempting Google Sign In', tag: 'LoginScreen');
      final result = await context.read<AuthService>().signInWithGoogle();
      if (result == null) {
        AppLogger.log('Google Sign In cancelled', tag: 'LoginScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        AppLogger.log('Google Sign In successful', tag: 'LoginScreen');
      }
    } catch (e, stack) {
      AppLogger.error(
        'Google Sign In failed: $e',
        tag: 'LoginScreen',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueAccent],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selamat datang di CleanHNote',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ruang bersih, pikiran segar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _isLoading ? null : _performLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton.icon(
                            onPressed: _isLoading ? null : _performGoogleSignIn,
                            icon: SafeNetworkImage(
                              imageUrl:
                                  'https://developers.google.com/identity/images/g-logo.png',
                              height: 24,
                              width: 24,
                              loadingError: true,
                            ),
                            label: const Text('Masuk dengan Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        if (!_isLoading) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          );
                        }
                      },
                      child: const Text(
                        'Belum punya akun? Daftar',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
