import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'address_remote_datasource.dart';
import '../presentation/screens/saved_addresses_screen.dart';
import '../../auth/domain/providers/auth_provider.dart';
import 'package:dio/dio.dart';

class AddressProvider extends ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  late AddressRemoteDatasource _datasource;

  AddressProvider(Dio dio) {
    _datasource = AddressRemoteDatasource(dio);
  }

  Future<void> fetchAddresses(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('No auth token');
      _addresses = await _datasource.getAddresses(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(Address address, BuildContext context) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('No auth token');
      final newAddress = await _datasource.createAddress(address, token);
      _addresses.add(newAddress);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(Address address, BuildContext context) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('No auth token');
      final updated = await _datasource.updateAddress(address, token);
      final idx = _addresses.indexWhere((a) => a.id == address.id);
      if (idx != -1) _addresses[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(int id, BuildContext context) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('No auth token');
      await _datasource.deleteAddress(id, token);
      _addresses.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Address? get defaultAddress =>
      _addresses.firstWhereOrNull((a) => a.isDefault) ??
      (_addresses.isNotEmpty ? _addresses.first : null);
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
