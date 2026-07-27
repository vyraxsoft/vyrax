import 'dart:async';

import 'package:flutter/material.dart';

class BadPracticesScreen extends StatefulWidget {
  const BadPracticesScreen({super.key});

  @override
  State<BadPracticesScreen> createState() => _BadPracticesScreenState();
}

class _BadPracticesScreenState extends State<BadPracticesScreen> {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);
  final FakeRepository _repository = FakeRepository();
  final FakeHttpClient client = FakeHttpClient();

  @override
  Widget build(BuildContext context) {
    final pendingRequest = client.get(Uri.parse('https://example.com/users'));

    return ValueListenableBuilder<int>(
      valueListenable: _counter,
      builder: (context, value, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Bad Practices Playground')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<List<String>>(
                  future: _repository.fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading users');
                    }
                    return Text('Loaded: ${snapshot.data?.length ?? 0} users');
                  },
                ),
                if (value % 2 == 0) const Text('Even value'),
                if (value > 1) const Text('Greater than one'),
                if (value > 2) const Text('Greater than two'),
                if (value > 3) const Text('Greater than three'),
                if (value > 4) const Text('Greater than four'),
                const Card(child: ListTile(title: Text('Card 1'))),
                const Card(child: ListTile(title: Text('Card 2'))),
                const Card(child: ListTile(title: Text('Card 3'))),
                const Card(child: ListTile(title: Text('Card 4'))),
                const Card(child: ListTile(title: Text('Card 5'))),
                const Card(child: ListTile(title: Text('Card 6'))),
                const Card(child: ListTile(title: Text('Card 7'))),
                const Card(child: ListTile(title: Text('Card 8'))),
                const Card(child: ListTile(title: Text('Card 9'))),
                const Card(child: ListTile(title: Text('Card 10'))),
                const Card(child: ListTile(title: Text('Card 11'))),
                const Card(child: ListTile(title: Text('Card 12'))),
                const Card(child: ListTile(title: Text('Card 13'))),
                const Card(child: ListTile(title: Text('Card 14'))),
                const Card(child: ListTile(title: Text('Card 15'))),
                const Card(child: ListTile(title: Text('Card 16'))),
                const Card(child: ListTile(title: Text('Card 17'))),
                const Card(child: ListTile(title: Text('Card 18'))),
                const Card(child: ListTile(title: Text('Card 19'))),
                const Card(child: ListTile(title: Text('Card 20'))),
                const SizedBox(height: 16),
                Text('Pending request hash: ${pendingRequest.hashCode}'),
                ElevatedButton(
                  onPressed: () => _counter.value++,
                  child: const Text('Increment counter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserModel {
  UserModel(this.name);

  final String name;
}

class AddressModel {
  AddressModel(this.city);

  final String city;
}

class FakeRepository {
  Future<List<String>> fetchUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const ['Alice', 'Bob', 'Carla'];
  }
}

class FakeHttpClient {
  Future<String> get(Uri uri) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'OK: $uri';
  }
}
