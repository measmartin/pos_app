import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database_service.dart';
import '../models/product.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();

  // Notification IDs
  static const int _lowStockNotificationId = 1;
  // Note: _dailyReportNotificationId reserved for future daily report feature

  // Low stock threshold (can be configured per product in future)
  static const int _defaultLowStockThreshold = 10;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Request permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pos_channel',
      'POS Notifications',
      channelDescription: 'Notifications for POS System',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Check for low stock products and send notification if any found
  Future<void> checkLowStockAndNotify({int threshold = _defaultLowStockThreshold}) async {
    final db = await _databaseService.database;
    
    // Query products with low stock
    final List<Map<String, dynamic>> results = await db.query(
      'products',
      where: 'stockQuantity <= ? AND stockQuantity > 0',
      whereArgs: [threshold],
      orderBy: 'stockQuantity ASC',
    );

    if (results.isEmpty) {
      return; // No low stock items
    }

    final lowStockProducts = results.map((map) => Product.fromMap(map)).toList();
    
    // Create notification message
    final count = lowStockProducts.length;
    String title = 'Low Stock Alert';
    String body;

    if (count == 1) {
      final product = lowStockProducts.first;
      body = '${product.name} is running low (${product.stockQuantity} ${product.unit} remaining)';
    } else if (count <= 3) {
      final names = lowStockProducts.map((p) => p.name).join(', ');
      body = '$count items running low: $names';
    } else {
      body = '$count products are running low on stock. Check inventory report for details.';
    }

    // Show notification
    await showLowStockNotification(title, body);
  }

  /// Show a low stock notification
  Future<void> showLowStockNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Alerts for products running low on stock',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 255, 152, 0), // Orange color for warnings
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      _lowStockNotificationId,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Schedule daily low stock check (e.g., at 9 AM every day)
  /// Note: For production, consider using a background task plugin like workmanager
  Future<void> scheduleDailyLowStockCheck() async {
    // For now, this is a placeholder for future implementation
    // To implement proper daily checks, you would need:
    // 1. workmanager or similar background task plugin
    // 2. Android/iOS background execution permissions
    // 3. Scheduled tasks that run even when app is closed
    
    // For immediate implementation, the app can check when:
    // - App starts (main.dart)
    // - Dashboard screen opens
    // - User navigates to inventory
  }

  /// Show notification when product is added
  Future<void> notifyProductAdded(String productName) async {
    await showNotification(
      100,
      'Product Added',
      '$productName has been added to inventory',
    );
  }

  /// Show notification when sale is completed
  Future<void> notifySaleCompleted(double totalAmount) async {
    await showNotification(
      200,
      'Sale Completed',
      'Sale total: \$${totalAmount.toStringAsFixed(2)}',
    );
  }

  /// Show notification when purchase is completed
  Future<void> notifyPurchaseCompleted(int itemCount) async {
    await showNotification(
      300,
      'Purchase Completed',
      'Added $itemCount item(s) to inventory',
    );
  }

  /// Get count of low stock products
  Future<int> getLowStockCount({int threshold = _defaultLowStockThreshold}) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stockQuantity <= ? AND stockQuantity > 0',
      [threshold],
    );

    return result.first['count'] as int? ?? 0;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}

