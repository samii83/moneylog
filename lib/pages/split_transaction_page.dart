import 'package:flutter/material.dart';

class SplitTransactionPage extends StatelessWidget {
  const SplitTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Split Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split Amount', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Category'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Amount', prefixText: '₹'))),
                        IconButton(icon: Icon(Icons.delete_outline), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Category'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Amount', prefixText: '₹'))),
                        IconButton(icon: Icon(Icons.delete_outline), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Split'),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.check_circle_outline),
              label: Text('Save Split'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
