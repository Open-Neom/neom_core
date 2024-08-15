import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/domain/model/app_user.dart';
import '../../../core/utils/app_utilities.dart';

class WooUsersApi {
  Future<void> createWooCommerceUser(AppUser user) async {
    final url = Uri.parse('https://tudominio.com/wp-json/wc/v3/customers');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic <tu_clave_api>',
    };
    final body = jsonEncode({
      'username': user.email,
      'email': user.email,
      'password': user.password,
      // ... otros campos personalizados
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 201) {
      AppUtilities.logger.i('Usuario creado exitosamente en WooCommerce');
    } else {
      AppUtilities.logger.e('Error al crear usuario: ${response.body}');
    }
  }
}