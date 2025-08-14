// lib/screens/marketplace_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/listing_details_screen.dart'; // Importamos la nueva pantalla
import 'package:roozterfaceapp/widgets/listing_tile.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado de Ejemplares'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('showcase_listings')
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar el mercado: ${snapshot.error}'));
          }

          final listings = snapshot.data?.docs ?? [];

          if (listings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Actualmente no hay ejemplares en venta en el mercado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listingData =
                  listings[index].data() as Map<String, dynamic>;

              return ListingTile(
                listingData: listingData,
                onTap: () {
                  // --- ¡NAVEGACIÓN AHORA FUNCIONAL! ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListingDetailsScreen(listingData: listingData),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
