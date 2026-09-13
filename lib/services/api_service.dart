import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api',
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  final StorageService _storageService = StorageService();

  //*el registro
  Future<Response> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  // *el login
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  //*tener el token
  Future<Options> _authOptions() async {
    final token = await _storageService.getToken();

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  //*tener notas
  Future<Response> getNotes() async {
    final options = await _authOptions();

    return await _dio.get(
      '/notes',
      options: options,
    );
  }

  //*crea la nota
  Future<Response> createNote({
    required String title,
    required String content,
  }) async {
    final options = await _authOptions();

    return await _dio.post(
      '/notes',
      options: options,
      data: {
        'title': title,
        'content': content,
      },
    );
  }

  //*actualiza
  Future<Response> updateNote({
    required int id,
    required String title,
    required String content,
  }) async {
    final options = await _authOptions();

    return await _dio.put(
      '/notes/$id',
      options: options,
      data: {
        'title': title,
        'content': content,
      },
    );
  }

  //*elimina
  Future<Response> deleteNote(int id) async {
    final options = await _authOptions();

    return await _dio.delete(
      '/notes/$id',
      options: options,
    );
  }
    //*mira la conexion a internet o con el servidor

  Future<bool> isOnline() async {
    try {
      final testDio = Dio();

      final response = await testDio.get(
        'http://localhost:3000/',
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}