import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus {
  active, // Game is visible and playable
  hidden, // Game is hidden from menu but accessible via direct URL
  blocked, // Game is completely blocked and inaccessible
  maintenance, // Game is temporarily unavailable
}

class GameManagement {
  final String gameId;
  final String gameName;
  final GameStatus status;
  final String? reason;
  final DateTime? blockedUntil;
  final DateTime updatedAt;
  final String updatedBy;

  const GameManagement({
    required this.gameId,
    required this.gameName,
    required this.status,
    this.reason,
    this.blockedUntil,
    required this.updatedAt,
    required this.updatedBy,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'gameId': gameId,
      'gameName': gameName,
      'status': status.name,
      'reason': reason,
      'blockedUntil': blockedUntil != null
          ? Timestamp.fromDate(blockedUntil!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory GameManagement.fromMap(Map<String, Object?> data) {
    return GameManagement(
      gameId: data['gameId'] as String,
      gameName: data['gameName'] as String,
      status: GameStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GameStatus.active,
      ),
      reason: data['reason'] as String?,
      blockedUntil: data['blockedUntil'] != null
          ? (data['blockedUntil'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] as String,
    );
  }

  GameManagement copyWith({
    String? gameId,
    String? gameName,
    GameStatus? status,
    String? reason,
    DateTime? blockedUntil,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return GameManagement(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  bool get isActive => status == GameStatus.active;
  bool get isHidden => status == GameStatus.hidden;
  bool get isBlocked => status == GameStatus.blocked;
  bool get isMaintenance => status == GameStatus.maintenance;
  bool get isAccessible =>
      status == GameStatus.active || status == GameStatus.hidden;
  bool get isBlockedTemporarily =>
      status == GameStatus.maintenance &&
      blockedUntil != null &&
      blockedUntil!.isAfter(DateTime.now());
}
