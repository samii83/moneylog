import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class SmsSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenses = provider.expenses;
    final results = query.isEmpty
        ? []
        : expenses.where((exp) => exp.description.toLowerCase().contains(query.toLowerCase())).toList();
    if (query.isEmpty) {
      return Center(child: Text('Type to search SMS messages...'));
    }
    if (results.isEmpty) {
      return Center(child: Text('No results found.'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, i) {
        final exp = results[i];
        return ListTile(
          leading: Icon(Icons.sms),
          title: Text(exp.description),
          subtitle: Text('${exp.sender} • ${exp.date}'),
        );
      },
    );
  }
}
