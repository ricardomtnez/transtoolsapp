import 'package:flutter/material.dart';
import 'package:transtools/api/login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:transtools/models/usuario.dart';
import 'package:transtools/views/dashboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

Future<bool> isConnectedToInternet() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  // Para dispositivos que devuelven una lista
  return connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.contains(ConnectivityResult.wifi);
}

class LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscureText = true;
  // AQUÍ VA el método _handleLogin
  // En tu método _handleLogin en la vista
  Future<void> _handleLogin() async {
    final isConnected = await isConnectedToInternet();

    if (!mounted) return;

    if (!isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sin conexión a internet')));
      return;
    }

    final email = emailController.text.trim();
    final inputPassword = passwordController.text.trim();

    final loginController = LoginController();
    final userData = await loginController.loginUser(email);

    if (!mounted) return;

    if (userData != null) {
      final storedPassword = userData['password'] ?? '';
      if (storedPassword == inputPassword) {
        // Creamos objeto Usuario
        Usuario usuario = Usuario(
          fullname: userData['fullname'] ?? '',
          departamento: userData['departamento'] ?? '',
          password: storedPassword,
          email: email,
          initials: userData['iniciales'] ?? '',
        );

        // Serializamos a json
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', usuario.toJson());

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contraseña incorrecta')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/transtools_logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                    const Text("Logo no disponible"),
              ),
              const SizedBox(height: 20),

              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Correo
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue[700]!,
                      width: 2,
                    ), // Borde cuando está enfocado
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contraseña con ojito
              TextField(
                controller: passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue[700]!,
                      width: 2,
                    ), // Borde cuando está enfocado
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Icono para mostrar/ocultar contraseña
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}
