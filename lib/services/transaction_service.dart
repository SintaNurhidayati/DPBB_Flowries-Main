import 'package:flutter/foundation.dart';
import 'package:flowries/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal() {
    _transactionsNotifier = ValueNotifier([]);
    _loadInitialData();
  }

  late ValueNotifier<List<Map<String, dynamic>>> _transactionsNotifier;

  List<Map<String, dynamic>> get transactions => _transactionsNotifier.value;
  ValueNotifier<List<Map<String, dynamic>>> get transactionsNotifier => _transactionsNotifier;

  void initialize() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    
    if (maps.isEmpty) {
      // Seed initial dummy data if DB is empty
      final initialTransactions = [
        {
          'id': 'TRX001',
          'userId': 'admin',
          'items': jsonEncode([
            {
              'id': '1', 'nama': 'Bunga Mawar Merah', 'harga': 150000,
              'quantity': 2, 'image': 'assets/images/flower1.png',
            }
          ]),
          'totalSebelomDiskon': 300000.0,
          'diskonNominal': 0.0,
          'totalSetelahDiskon': 300000.0,
          'status': 'menunggu',
          'tanggalPemesanan': DateTime.now().toIso8601String(),
          'metodePembayaran': 'Transfer Bank',
          'alamatPengiriman': 'Jl. Merdeka No. 123, Kota'
        },
      ];
      for (var trx in initialTransactions) {
        await db.insert('transactions', trx, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await refreshTransactions();
    } else {
      await refreshTransactions();
    }
  }

  Future<void> refreshTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('transactions');
    
    final formattedTransactions = maps.map((map) {
      List<dynamic> itemsArray = [];
      try {
        itemsArray = jsonDecode(map['items'] as String);
      } catch (e) {
        // ignore
      }
      
      String itemsString = itemsArray.map((i) => "${i['nama']} x${i['quantity']}").join(', ');

      return {
        'id': map['id'],
        'items': itemsString,
        'itemsArray': itemsArray,
        'pembeli': map['userId'], // simplified
        'total': map['totalSetelahDiskon'],
        'status': map['status'],
        'tanggal': (map['tanggalPemesanan'] as String).split('T')[0],
        'metode': map['metodePembayaran'],
        'alamat': map['alamatPengiriman'],
        'diskon': map['diskonNominal'],
        'reviewAdded': map['status'] == 'selesai' && map['tanggalSelesai'] != null, // simplified logic
        'buktiPembayaran': map['buktiPembayaran'],
        'tipePesanan': map['tipePesanan'] ?? 'katalog',
        'catatanCustom': map['catatanCustom'],
      };
    }).toList();
    
    _transactionsNotifier.value = formattedTransactions;
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.insert('transactions', {
      'id': transaction['id'],
      'userId': transaction['pembeli'] ?? 'user1',
      'items': jsonEncode(transaction['itemsArray'] ?? []),
      'totalSebelomDiskon': transaction['total'] + (transaction['diskon'] ?? 0.0),
      'diskonNominal': transaction['diskon'] ?? 0.0,
      'totalSetelahDiskon': transaction['total'],
      'status': transaction['status'] ?? 'menunggu',
      'tanggalPemesanan': DateTime.now().toIso8601String(),
      'metodePembayaran': transaction['metode'],
      'alamatPengiriman': transaction['alamat'],
      'buktiPembayaran': transaction['buktiPembayaran'],
      'tipePesanan': transaction['tipePesanan'] ?? 'katalog',
      'catatanCustom': transaction['catatanCustom'],
    });
    
    await refreshTransactions();
  }

  Future<void> updateTransactionStatus(String transactionId, String newStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'transactions',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    await refreshTransactions();
  }

  Future<void> updateTransactionPaymentProof(String transactionId, String base64Image) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'transactions',
      {
        'status': 'menunggu_verifikasi_admin',
        'buktiPembayaran': base64Image,
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    await refreshTransactions();
  }

  Future<void> updateReviewStatus(String transactionId, bool reviewed) async {
    final db = await DatabaseHelper.instance.database;
    if (reviewed) {
      await db.update(
        'transactions',
        {'tanggalSelesai': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    }
    await refreshTransactions();
  }

  void dispose() {
    _transactionsNotifier.dispose();
  }
}
