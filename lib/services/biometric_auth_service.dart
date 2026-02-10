import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service d'authentification biométrique (empreinte/Face ID)
class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._init();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _biometricEnabledKey = 'biometric_auth_enabled';

  BiometricAuthService._init();

  /// Vérifier si l'appareil supporte la biométrie
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('❌ Erreur canCheckBiometrics: $e');
      return false;
    }
  }

  /// Vérifier si l'authentification est disponible
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('❌ Erreur isDeviceSupported: $e');
      return false;
    }
  }

  /// Obtenir les biométries disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('❌ Erreur getAvailableBiometrics: $e');
      return [];
    }
  }

  /// Vérifier si la biométrie est activée dans les paramètres
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Activer/Désactiver la biométrie
  Future<bool> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Authentifier l'utilisateur
  Future<bool> authenticate({
    String reason = 'Veuillez vous authentifier pour continuer',
  }) async {
    try {
      // Vérifier si la biométrie est disponible
      final canCheck = await canCheckBiometrics();
      final isSupported = await isDeviceSupported();

      if (!canCheck || !isSupported) {
        debugPrint('⚠️ Biométrie non disponible sur cet appareil');
        return false;
      }

      // Obtenir les types disponibles
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        debugPrint('⚠️ Aucune biométrie configurée sur l\'appareil');
        return false;
      }

      // Afficher le type de biométrie disponible
      String biometricType = 'biométrique';
      if (availableBiometrics.contains(BiometricType.face)) {
        biometricType = 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricType = 'empreinte digitale';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricType = 'iris';
      }

      debugPrint('🔐 Tentative d\'authentification par $biometricType...');

      // Authentifier
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permettre le code PIN comme fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        debugPrint('✅ Authentification réussie');
      } else {
        debugPrint('❌ Authentification échouée');
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('❌ Erreur lors de l\'authentification: ${e.message}');
      
      // Gérer les erreurs spécifiques
      if (e.code == 'NotAvailable') {
        debugPrint('⚠️ Biométrie non disponible');
      } else if (e.code == 'NotEnrolled') {
        debugPrint('⚠️ Aucune biométrie enregistrée');
      } else if (e.code == 'LockedOut') {
        debugPrint('⚠️ Trop de tentatives, authentification verrouillée temporairement');
      } else if (e.code == 'PermanentlyLockedOut') {
        debugPrint('⚠️ Authentification définitivement verrouillée');
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      return false;
    }
  }

  /// Arrêter l'authentification en cours
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      debugPrint('🛑 Authentification arrêtée');
    } catch (e) {
      debugPrint('❌ Erreur stopAuthentication: $e');
    }
  }

  /// Vérifier si on peut activer la biométrie (appareil compatible + biométrie configurée)
  Future<bool> canEnableBiometric() async {
    final canCheck = await canCheckBiometrics();
    final isSupported = await isDeviceSupported();
    final available = await getAvailableBiometrics();
    
    return canCheck && isSupported && available.isNotEmpty;
  }

  /// Obtenir une description lisible des biométries disponibles
  Future<String> getBiometricsDescription() async {
    final availableBiometrics = await getAvailableBiometrics();
    
    if (availableBiometrics.isEmpty) {
      return 'Aucune biométrie disponible';
    }

    final List<String> types = [];
    
    if (availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Empreinte digitale');
    }
    if (availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }
    if (availableBiometrics.contains(BiometricType.strong)) {
      types.add('Biométrie forte');
    }
    if (availableBiometrics.contains(BiometricType.weak)) {
      types.add('Biométrie faible');
    }

    return types.join(', ');
  }

  /// Obtenir un message d'erreur adapté
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'NotAvailable':
        return 'La biométrie n\'est pas disponible sur cet appareil';
      case 'NotEnrolled':
        return 'Aucune biométrie n\'est enregistrée. Veuillez en configurer une dans les paramètres de votre appareil';
      case 'LockedOut':
        return 'Trop de tentatives échouées. Veuillez réessayer dans quelques instants';
      case 'PermanentlyLockedOut':
        return 'L\'authentification biométrique est bloquée. Utilisez votre code PIN';
      case 'PasscodeNotSet':
        return 'Aucun code de verrouillage n\'est défini sur l\'appareil';
      default:
        return 'Erreur d\'authentification biométrique';
    }
  }
}
