import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userRepository.getUserByUsername(username);
      
      if (user != null && user.password == password && user.isActive == 1) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;
    final result = await _userRepository.updatePassword(_currentUser!.id!, newPassword);
    if (result > 0) {
      _currentUser = _currentUser!.copyWith(password: newPassword);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;
    final result = await _userRepository.deleteAccount(_currentUser!.id!);
    if (result > 0) {
      logout();
      return true;
    }
    return false;
  }
}
