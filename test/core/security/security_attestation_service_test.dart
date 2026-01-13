import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:crypto_wallet_pro/core/security/services/security_attestation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/attestation');

  late SecurityAttestationService service;

  setUp(() {
    service = SecurityAttestationService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    service.invalidateCache();
  });

  group('SecurityAttestationService - performAttestation', () {
    test('should perform Android Play Integrity attestation', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'ANDROID_ATTESTATION_TOKEN',
            'details': {'playProtect': 'enabled'},
          };
        }
        return null;
      });

      final result = await service.performAttestation();

      expect(result.deviceIntegrity, DeviceIntegrityState.trusted);
      expect(result.appIntegrity, AppIntegrityState.genuine);
      expect(result.environment, EnvironmentType.physicalDevice);
      expect(result.isSecure, true);
      expect(result.attestationToken, 'ANDROID_ATTESTATION_TOKEN');
    });

    test('should detect compromised device', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'compromised',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': null,
            'details': {'reason': 'rooted'},
          };
        }
        return null;
      });

      final result = await service.performAttestation();

      expect(result.deviceIntegrity, DeviceIntegrityState.compromised);
      expect(result.isSecure, false);
      expect(result.isCompromised, true);
    });

    test('should detect tampered app', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'tampered',
            'environment': 'physical_device',
            'token': null,
            'details': {'reason': 'sideloaded'},
          };
        }
        return null;
      });

      final result = await service.performAttestation();

      expect(result.appIntegrity, AppIntegrityState.tampered);
      expect(result.isSecure, false);
      expect(result.isCompromised, true);
    });

    test('should detect emulator', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'emulator',
            'token': null,
            'details': {},
          };
        }
        return null;
      });

      final result = await service.performAttestation();

      expect(result.environment, EnvironmentType.emulator);
      expect(result.isSecure, false);
    });

    test('should cache attestation result for 5 minutes', () async {
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          callCount++;
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'TOKEN',
            'details': {},
          };
        }
        return null;
      });

      // First call
      await service.performAttestation();

      // Second call within 5 minutes (should use cache)
      await service.performAttestation();

      expect(callCount, 1); // Only called once
    });

    test('should force refresh when requested', () async {
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          callCount++;
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'TOKEN_$callCount',
            'details': {},
          };
        }
        return null;
      });

      await service.performAttestation();
      final result = await service.performAttestation(forceRefresh: true);

      expect(callCount, 2); // Called twice
      expect(result.attestationToken, 'TOKEN_2');
    });
  });

  group('SecurityAttestationService - quickDeviceCheck', () {
    test('should perform quick device integrity check', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'quickDeviceCheck') {
          return 'trusted';
        }
        return null;
      });

      final state = await service.quickDeviceCheck();

      expect(state, DeviceIntegrityState.trusted);
    });

    test('should detect compromised state in quick check', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'quickDeviceCheck') {
          return 'compromised';
        }
        return null;
      });

      final state = await service.quickDeviceCheck();

      expect(state, DeviceIntegrityState.compromised);
    });
  });

  group('SecurityAttestationService - isEmulator', () {
    test('should return true when running on emulator', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isEmulator') {
          return true;
        }
        return null;
      });

      final isEmu = await service.isEmulator();

      expect(isEmu, true);
    });

    test('should return false on physical device', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isEmulator') {
          return false;
        }
        return null;
      });

      final isEmu = await service.isEmulator();

      expect(isEmu, false);
    });
  });

  group('SecurityAttestationService - refreshAttestationToken', () {
    test('should refresh and return new token', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'REFRESHED_TOKEN',
            'details': {},
          };
        }
        return null;
      });

      final token = await service.refreshAttestationToken();

      expect(token, 'REFRESHED_TOKEN');
    });
  });

  group('SecurityAttestationService - cache management', () {
    test('should return cached result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'TOKEN',
            'details': {},
          };
        }
        return null;
      });

      await service.performAttestation();
      final cached = service.getLastAttestationResult();

      expect(cached, isNotNull);
      expect(cached!.attestationToken, 'TOKEN');
    });

    test('should return last attestation time', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'TOKEN',
            'details': {},
          };
        }
        return null;
      });

      await service.performAttestation();
      final time = service.getLastAttestationTime();

      expect(time, isNotNull);
      expect(time!.isBefore(DateTime.now()), true);
    });

    test('should invalidate cache', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'performPlayIntegrityAttestation') {
          return {
            'deviceIntegrity': 'trusted',
            'appIntegrity': 'genuine',
            'environment': 'physical_device',
            'token': 'TOKEN',
            'details': {},
          };
        }
        return null;
      });

      await service.performAttestation();
      service.invalidateCache();

      expect(service.getLastAttestationResult(), isNull);
      expect(service.getLastAttestationTime(), isNull);
    });
  });

  group('AttestationResult', () {
    test('should identify secure environment correctly', () {
      final result = AttestationResult(
        deviceIntegrity: DeviceIntegrityState.trusted,
        appIntegrity: AppIntegrityState.genuine,
        environment: EnvironmentType.physicalDevice,
        attestationToken: 'TOKEN',
        details: const {},
        timestamp: DateTime.now(),
      );

      expect(result.isSecure, true);
      expect(result.isCompromised, false);
    });

    test('should identify compromised environment correctly', () {
      final result = AttestationResult(
        deviceIntegrity: DeviceIntegrityState.compromised,
        appIntegrity: AppIntegrityState.genuine,
        environment: EnvironmentType.physicalDevice,
        attestationToken: null,
        details: const {},
        timestamp: DateTime.now(),
      );

      expect(result.isSecure, false);
      expect(result.isCompromised, true);
    });

    test('should implement equality correctly', () {
      final now = DateTime.now();
      final result1 = AttestationResult(
        deviceIntegrity: DeviceIntegrityState.trusted,
        appIntegrity: AppIntegrityState.genuine,
        environment: EnvironmentType.physicalDevice,
        attestationToken: 'TOKEN',
        details: const {},
        timestamp: now,
      );

      final result2 = AttestationResult(
        deviceIntegrity: DeviceIntegrityState.trusted,
        appIntegrity: AppIntegrityState.genuine,
        environment: EnvironmentType.physicalDevice,
        attestationToken: 'TOKEN',
        details: const {},
        timestamp: now,
      );

      expect(result1, equals(result2));
    });
  });
}
