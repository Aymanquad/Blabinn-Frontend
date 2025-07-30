import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../services/auth_service.dart';

class BackendConnectionTest {
  static final AuthService _authService = AuthService();

  /// Comprehensive backend connection test
  static Future<Map<String, dynamic>> runFullTest() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Basic connectivity
      results['basicConnectivity'] = await _testBasicConnectivity();
      
      // Test 2: Auth service tests
      results['authServiceTests'] = await _testAuthServiceMethods();
      
      // Test 3: API endpoints test
      results['apiEndpoints'] = await _testApiEndpoints();
      
      // Test 4: Network configuration
      results['networkConfig'] = await _getNetworkConfiguration();
      
      // Test 5: Firebase availability
      results['firebaseStatus'] = await _testFirebaseStatus();
      
      // Overall success
      results['overallSuccess'] = results['basicConnectivity']['success'] && 
                                 results['authServiceTests']['success'];
      
    } catch (e) {
      results['error'] = e.toString();
      results['overallSuccess'] = false;
    }
    
    return results;
  }

  /// Test basic network connectivity
  static Future<Map<String, dynamic>> _testBasicConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      final testUrl = '${AppConfig.apiUrl}/auth/test-connection';
      
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      results['statusCode'] = response.statusCode;
      results['responseBody'] = response.body;
      results['success'] = response.statusCode == 200;
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          results['parsedData'] = data;
        } catch (e) {
          results['parseError'] = e.toString();
        }
      }
      
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }
    
    return results;
  }

  /// Test auth service methods
  static Future<Map<String, dynamic>> _testAuthServiceMethods() async {
    final results = <String, dynamic>{};
    
    try {
      // Test backend connection
      final canConnect = await _authService.testBackendConnection();
      results['backendConnection'] = canConnect;
      
      // Test POST requests
      final canPost = await _authService.testPostRequest();
      results['postRequests'] = canPost;
      
      results['success'] = canConnect && canPost;
      
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }
    
    return results;
  }

  /// Test various API endpoints
  static Future<Map<String, dynamic>> _testApiEndpoints() async {
    final results = <String, dynamic>{};
    final endpoints = [
      '/auth/test-connection',
      '/auth/test-post',
      '/api/health',
      '/api/status',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.apiUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(Duration(seconds: 5));
        
        results[endpoint] = {
          'statusCode': response.statusCode,
          'success': response.statusCode == 200,
          'body': response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body,
        };
      } catch (e) {
        results[endpoint] = {
          'error': e.toString(),
          'success': false,
        };
      }
    }
    
    return results;
  }

  /// Get network configuration details
  static Future<Map<String, dynamic>> _getNetworkConfiguration() async {
    return {
      'apiUrl': AppConfig.apiUrl,
      'timeout': AppConfig.apiTimeout.inSeconds,
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'localIp': await _getLocalIpAddress(),
    };
  }

  /// Test Firebase status
  static Future<Map<String, dynamic>> _testFirebaseStatus() async {
    return {
      'isAvailable': _authService.isFirebaseAvailable,
      'currentUser': _authService.currentUser?.email ?? 'No user',
      'isGuest': _authService.isGuest,
    };
  }

  /// Get local IP address
  static Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
      return 'Not found';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Format test results for display
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 BACKEND CONNECTION TEST RESULTS');
    buffer.writeln('=====================================');
    
    // Overall status
    buffer.writeln('Overall Status: ${results['overallSuccess'] ? '✅ SUCCESS' : '❌ FAILED'}');
    buffer.writeln('');
    
    // Basic connectivity
    final basic = results['basicConnectivity'] as Map<String, dynamic>;
    buffer.writeln('📡 Basic Connectivity:');
    buffer.writeln('  Status: ${basic['success'] ? '✅ Connected' : '❌ Failed'}');
    buffer.writeln('  Status Code: ${basic['statusCode']}');
    if (basic['error'] != null) {
      buffer.writeln('  Error: ${basic['error']}');
    }
    buffer.writeln('');
    
    // Auth service tests
    final auth = results['authServiceTests'] as Map<String, dynamic>;
    buffer.writeln('🔐 Auth Service Tests:');
    buffer.writeln('  Backend Connection: ${auth['backendConnection'] ? '✅' : '❌'}');
    buffer.writeln('  POST Requests: ${auth['postRequests'] ? '✅' : '❌'}');
    if (auth['error'] != null) {
      buffer.writeln('  Error: ${auth['error']}');
    }
    buffer.writeln('');
    
    // Network configuration
    final network = results['networkConfig'] as Map<String, dynamic>;
    buffer.writeln('🌐 Network Configuration:');
    buffer.writeln('  API URL: ${network['apiUrl']}');
    buffer.writeln('  Timeout: ${network['timeout']}s');
    buffer.writeln('  Platform: ${network['platform']} ${network['platformVersion']}');
    buffer.writeln('  Local IP: ${network['localIp']}');
    buffer.writeln('');
    
    // Firebase status
    final firebase = results['firebaseStatus'] as Map<String, dynamic>;
    buffer.writeln('🔥 Firebase Status:');
    buffer.writeln('  Available: ${firebase['isAvailable'] ? '✅' : '❌'}');
    buffer.writeln('  Current User: ${firebase['currentUser']}');
    buffer.writeln('  Is Guest: ${firebase['isGuest'] ? 'Yes' : 'No'}');
    buffer.writeln('');
    
    // API endpoints
    final endpoints = results['apiEndpoints'] as Map<String, dynamic>;
    buffer.writeln('🔗 API Endpoints:');
    endpoints.forEach((endpoint, result) {
      final status = result['success'] ? '✅' : '❌';
      buffer.writeln('  $endpoint: $status (${result['statusCode']})');
    });
    
    return buffer.toString();
  }
} 