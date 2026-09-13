import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'register_screen.dart';
import 'notes_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('====================================');
      print('ENVIANDO LOGIN');
      print('Correo: ${_emailController.text.trim()}');
      print('====================================');

      final response = await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('RESPUESTA DEL SERVIDOR:');
      print(response.data);

      final token = response.data['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('El servidor no devolvió el token');
      }

      await _storageService.saveToken(token);
      await _storageService.saveSession();

      print('====================================');
      print('LOGIN EXITOSO');
      print('JWT GUARDADO CORRECTAMENTE');
      print('====================================');

      if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const NotesScreen(),
      ),
    );
    } on DioException catch (e) {
      print('====================================');
      print('ERROR DE DIO');
      print('Mensaje: ${e.message}');
      print('URL: ${e.requestOptions.uri}');
      print('Método: ${e.requestOptions.method}');
      print('Código de estado: ${e.response?.statusCode}');
      print('Respuesta: ${e.response?.data}');
      print('====================================');

      if (!mounted) return;

      String mensaje;

      if (e.response != null) {
        if (e.response!.data is Map) {
          mensaje =
              e.response!.data['mensaje'] ?? 'Error del servidor';
        } else {
          mensaje = 'Error del servidor: ${e.response!.statusCode}';
        }
      } else {
        mensaje = 'No se pudo conectar con el servidor';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
        ),
      );
    } catch (e) {
      print('====================================');
      print('ERROR GENERAL');
      print(e);
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
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
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu correo';
                  }

                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Crear una cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

