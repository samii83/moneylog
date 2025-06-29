import 'package:flutter/material.dart';

class MerchantInsightsPage extends StatelessWidget {
  const MerchantInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for merchant/payee insights
    return Scaffold(
      appBar: AppBar(title: Text('Merchant Insights')),
      body: Center(child: Text('View stats for top merchants/payees here.')),
    );
  }
}
