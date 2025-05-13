import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import '../presentation/screens/saved_addresses_screen.dart';

class AddressRemoteDatasource {
  final Dio dio;
  AddressRemoteDatasource(this.dio);

  Future<List<Address>> getAddresses(String token) async {
    final response = await dio.get(
      ApiEndpoints.addresses,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data['data'] as List;
    return data.map((json) => Address.fromJson(json)).toList();
  }

  Future<Address> createAddress(Address address, String token) async {
    final response = await dio.post(
      ApiEndpoints.addresses,
      data: address.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Address.fromJson(response.data['data']);
  }

  Future<Address> updateAddress(Address address, String token) async {
    final response = await dio.put(
      ApiEndpoints.addressById(address.id),
      data: address.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Address.fromJson(response.data['data']);
  }

  Future<void> deleteAddress(int id, String token) async {
    await dio.delete(
      ApiEndpoints.addressById(id),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
