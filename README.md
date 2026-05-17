# SchoolFootballManager

小学校サッカーチーム管理アプリ

## 概要

SchoolFootballManagerは、小学校のサッカーチームを効率的に管理するためのiOSアプリケーションです。選手管理、試合記録、イベント管理、相乗り調整などの機能を提供します。

## 機能

### 組織構造
- 1つの学校に6つのチーム（1年生〜6年生）
- 各学年は独立したチーム

### ユーザー役割
- **管理者**: 全チーム閲覧、アカウント承認、学校全体管理
- **監督**: 学年別選手管理、試合結果入力、イベント作成
- **保護者**: 子供の情報閲覧、イベント登録、相乗り登録

### 主要機能
- **選手管理**: 基本情報、ポジション、身体情報、プロフィール写真
- **試合統計**: 試合記録、ゴール・アシスト数、カード履歴
- **イベント管理**: 試合・練習の予定管理、出欠確認
- **相乗り機能**: 運転手登録、座席予約、連絡先共有
- **プッシュ通知**: イベント通知、締切リマインダー

## 技術スタック

- **iOS**: SwiftUI + Swift 5.10
- **最小対応iOS**: 16.0
- **バックエンド**: Firebase
  - Authentication (認証)
  - Firestore (データベース)
  - Storage (画像保存)
  - Cloud Messaging (通知)
- **依存関係管理**: Swift Package Manager
- **プロジェクト生成**: XcodeGen

## セットアップ

### 1. 前提条件

- Xcode 15.0以上
- iOS 16.0以上の対応デバイス
- Firebaseプロジェクト

### 2. Firebaseセットアップ

1. [Firebase Console](https://console.firebase.google.com/)で新しいプロジェクトを作成
2. iOSアプリを追加（Bundle ID: `com.rinkan.schoolfootballmanager`）
3. `GoogleService-Info.plist`をダウンロード
4. ダウンロードしたファイルを`Resources/`フォルダに配置
5. Firestoreデータベースを有効化
6. Firebase Authenticationでメール/パスワード認証を有効化
7. Firebase Storageを有効化
8. Firebase Cloud Messagingを設定

### 3. プロジェクトビルド

```bash
# プロジェクトディレクトリに移動
cd school-football-manager

# Xcodeプロジェクトを生成（既に生成済み）
# xcodegen generate

# Xcodeでプロジェクトを開く
open SchoolFootballManager.xcodeproj
```

### 4. 依存関係

以下のFirebase SDKがSPMで自動的に追加されます：
- FirebaseAuth
- FirebaseFirestore
- FirebaseFirestoreSwift
- FirebaseStorage
- FirebaseMessaging

## Firestoreデータ構造

```
users/{uid}
  - email: String
  - name: String
  - role: String (admin/manager/parent)
  - teamId: String?
  - approvalStatus: String

teams/{teamId}/players/{playerId}
  - name: String
  - jerseyNumber: Int
  - position: String
  - birthday: Date
  - profilePhotoURL: String?

teams/{teamId}/players/{playerId}/matchRecords/{recordId}
  - opponentName: String
  - matchDate: Date
  - goals: Int
  - assists: Int

events/{eventId}
  - teamId: String
  - type: String (match/practice)
  - title: String
  - eventDate: Date
  - venue: String

events/{eventId}/registrations/{userId}
  - status: String (attending/absent/not_confirmed)
  - registeredAt: Date

events/{eventId}/carpools/{carpoolId}
  - driverId: String
  - carModel: String
  - totalSeats: Int
  - availableSeats: Int

events/{eventId}/carpools/{carpoolId}/bookings/{bookingId}
  - parentId: String
  - playerId: String?
  - status: String
```

## アーキテクチャ

### ディレクトリ構造
```
Sources/SchoolFootballManager/
├── App/                     # アプリエントリーポイント
├── Core/
│   ├── Models/             # データモデル
│   ├── Services/           # Firebase連携サービス
│   └── Extensions/         # 拡張機能
├── Features/
│   ├── Auth/              # 認証機能
│   ├── Dashboard/         # ダッシュボード
│   ├── Players/           # 選手管理
│   ├── Events/            # イベント管理
│   ├── Stats/             # 統計機能
│   ├── Carpool/           # 相乗り管理
│   └── Admin/             # 管理機能
└── Shared/
    ├── Components/        # 共通UI部品
    └── AppState.swift     # アプリ状態管理
```

### 設計パターン
- **MVVM**: Model-View-ViewModel
- **Repository Pattern**: データアクセス抽象化
- **Dependency Injection**: サービス依存性管理
- **Observer Pattern**: リアルタイムデータ更新

## 開発ガイドライン

### コーディング規約
- Swift標準コーディング規約に従う
- SwiftUIのベストプラクティスを適用
- `@MainActor`と`async/await`を使用
- 適切なエラーハンドリングを実装

### Git運用
- `main`ブランチは常に安定版を維持
- 機能開発は`feature/`ブランチで実施
- プルリクエストによるコードレビューを実施

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## サポート

質問や問題がある場合は、GitHubのIssuesをご利用ください。

---

## 初回セットアップチェックリスト

- [ ] Firebaseプロジェクトの作成
- [ ] `GoogleService-Info.plist`の配置
- [ ] Firestoreデータベースの有効化
- [ ] Firebase Authenticationの設定
- [ ] Firebase Storageの設定
- [ ] プッシュ通知証明書の設定
- [ ] 初期管理者アカウントの作成
- [ ] チームデータの初期設定

## 運用時の注意事項

1. **セキュリティ**
   - `GoogleService-Info.plist`は絶対にGitにコミットしないでください
   - 本番環境では適切なFirestore Rulesを設定してください

2. **パフォーマンス**
   - 大量のデータを扱う際は適切なページネーションを実装してください
   - 画像アップロード時は適切な圧縮を行ってください

3. **ユーザビリティ**
   - オフライン対応を考慮してください
   - 適切なローディング状態とエラーメッセージを表示してください