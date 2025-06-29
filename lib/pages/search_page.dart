import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for searching SMS/expenses
    return Scaffold(
      appBar: AppBar(title: Text('Search Transactions')),
      body: Center(child: Text('Search for SMS or expenses here.')),
    );
  }
}
