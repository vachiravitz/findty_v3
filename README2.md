# findty (หาตี้) 🎮

แอปหาเพื่อนเล่นเกมแบบเรียลไทม์ — สร้างตี้ / **เข้าร่วมตี้** / **ลบตี้** / แชทในตี้ / รีวิวเพื่อนร่วมตี้ ผ่าน Firebase

> เกมที่รองรับ: **Valorant**, **CS2**, **ROV**, **Minecraft**

---

## ✨ Features

- 🔐 **Firebase Auth** — register/login ด้วย email + password
- 👤 **User Profiles** — โปรไฟล์ (ชื่อ, รูป, tagline, Discord, Steam, traits)
- 🔄 **Realtime Party Feed** — มีคนสร้างตี้ที่ไหน ฟีดอัปเดตทันที
- ✋ **Join/Leave Party** — กดปุ่ม "เข้าร่วมตี้" → ใช้ Firestore transaction กัน race condition
- 🗑️ **Delete Party** — หัวตี้ลบตี้ของตัวเองได้ (ลบ chat history พร้อมกัน)
- 👥 **Member Tracking** — รู้ว่าใครอยู่ในตี้บ้าง โชว์ avatar กดเข้าโปรไฟล์ได้
- 💬 **Chat in Party** — แชทเรียลไทม์ในตี้ ส่งชื่อ/Discord ให้แอดกัน
- ⭐ **Reviews** — รีวิวเพื่อนร่วมตี้ (ดาว + ข้อความ + ชื่อ + วันเวลา)
- ✏️ **Edit Profile** — เปลี่ยนรูป (URL), ชื่อ, social links, traits
- 🖼️ **Custom Game Icons** — รองรับรูป icon เกมจาก local assets
- 🧩 **Game-aware UI** — multi-role (Valorant), single-role, no-role อัตโนมัติ
- 🇹🇭 **Thai-first** — Noto Sans Thai + locale ไทย

---

## 📁 โครงสร้างโปรเจกต์

```
lib/
├── main.dart
├── firebase_options.dart
├── constants.dart
│
├── config/
│   └── game_config.dart               # มี iconAsset
│
├── models/
│   ├── party_model.dart               # มี memberIds[]
│   ├── user_profile_model.dart
│   ├── review_model.dart
│   └── message_model.dart
│
├── services/
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── party_service.dart             # join / leave / delete (with messages)
│   └── chat_service.dart
│
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── game_selection_screen.dart     # ใช้ iconAsset
    ├── party_feed_screen.dart
    ├── create_party_screen.dart       # multi-role + memberIds
    ├── party_detail_screen.dart       # join button + delete button
    ├── profile_screen.dart
    ├── edit_profile_screen.dart
    └── write_review_screen.dart

assets/
└── games/                             # ใส่รูป icon เกมที่นี่
    ├── valorant.png
    ├── cs2.png
    ├── rov.png
    └── minecraft.png
```

---

## 🚀 Setup

### 1. ติดตั้ง dependencies

```bash
flutter pub get
```

### 2. เพิ่มรูป icon เกม (Asset Setup)

#### 2.1 สร้างโฟลเดอร์ + ใส่รูป

```
assets/games/
├── valorant.png
├── cs2.png
├── rov.png
└── minecraft.png
```

แนะนำ: PNG transparent background ขนาด 256x256 หรือ 512x512 px

#### 2.2 เพิ่มใน `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/games/
```

> ⚠️ ระวัง indentation 2 spaces ตรงกัน

ถ้ารูปยังไม่มี/path ผิด → fallback ไปใช้ Material icon อัตโนมัติ ไม่ crash

### 3. Firebase Setup

ใช้ `firebase_options.dart` กับ `google-services.json` ที่มีอยู่ต่อได้

### 4. อัปเดต Firestore Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /parties/{partyId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null;        // join/leave
      allow delete: if request.auth != null
                    && resource.data.ownerId == request.auth.uid;
      match /messages/{msgId} {
        allow read, create: if request.auth != null;
        allow delete: if request.auth != null;       // ตอนหัวตี้ลบตี้
      }
    }
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null && request.auth.uid != userId;
      }
    }
  }
}
```

### 5. รัน

```bash
flutter run
```

---

## ✋ Join/Leave/Delete Party

### Schema Firestore

```json
parties/{partyId}: {
  "memberIds": ["uid_owner", "uid_joiner_1"],
  "current": 2,
  "max": 5,
  ...
}
```

`memberIds[0]` = owner เสมอ. `current = memberIds.length`

### Backward Compat

ตี้เก่าที่ยังไม่มี `memberIds` → `PartyModel.fromDoc` default ให้เป็น `[ownerId]` อัตโนมัติ

### Transaction Logic

`joinParty` ใช้ `runTransaction` อ่าน → เช็ค → write atomic
ถ้า 2 คนกดพร้อมกันตอนเหลือ 1 ที่ → คนเดียวสำเร็จ อีกคน fail "ตี้เต็ม"

### Delete (Owner Only)

`deleteParty` ใช้ `WriteBatch`:
1. ลบ docs ทั้งหมดใน `messages/` sub-collection
2. ลบ doc party

ทำใน batch เดียว → atomic. Firestore Rules บังคับว่าเฉพาะ owner ลบได้

### UI ในหน้า party detail

ปุ่ม join/leave/delete จะเปลี่ยนตามสถานะ:

| สถานะ user | ปุ่มกลาง | AppBar |
|---|---|---|
| คุณคือหัวตี้ | "คุณคือหัวตี้" (เทา + ⭐) | 🗑️ ลบตี้ |
| คุณ join แล้ว (ไม่ใช่หัว) | "ออกจากตี้" (ส้ม) | — |
| ตี้เต็ม | "ตี้เต็มแล้ว" (เทา) | — |
| ปกติ | "เข้าร่วมตี้" (ชมพู) | — |

ใช้ `StreamBuilder` ฟัง doc → กด join/leave → UI update ทันที

---

## 🖼️ Game Icons

ใน `GameConfig` มี 2 ฟิลด์:
- `icon: IconData` — Material icon (fallback)
- `iconAsset: String?` — path asset

```dart
Image.asset(
  game.iconAsset!,
  errorBuilder: (_, __, ___) => Icon(game.icon, ...),  // fallback
)
```

→ ใส่รูปได้ตั้งแต่วันแรก, ไม่มีรูปก็ไม่พัง

---

## 🔥 Firestore Schema ทั้งหมด

```
users/{uid}
  ├─ username, email, avatarUrl, discordTag, steamId, tagline, traits[]
  └─ reviews/{reviewId}
       └─ reviewerUid, reviewerName, reviewerAvatar, rating, text, createdAt

parties/{partyId}
  ├─ title, gameId, rank?, role?
  ├─ current, max?
  ├─ ownerId, ownerName, leadAvatar
  ├─ memberIds[]
  ├─ createdAt
  └─ messages/{msgId}
       └─ senderId, senderName, senderAvatar, text, createdAt
```

---

## 📝 TODO

- [ ] auto-redirect คนออกจากตี้กลับไปหน้าฟีด หลัง leave
- [ ] หน้า "ตี้ของฉัน" — query `where memberIds array-contains <my uid>`
- [ ] Image upload จริงๆ (image_picker + Firebase Storage)
- [ ] ป้องกัน user รีวิวคนเดียวกันซ้ำ
- [ ] Push notification เมื่อมี chat ใหม่

---

## 🛠 Stack

- Flutter SDK ≥ 3.11.5
- Firebase Auth / Firestore / Core
- google_fonts (Noto Sans Thai)
- flutter_rating_bar
- Material 3
