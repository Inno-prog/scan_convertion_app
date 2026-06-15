import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class ConversionRecord {
  final String id;
  final String originalName;
  final String outputPath;
  final String outputFormat;
  final String categoryName;
  final DateTime date;
  final int fileSizeBytes;

  ConversionRecord({
    required this.id,
    required this.originalName,
    required this.outputPath,
    required this.outputFormat,
    required this.categoryName,
    required this.date,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'outputPath': outputPath,
        'outputFormat': outputFormat,
        'categoryName': categoryName,
        'date': date.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory ConversionRecord.fromJson(Map<String, dynamic> json) =>
      ConversionRecord(
        id: json['id'],
        originalName: json['originalName'],
        outputPath: json['outputPath'],
        outputFormat: json['outputFormat'],
        categoryName: json['categoryName'],
        date: DateTime.parse(json['date']),
        fileSizeBytes: json['fileSizeBytes'],
      );
}

class UserProfile {
  final String name;
  final String email;
  final String? avatarPath;

  const UserProfile({
    this.name = 'Utilisateur',
    this.email = 'utilisateur@email.com',
    this.avatarPath,
  });

  UserProfile copyWith({String? name, String? email, String? avatarPath}) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        avatarPath: avatarPath ?? this.avatarPath,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatarPath': avatarPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Utilisateur',
        email: json['email'] ?? 'utilisateur@email.com',
        avatarPath: json['avatarPath'],
      );
}

class AppSettings {
  final bool darkMode;
  final bool notifications;
  final String language;

  const AppSettings({
    this.darkMode = true,
    this.notifications = false,
    this.language = 'Français',
  });

  AppSettings copyWith(
          {bool? darkMode, bool? notifications, String? language}) =>
      AppSettings(
        darkMode: darkMode ?? this.darkMode,
        notifications: notifications ?? this.notifications,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'notifications': notifications,
        'language': language,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        darkMode: json['darkMode'] ?? true,
        notifications: json['notifications'] ?? false,
        language: json['language'] ?? 'Français',
      );
}

class StorageService {
  static const _historyKey = 'conversion_history';
  static const _settingsKey = 'app_settings';
  static const _profileKey = 'user_profile';
  static const _scansKey = 'scan_history';
  static StorageService? _instance;
  late SharedPreferences _prefs;
  // Tracks whether _prefs has been initialized and the instance is ready.
  static bool _initialized = false;
  // If initialization is in progress, this Future completes with the ready instance.
  static Future<StorageService>? _initializing;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_initialized && _instance != null) return _instance!;

    // If another call is already initializing the service, wait for it.
    if (_initializing != null) return await _initializing!;

    // Begin initialization and store the Future so concurrent callers wait on it.
    _initializing = () async {
      final inst = StorageService._();
      inst._prefs = await SharedPreferences.getInstance();
      _instance = inst;
      _initialized = true;
      // Clear the initializing future after completion so subsequent calls go fast.
      _initializing = null;
      return _instance!;
    }();

    return await _initializing!;
  }

  // --- Historique ---

  List<ConversionRecord> getHistory() {
    final raw = _prefs.getStringList(_historyKey) ?? [];
    return raw.map((e) => ConversionRecord.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addRecord(ConversionRecord record) async {
    final history = getHistory();
    history.insert(0, record);
    // Garder max 100 entrées
    final trimmed = history.take(100).toList();
    await _prefs.setStringList(
      _historyKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> deleteRecord(String id) async {
    final history = getHistory().where((r) => r.id != id).toList();
    await _prefs.setStringList(
      _historyKey,
      history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // --- Historique Scans ---

  List<ScanRecord> getScanHistory() {
    final raw = _prefs.getStringList(_scansKey) ?? [];
    return raw.map((e) => ScanRecord.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addScanRecord(ScanRecord record) async {
    final history = getScanHistory();
    history.insert(0, record);
    final trimmed = history.take(100).toList();
    await _prefs.setStringList(
      _scansKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> deleteScanRecord(String id) async {
    final history = getScanHistory().where((r) => r.id != id).toList();
    await _prefs.setStringList(
      _scansKey,
      history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clearScanHistory() async {
    await _prefs.remove(_scansKey);
  }

  // --- Paramètres ---

  AppSettings getSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  // --- Profil ---

  UserProfile getProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return const UserProfile();
    return UserProfile.fromJson(jsonDecode(raw));
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // --- Stats profil ---

  int getTotalConversions() => getHistory().length;

  Set<String> getUsedFormats() =>
      getHistory().map((r) => r.outputFormat).toSet();

  int getTotalSavedBytes() =>
      getHistory().fold(0, (sum, r) => sum + r.fileSizeBytes);
}
