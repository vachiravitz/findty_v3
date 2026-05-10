# findty (หาตี้) 🎮

แอปหาเพื่อนเล่นเกมแบบเรียลไทม์ — สร้างตี้ / หาตี้ / แชทในตี้ / รีวิวเพื่อนร่วมตี้ ผ่าน Firebase

> เกมที่รองรับ: **Valorant**, **CS2**, **ROV**, **Minecraft**

---

## ✨ Features

- 🔐 **Firebase Auth** — register/login ด้วย email + password
- 👤 **User Profiles** — แต่ละคนมีโปรไฟล์ (ชื่อ, รูป, tagline, Discord, Steam, traits)
- 🔄 **Realtime Party Feed** — มีคนสร้างตี้ที่ไหน หน้าฟีดอัปเดตทันที
- 💬 **Chat in Party** — กดเข้า card ตี้ → หน้า detail มีกล่องแชทเรียลไทม์ ส่งชื่อ/discord ให้แอดกันได้
- ⭐ **Reviews** — กดเข้าโปรไฟล์คนอื่น → เขียนรีวิว (1-5 ดาว + ข้อความ) → โชว์ใต้โปรไฟล์พร้อมชื่อ + วันเวลา
- ✏️ **Edit Profile** — เปลี่ยนรูป (URL), ชื่อ, social links, traits
- 🧩 **Game-aware UI** — UI ฟอร์มสร้างตี้ปรับตัวเองตามเกม (มี/ไม่มี rank, role, จำกัด/ไม่จำกัดคน)
- 🇹🇭 **Thai-first** — Noto Sans Thai + locale ไทย ครบ
- 🧱 **Extensible** — เพิ่มเกมใหม่แก้ไฟล์เดียว (`lib/config/game_config.dart`)

---

## 📁 โครงสร้างโปรเจกต์

```
lib/
├── main.dart                          # entry + Firebase + auth-aware home
├── firebase_options.dart              # *** Firebase config ***
├── constants.dart
│
├── config/
│   └── game_config.dart               # 👈 ศูนย์รวมเกม - เพิ่มเกมใหม่ที่นี่
│
├── models/
│   ├── party_model.dart               # ตี้ (พร้อม ownerName + leadAvatar)
│   ├── user_profile_model.dart        # ⭐ ใหม่: profile
│   ├── review_model.dart              # ⭐ ใหม่: review
│   └── message_model.dart             # ⭐ ใหม่: chat message
│
├── services/
│   ├── auth_service.dart              # ⭐ ใหม่: FirebaseAuth
│   ├── user_service.dart              # ⭐ ใหม่: profile + reviews
│   ├── party_service.dart             # ตี้ (stream-based)
│   └── chat_service.dart              # ⭐ ใหม่: chat
│
└── screens/
    ├── login_screen.dart              # auth จริงแล้ว
    ├── register_screen.dart           # auth + สร้าง profile doc
    ├── game_selection_screen.dart     # มีปุ่ม profile + logout
    ├── party_feed_screen.dart         # card click -> party_detail
    ├── create_party_screen.dart       # ใช้ user จริง + รูปจริง
    ├── party_detail_screen.dart       # ⭐ ใหม่: สมาชิก + chat
    ├── profile_screen.dart            # โหลดจาก Firestore + reviews
    ├── edit_profile_screen.dart       # ⭐ ใหม่: แก้ profile
    └── write_review_screen.dart       # ⭐ ใหม่: เขียนรีวิว
```

---

## 🚀 Setup

### 1. ติดตั้ง dependencies

```bash
flutter pub get
```

### 2. ตั้งค่า Firebase

ไฟล์ `lib/firebase_options.dart` ต้องมีค่าจริงของ project คุณ
ดู `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) เพื่อ map ค่า

### 3. เปิด Firebase Auth

ไปที่ **Firebase Console → Authentication → Sign-in method → เปิด "Email/Password"**

> ⚠️ ขั้นนี้สำคัญมาก ถ้าลืมจะ register/login ไม่ได้ขึ้น `auth/operation-not-allowed`

### 4. ตั้ง Firestore Rules (สำหรับ dev)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // parties + sub-collection messages
    match /parties/{partyId} {
      allow read, write: if true;
      match /messages/{msgId} {
        allow read, write: if true;
      }
    }
    // users + sub-collection reviews
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null
                      && request.auth.uid != userId;  // กันรีวิวตัวเอง
      }
    }
  }
}
```

> ก่อน deploy production แก้ rules ให้เข้มกว่านี้

### 5. รัน

```bash
flutter run
```

---

## 🔥 Firestore Schema

```
users/{uid}
  ├─ username, email, avatarUrl, discordTag, steamId, tagline, traits[]
  └─ reviews/{reviewId}
       └─ reviewerUid, reviewerName, reviewerAvatar, rating, text, createdAt

parties/{partyId}
  ├─ title, gameId, rank?, role?, current, max?
  ├─ ownerId, ownerName, leadAvatar, createdAt
  └─ messages/{msgId}
       └─ senderId, senderName, senderAvatar, text, createdAt
```

**ออกแบบเป็น "denormalized"** — `ownerName`, `leadAvatar` ใน party doc คือ **snapshot ตอนสร้าง**
เหมือน Twitter/Discord ที่ snapshot ชื่อตอนโพสต์ — เปลี่ยน profile ทีหลังจะไม่กระทบ posts เก่า
ตี้/รีวิว/แชทใหม่หลังเปลี่ยน profile จะใช้รูป+ชื่อใหม่อัตโนมัติ

---

## 🧠 Flow การใช้งาน

1. **Register** → กรอกชื่อ + email + password
   → Firebase Auth สร้าง user
   → Firestore สร้าง doc `users/{uid}` ด้วยชื่อจากฟอร์ม + avatar default (pravatar)
   → เด้งเข้า GameSelectionScreen
2. **Login** → email + password → main.dart `authStateChanges` พาเข้า GameSelectionScreen
3. **สร้างตี้** — `create_party_screen` ดึง profile ของ user → snapshot ชื่อ+รูปลง party doc
4. **กด card ตี้** → `party_detail_screen` — เห็นสมาชิก (กดรูปหัวตี้ → ไปโปรไฟล์เขา) + chat
5. **กดที่รูปคนอื่น** ใน chat / member list → `profile_screen(uid: คนนั้น)`
   → เห็นปุ่ม **Write Review** → ให้ดาว + เขียนรายละเอียด → save เข้า `users/{uid}/reviews/`
6. **โปรไฟล์ตัวเอง** (กดไอคอน account ขวาบนของ GameSelection) → เห็นปุ่ม **Edit** → แก้ทุกฟิลด์ได้

---

## 🖼️ การเปลี่ยนรูปโปรไฟล์

ตอนนี้ใช้ระบบ **URL paste** — แปะลิงก์รูป (เช่น Discord CDN, Imgur, pravatar) ใน Edit Profile แล้วกด save

ทำไมถึงใช้ URL?
- ไม่ต้องเพิ่ม package เพิ่ม
- ไม่ต้องตั้ง permission Android/iOS
- ไม่ต้องเปิด Firebase Storage

### Image Upload (Optional Upgrade)

ถ้าจะเปลี่ยนเป็น **อัปโหลดรูปจากเครื่อง** (ดีกว่า UX แต่ setup เพิ่ม):

1. เพิ่ม packages:
   ```yaml
   image_picker: ^1.1.2
   firebase_storage: ^12.3.0
   ```
2. เปิด **Firebase Storage** ใน Firebase Console
3. แก้ `edit_profile_screen.dart` ให้:
   - ใช้ `ImagePicker().pickImage(source: ImageSource.gallery)` เลือกรูป
   - upload ไป Storage `avatars/{uid}.jpg`
   - เก็บ download URL ลง `users/{uid}.avatarUrl`

จะทำเพิ่มทีหลังได้ ไม่ต้องรื้อโค้ดเดิม

---

## 🧩 เพิ่มเกมใหม่

แก้ไฟล์เดียว: `lib/config/game_config.dart` เพิ่ม entry ใน `GameRegistry.all`

```dart
GameConfig(
  id: 'apex',
  displayName: 'Apex Legends',
  icon: Icons.flash_on,
  hasRank: true,
  ranks: ['Any', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'],
  hasRole: false,
  maxPartySize: 3,
),
```

หน้า GameSelection + ฟอร์มสร้างตี้ จะรองรับเกมใหม่ทันที — ไม่ต้องแก้ UI

---

## 📝 TODO

- [ ] ระบบ "เข้าร่วมตี้" จริงๆ — กดแล้ว `current += 1` แบบ `transaction`
- [ ] หน้า "ตี้ของฉัน" — query `where ownerId == currentUser.uid`
- [ ] auto-close ตี้เมื่อ `current == max`
- [ ] Image upload (ดูหัวข้อด้านบน)
- [ ] ป้องกัน user รีวิวคนเดียวกันซ้ำ (เพิ่ม check ใน rules)
- [ ] Typing indicator ใน chat
- [ ] Push notification เมื่อมี chat ใหม่

---

## 🛠 Stack

- Flutter SDK ≥ 3.38.4
- Firebase Auth / Firestore / Core
- google_fonts (Noto Sans Thai)
- flutter_rating_bar (สำหรับ stars)
- Material 3
