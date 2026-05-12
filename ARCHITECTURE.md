# 🗺️ findty — อธิบายการทำงานทั้งโปรเจค

---

## ภาพรวม: แอปทำงานยังไง?

```
User เปิดแอป
  └─ main.dart ตรวจว่า login อยู่ไหม (Firebase Auth)
       ├─ ใช่ → GameSelectionScreen
       └─ ไม่ใช่ → LoginScreen
```

แอปนี้ใช้ **Firebase** เป็น backend ทั้งหมด ไม่มี server ของตัวเอง
- **Firebase Auth** — จัดการ login/register
- **Cloud Firestore** — เก็บข้อมูลทุกอย่าง (users, parties, messages, reviews)
- ข้อมูลทุกอย่างไหลเป็น **Stream** (realtime) ไม่ต้องกด refresh

---

## 📂 lib/ — แบ่งเป็น 4 โซน

```
lib/
├── main.dart              ← จุดเริ่มต้นของแอป
├── constants.dart         ← สีทั้งแอป
├── firebase_options.dart  ← config Firebase (gen อัตโนมัติ)
│
├── config/                ← ค่าคงที่ของเกม
├── models/                ← โครงสร้างข้อมูล
├── services/              ← คุยกับ Firebase
└── screens/               ← UI ที่ user เห็น
```

---

## 1. main.dart — จุดเริ่มต้น

**ทำอะไร:** เปิดแอป + ตัดสินใจว่าจะพาไปหน้าไหน

```dart
// ฟัง Firebase Auth ตลอดเวลา
StreamBuilder(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snap) {
    if (snap.data != null) return GameSelectionScreen(); // login แล้ว
    return LoginScreen();                                // ยังไม่ login
  },
)
```

**เชื่อมกับ:** Firebase Auth โดยตรง + ตั้ง Theme (Noto Sans Thai) + locale ไทย

---

## 2. constants.dart — สีทั้งแอป

ไฟล์เล็กที่สุดแต่สำคัญ กำหนดสีกลางที่ทุก screen ดึงไปใช้

```dart
const Color primaryPink = Color(0xFFFCE4EC);  // พื้นหลังชมพูอ่อน
const Color deepPink    = Color(0xFFD81B60);  // ปุ่ม, icon, accent
const Color bgWhite     = Color(0xFFFFFFFF);  // พื้นหลังขาว
const Color textMain    = Color(0xFF212121);  // ข้อความหลัก
const Color textSub     = Color(0xFF666666);  // ข้อความรอง
```

---

## 3. config/game_config.dart — ข้อมูลเกม

**ทำอะไร:** เก็บรายละเอียดของแต่ละเกมที่แอปรองรับ

```dart
class GameConfig {
  final String id;           // 'valorant', 'cs2', ...
  final String displayName;  // 'Valorant', 'CS2', ...
  final bool hasRank;        // มี rank ไหม?
  final List<String> ranks;  // ['Iron', 'Silver', ...]
  final bool hasRole;        // มี role ไหม?
  final int? maxPartySize;   // จำกัดคนไหม?
}
```

**เชื่อมกับ:**
- `GameSelectionScreen` — ดึงรายชื่อเกมมาแสดง
- `CreatePartyScreen` — ดูว่าต้องแสดง dropdown rank/role ไหม
- `PartyFeedScreen` — รับ GameConfig มาแสดงชื่อเกม

**เพิ่มเกมใหม่:** แก้ไฟล์นี้ไฟล์เดียว ทุก screen อัปเดตอัตโนมัติ

---

## 4. models/ — โครงสร้างข้อมูล

Models คือ "พิมพ์เขียว" ของข้อมูล — บอกว่าแต่ละอันมีฟิลด์อะไรบ้าง

### UserProfile
เก็บใน Firestore: `users/{uid}`

| ฟิลด์ | ประเภท | ความหมาย |
|---|---|---|
| uid | String | ID จาก Firebase Auth |
| username | String | ชื่อที่แสดงในแอป |
| email | String | อีเมล |
| avatarUrl | String | URL รูปโปรไฟล์ |
| discordTag | String | Discord username |
| steamId | String | Steam profile URL |
| tagline | String | คำอธิบายตัวเอง |
| traits | List\<String\> | สไตล์การเล่น เช่น ['Aggressive'] |
| createdAt | DateTime | วันที่สมัคร |

```dart
// วิธีสร้าง profile เปล่าตอน register
UserProfile.fresh(uid: uid, username: name, email: email)
// avatarUrl default = https://i.pravatar.cc/300?u={uid}
```

### PartyModel
เก็บใน Firestore: `parties/{partyId}`

| ฟิลด์ | ความหมาย |
|---|---|
| title | ชื่อตี้ เช่น "หาตัวกลาง 2 คน" |
| gameId | 'valorant', 'cs2', ... |
| rank | Rank ที่ต้องการ (optional) |
| role | ตำแหน่งที่ต้องการ (optional) |
| ownerId | uid ของหัวตี้ |
| ownerName | ชื่อหัวตี้ (snapshot ตอนสร้าง) |
| leadAvatar | รูปหัวตี้ (snapshot ตอนสร้าง) |
| memberIds | List uid ของสมาชิกทั้งหมด |
| current | จำนวนคนปัจจุบัน |
| max | จำนวนคนสูงสุด (optional) |

> **Denormalized design:** `ownerName` และ `leadAvatar` เป็น snapshot ตอนสร้าง
> ถ้าหัวตี้เปลี่ยนชื่อ/รูปทีหลัง ตี้เก่าจะยังแสดงชื่อ/รูปเดิม (เหมือน Twitter)

### Message
เก็บใน Firestore: `parties/{partyId}/messages/{msgId}`

| ฟิลด์ | ความหมาย |
|---|---|
| senderId | uid ของคนส่ง |
| senderName | ชื่อผู้ส่ง (snapshot ตอนส่ง) |
| senderAvatar | รูปผู้ส่ง (snapshot ตอนส่ง) |
| text | ข้อความ |
| createdAt | เวลาส่ง |

### Review
เก็บใน Firestore: `users/{targetUid}/reviews/{reviewId}`

| ฟิลด์ | ความหมาย |
|---|---|
| reviewerUid | uid คนเขียนรีวิว |
| reviewerName | ชื่อคนเขียน (snapshot) |
| reviewerAvatar | รูปคนเขียน (snapshot) |
| rating | คะแนน 1-5 |
| text | ข้อความรีวิว |
| createdAt | วันที่รีวิว |

---

## 5. services/ — คุยกับ Firebase

Services คือ "ตัวกลาง" ระหว่าง Screen กับ Firebase
Screen ไม่ควรคุยกับ Firebase ตรงๆ — ให้ผ่าน service เสมอ

### auth_service.dart

```
FirebaseAuth.instance → ห่อด้วย AuthService.instance
```

| method | ทำอะไร |
|---|---|
| `signIn(email, password)` | เข้าสู่ระบบ |
| `register(email, password)` | สร้าง account ใหม่ |
| `signOut()` | ออกจากระบบ |
| `currentUser` | User ปัจจุบัน (หรือ null) |
| `currentUid` | uid ปัจจุบัน |
| `authStateChanges()` | Stream: login/logout |

**ใช้โดย:** main.dart, login_screen, register_screen, game_selection_screen

---

### user_service.dart

```
Firestore: users/{uid}  +  users/{uid}/reviews/{reviewId}
```

| method | ทำอะไร |
|---|---|
| `createOrUpdateProfile(profile)` | บันทึก/อัปเดต profile |
| `getProfile(uid)` | ดึง profile ครั้งเดียว |
| `watchProfile(uid)` | Stream: profile อัปเดต realtime |
| `addReview(targetUid, review)` | เพิ่มรีวิว |
| `watchReviews(targetUid)` | Stream: รีวิวทั้งหมด เรียงใหม่สุดก่อน |
| `watchAverageRating(uid)` | Stream: คะแนนเฉลี่ย |

**ใช้โดย:** profile_screen, edit_profile_screen, write_review_screen, game_selection_screen (avatar), party_detail_screen (ดึงชื่อก่อนส่งแชท)

---

### party_service.dart

```
Firestore: parties/{partyId}  +  parties/{partyId}/messages/
```

| method | ทำอะไร |
|---|---|
| `watchParties(gameId)` | Stream: ตี้ทั้งหมดของเกมนั้น เรียงใหม่สุด |
| `watchParty(partyId)` | Stream: ตี้อันเดียว realtime |
| `createParty(party)` | สร้างตี้ใหม่ คืน partyId |
| `joinParty(partyId, uid)` | เข้าร่วมตี้ (ใช้ transaction กัน race condition) |
| `leaveParty(partyId, uid)` | ออกจากตี้ (owner ออกไม่ได้) |
| `deleteParty(partyId)` | ลบตี้ + messages ทั้งหมด (batch write) |

> **Transaction:** joinParty ใช้ Firestore Transaction เพื่อกัน race condition
> เช่น ตี้เหลือที่ 1 แต่มี 2 คนกด join พร้อมกัน — transaction ทำให้แค่คนแรกเข้าได้

**ใช้โดย:** party_feed_screen, create_party_screen, party_detail_screen, game_selection_screen (นับจำนวนตี้)

---

### chat_service.dart

```
Firestore: parties/{partyId}/messages/{msgId}  (sub-collection)
```

| method | ทำอะไร |
|---|---|
| `sendMessage(partyId, msg)` | ส่งข้อความใหม่ |
| `watchMessages(partyId)` | Stream: ข้อความทั้งหมด เรียงเก่า→ใหม่ |

**ใช้โดย:** party_detail_screen เท่านั้น

---

## 6. screens/ — หน้าต่างๆ

### login_screen.dart

**ทำอะไร:** หน้า login  
**Flow:**
1. user กรอก email + password
2. เรียก `AuthService.instance.signIn()`
3. สำเร็จ → `authStateChanges()` ใน main.dart ดักได้ → พา user ไป GameSelection อัตโนมัติ
4. ไม่สำเร็จ → แสดง error SnackBar

**ปุ่มสมัคร:** `Navigator.push` ไป register_screen

---

### register_screen.dart

**ทำอะไร:** สมัครสมาชิกใหม่  
**Flow:**
1. user กรอกชื่อ + email + password + confirm
2. เรียก `AuthService.instance.register()` → ได้ uid
3. เรียก `UserService.instance.createOrUpdateProfile()` → สร้าง doc `users/{uid}`
4. เรียก `AuthService.instance.signOut()` — บังคับ login เอง (ไม่ให้ข้ามหน้า login)
5. กลับไป login_screen

---

### game_selection_screen.dart

**ทำอะไร:** หน้าหลักหลัง login — เลือกเกมที่จะหาตี้  
**สิ่งที่แสดง:**
- รายการเกมจาก `GameRegistry.all`
- จำนวนตี้ live ของแต่ละเกม (stream `watchPartyCount`)
- รูป avatar ของตัวเองขวาบน (stream `watchProfile`)
- ปุ่ม logout

**เชื่อมกับ:** party_feed_screen, profile_screen

---

### party_feed_screen.dart

**ทำอะไร:** แสดงรายการตี้ของเกมที่เลือก  
**Stream:** `PartyService.instance.watchParties(game.id)` — อัปเดตทันทีถ้ามีตี้ใหม่  
**ปุ่ม FAB (+):** ไป create_party_screen  
**กด card:** ไป party_detail_screen

---

### create_party_screen.dart

**ทำอะไร:** ฟอร์มสร้างตี้ใหม่  
**UI ปรับตาม GameConfig:**
- ถ้า `hasRank = true` → แสดง dropdown rank
- ถ้า `hasRole = true` → แสดง dropdown/chip role
- ถ้า `hasMemberLimit = true` → แสดงจำนวนคนสูงสุด

**Flow:**
1. ดึง profile ตัวเองมา (ชื่อ + รูป)
2. สร้าง `PartyModel` พร้อม snapshot ชื่อ+รูปตอนนี้
3. เรียก `PartyService.instance.createParty()` → บันทึก Firestore
4. Navigator.pop กลับ feed

---

### party_detail_screen.dart

**ทำอะไร:** หน้ารายละเอียดตี้ — ดูสมาชิก + แชท  
**Stream หลัก:**
- `watchParty(partyId)` — ดูสถานะตี้ realtime (คนเข้า/ออก)
- `watchMessages(partyId)` — แชท realtime

**Actions ตาม role:**
- เป็น owner → ปุ่ม Delete Party
- ไม่ใช่ owner, ยังไม่ได้เข้า → ปุ่ม Join
- เป็นสมาชิก → ปุ่ม Leave
- กดรูป member → ไป profile_screen ของคนนั้น

**ส่งแชท:**
1. ดึง profile ตัวเองมา (ชื่อ + รูป)
2. สร้าง Message object
3. เรียก `ChatService.instance.sendMessage()`
4. auto-scroll ลงล่าง

---

### profile_screen.dart

**ทำอะไร:** แสดงโปรไฟล์ (ของตัวเอง หรือคนอื่น)  
**รับ:** `uid` (optional) — ถ้าไม่ส่ง = โปรไฟล์ตัวเอง

| กรณี | ปุ่มที่เห็น |
|---|---|
| `uid == myUid` | Edit Profile |
| `uid != myUid` | Write Review |

**Stream:** `watchProfile(uid)` + `watchReviews(uid)` + `watchAverageRating(uid)`

---

### edit_profile_screen.dart

**ทำอะไร:** แก้ไขโปรไฟล์  
**ฟิลด์:** ชื่อ, tagline, discord, steam, traits  
**รูปโปรไฟล์:** แตะรูป → `image_picker` เปิด gallery → preview ทันที  
**บันทึก:**
1. ถ้าเลือกรูปใหม่ → upload ขึ้น Firebase Storage → ได้ URL
2. `UserService.instance.createOrUpdateProfile()` (merge: true)
3. Navigator.pop กลับ profile_screen

---

### write_review_screen.dart

**ทำอะไร:** เขียนรีวิว user อื่น  
**ใช้:** `flutter_rating_bar` สำหรับ star rating  
**บันทึก:** `UserService.instance.addReview(targetUid, review)`  
**ป้องกัน:** Firestore Rules บล็อกไม่ให้รีวิวตัวเอง

---

## 7. Firestore Schema แบบเต็ม

```
users/
  {uid}/
    ├── username: "GamerXYZ"
    ├── email: "x@email.com"
    ├── avatarUrl: "https://..."
    ├── discordTag: "user#1234"
    ├── steamId: "steamcommunity.com/..."
    ├── tagline: "Professional Duelist"
    ├── traits: ["Aggressive", "Friendly"]
    ├── createdAt: Timestamp
    └── reviews/
          {reviewId}/
            ├── reviewerUid: "..."
            ├── reviewerName: "..."
            ├── reviewerAvatar: "https://..."
            ├── rating: 4.5
            ├── text: "เล่นดีมาก!"
            └── createdAt: Timestamp

parties/
  {partyId}/
    ├── title: "หาตัวกลาง 2 คน"
    ├── gameId: "valorant"
    ├── rank: "Ascendant+"
    ├── role: ["Duelist", "Controller"]
    ├── ownerId: "uid123"
    ├── ownerName: "GamerXYZ"
    ├── leadAvatar: "https://..."
    ├── memberIds: ["uid123", "uid456"]
    ├── current: 2
    ├── max: 5
    ├── createdAt: Timestamp
    └── messages/
          {msgId}/
            ├── senderId: "uid123"
            ├── senderName: "GamerXYZ"
            ├── senderAvatar: "https://..."
            ├── text: "สวัสดี!"
            └── createdAt: Timestamp
```

---

## 8. Data Flow — ตัวอย่างเต็มๆ

### เมื่อ user ส่งข้อความในตี้

```
party_detail_screen
  → กดปุ่มส่ง
  → UserService.getProfile(myUid)  ← ดึงชื่อ+รูปตัวเอง
  → สร้าง Message object
  → ChatService.sendMessage(partyId, msg)
  → Firestore: เพิ่ม doc ใน parties/{id}/messages/
  → ChatService.watchMessages() stream emit ค่าใหม่
  → ListView rebuild แสดงข้อความใหม่ (ทุก device ที่เปิดอยู่)
```

### เมื่อ user เข้าร่วมตี้

```
party_detail_screen
  → กดปุ่ม Join
  → PartyService.joinParty(partyId, uid)
  → Firestore Transaction:
      read party doc
      ตรวจ memberIds.length < max
      ตรวจ uid ไม่ได้อยู่แล้ว
      update memberIds + current
  → watchParty() stream emit
  → UI แสดงจำนวนคนใหม่ทันที
```

### เมื่อ user เปลี่ยนรูปโปรไฟล์

```
edit_profile_screen
  → แตะรูป → ImagePicker.pickImage(gallery)
  → preview ด้วย Image.file()
  → กด บันทึก
  → StorageService.uploadAvatar(uid, file)
      Firebase Storage: avatars/{uid}.jpg
      ได้ downloadUrl
  → UserService.createOrUpdateProfile(updated)
      Firestore: users/{uid}.avatarUrl = downloadUrl
  → watchProfile() stream emit ทุกที่ที่แสดงรูปนี้
```

---

## 9. Firebase Rules — สรุป

### Firestore Rules

```js
parties: ใครก็อ่านได้, login แล้ว create/update ได้, owner เท่านั้นที่ delete ได้
messages: login แล้ว read/create ได้
users: ใครก็อ่านได้, เจ้าของเท่านั้น write ได้
reviews: ใครก็อ่านได้, login แล้ว create ได้ แต่รีวิวตัวเองไม่ได้
```

### Storage Rules

```js
avatars/{uid}.jpg: ใครก็อ่านได้, เจ้าของ uid เท่านั้น upload ได้
```

---

## 10. Package ที่ใช้

| Package | ใช้ทำอะไร |
|---|---|
| `firebase_core` | เปิดใช้งาน Firebase |
| `firebase_auth` | login / register |
| `cloud_firestore` | database |
| `google_fonts` | Noto Sans Thai |
| `flutter_rating_bar` | ดาว 1-5 ใน review |
| `flutter_localizations` | locale ภาษาไทย |
