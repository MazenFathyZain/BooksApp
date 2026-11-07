import 'dart:convert';
import 'dart:typed_data';

import 'package:book/core/di/dependency_injection.dart';
import 'package:book/core/helpers/constants.dart';
import 'package:book/features/admin/data/admin_repo.dart';
import 'package:book/features/admin/ui/admin_categories_screen.dart';
import 'package:book/features/admin/ui/admin_users_screen.dart';
import 'package:book/features/auth/data/models/register_request_body.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers API calls from a map of "METHOD path" to JSON, and records them.
class FakeApi implements HttpClientAdapter {
  final Map<String, Object?> responses;
  final List<String> calls = [];

  FakeApi(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri.path}';
    calls.add(key);
    return ResponseBody.fromString(
      jsonEncode(responses[key] ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeApi api;

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      // No translations here: labels simply show their keys.
      MaterialApp(home: screen),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() async {
    await getIt.reset();
    api = FakeApi({
      'GET /api/admin/users': [
        {
          '_id': 'me',
          'name': 'Boss',
          'email': 'boss@example.com',
          'role': 'admin',
        },
        {
          '_id': 'other',
          'name': 'Reader',
          'email': 'reader@example.com',
          'role': 'user',
        },
      ],
      'GET /api/categories/tree': [
        {'_id': 'a', 'name': 'From the app', 'language': 'Tajik'},
        {'_id': 'b', 'name': 'From the website', 'language': 'tg'},
        {'_id': 'c', 'name': 'In Arabic', 'language': 'Arabic'},
      ],
    });
    getIt.registerSingleton<AdminRepo>(
      AdminRepo(Dio()..httpClientAdapter = api),
    );
    updateSessionState(loggedIn: true, admin: true, userId: 'me');
  });

  tearDown(clearSessionState);

  test('sign-up request never asks for a role', () {
    final body = RegisterRequestBody(
      name: 'New',
      email: 'new@example.com',
      password: 'secret1',
    );
    expect(body.toJson().containsKey('role'), isFalse);
  });

  testWidgets('admins can delete other users but not themselves', (
    tester,
  ) async {
    await pumpScreen(tester, const AdminUsersScreen());

    expect(find.textContaining('Boss'), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget);
    // Only the other account has a delete button.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('a language shows categories saved by the app and the website', (
    tester,
  ) async {
    await pumpScreen(tester, const AdminCategoriesScreen());

    expect(find.text('From the app'), findsOneWidget);
    expect(find.text('From the website'), findsOneWidget);
    expect(find.text('In Arabic'), findsNothing);
  });
}
