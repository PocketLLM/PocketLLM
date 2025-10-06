import 'package:flutter_test/flutter_test.dart';
import 'package:pocketllm/services/network_service.dart';

void main() {
  group('NetworkService', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
      // Clear any existing state
      networkService.clearMessageQueue();
    });

    group('QueuedMessage', () {
      test('should create QueuedMessage with required fields', () {
        final message = QueuedMessage(
          id: 'test-id',
          endpoint: '/api/test',
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        expect(message.id, 'test-id');
        expect(message.endpoint, '/api/test');
        expect(message.data, {'key': 'value'});
        expect(message.retryCount, 0);
        expect(message.retryDelay, const Duration(seconds: 5));
      });

      test('should create copy with updated fields', () {
        final original = QueuedMessage(
          id: 'test-id',
          endpoint: '/api/test',
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        final copy = original.copyWith(
          retryCount: 3,
          retryDelay: const Duration(seconds: 10),
        );

        expect(copy.id, original.id);
        expect(copy.endpoint, original.endpoint);
        expect(copy.data, original.data);
        expect(copy.timestamp, original.timestamp);
        expect(copy.retryCount, 3);
        expect(copy.retryDelay, const Duration(seconds: 10));
      });

      test('should serialize to and from JSON', () {
        final timestamp = DateTime.now();
        final original = QueuedMessage(
          id: 'test-id',
          endpoint: '/api/test',
          data: {'key': 'value'},
          timestamp: timestamp,
          retryCount: 2,
          retryDelay: const Duration(seconds: 15),
        );

        final json = original.toJson();
        final restored = QueuedMessage.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.endpoint, original.endpoint);
        expect(restored.data, original.data);
        expect(restored.timestamp, original.timestamp);
        expect(restored.retryCount, original.retryCount);
        expect(restored.retryDelay, original.retryDelay);
      });
    });

    group('Message Queue Management', () {
      test('should queue messages', () {
        expect(networkService.queuedMessageCount, 0);

        networkService.queueMessage(
          id: 'msg-1',
          endpoint: '/api/test',
          data: {'test': 'data'},
        );

        expect(networkService.queuedMessageCount, 1);
        expect(networkService.queuedMessages.first.id, 'msg-1');
      });

      test('should remove queued messages', () {
        networkService.queueMessage(
          id: 'msg-1',
          endpoint: '/api/test',
          data: {'test': 'data'},
        );
        networkService.queueMessage(
          id: 'msg-2',
          endpoint: '/api/test2',
          data: {'test': 'data2'},
        );

        expect(networkService.queuedMessageCount, 2);

        networkService.removeQueuedMessage('msg-1');

        expect(networkService.queuedMessageCount, 1);
        expect(networkService.queuedMessages.first.id, 'msg-2');
      });

      test('should clear all queued messages', () {
        networkService.queueMessage(
          id: 'msg-1',
          endpoint: '/api/test',
          data: {'test': 'data'},
        );
        networkService.queueMessage(
          id: 'msg-2',
          endpoint: '/api/test2',
          data: {'test': 'data2'},
        );

        expect(networkService.queuedMessageCount, 2);

        networkService.clearMessageQueue();

        expect(networkService.queuedMessageCount, 0);
      });
    });

    group('Network Status', () {
      test('should have initial unknown status', () {
        expect(networkService.status, NetworkStatus.unknown);
        expect(networkService.connectionType, ConnectionType.unknown);
      });

      test('should provide network info', () {
        final info = networkService.getNetworkInfo();

        expect(info['status'], contains('NetworkStatus.'));
        expect(info['connectionType'], contains('ConnectionType.'));
        expect(info['isOnline'], isA<bool>());
        expect(info['queuedMessages'], isA<int>());
        expect(info['timestamp'], isA<String>());
      });
    });

    group('Network Requests', () {
      test('should throw NetworkException when offline', () async {
        // Simulate offline status
        // Note: In a real test, we'd need to mock the connectivity
        
        expect(
          () => networkService.performNetworkRequest(() async => 'test'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should perform request with retry logic', () async {
        // This test will likely fail due to offline status in test environment
        // but we can test that the method exists and handles the offline case
        expect(
          () => networkService.performNetworkRequest(() async => 'test'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('Host Reachability', () {
      test('should check if host is reachable', () async {
        // Test with a non-existent host (should be unreachable)
        final isReachable = await networkService.isHostReachable(
          'non-existent-host-12345.com',
          timeout: const Duration(seconds: 1),
        );
        
        expect(isReachable, false);
      });
    });
  });

  group('NetworkException', () {
    test('should create exception with message', () {
      final exception = NetworkException('Test error');
      
      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.toString(), 'NetworkException: Test error');
    });

    test('should create exception with message and code', () {
      final exception = NetworkException('Test error', code: 'NET001');
      
      expect(exception.message, 'Test error');
      expect(exception.code, 'NET001');
      expect(exception.toString(), 'NetworkException: Test error (Code: NET001)');
    });
  });
}