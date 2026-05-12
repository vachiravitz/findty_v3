# Findty (หาตี้) 🎮

แอปหาเพื่อนเล่นเกมแบบเรียลไทม์ — สร้างตี้ / **เข้าร่วมตี้** / **ลบตี้** / แชทในตี้ / รีวิวเพื่อนร่วมตี้ ผ่าน Firebase
และรองรับ **Dynamic Game Configuration** (เพิ่ม/ลดเกมได้ผ่านหลังบ้านโดยไม่ต้องอัปเดตแอป)

---

## ✨ Features

- ☁️ **Dynamic Game Registry** — ดึงรายชื่อเกม กฎของเกม (Rank, Role, Party Size) และรูปภาพจาก Firestore แบบ Real-time เพิ่มเกมใหม่ได้ทันทีผ่าน Firebase Console
- 🔍 **Search & Category Filter** — ค้นหาเกมจากชื่อ หรือกรองตามหมวดหมู่ (เช่น FPS, MOBA, Battle Royale)
- 🔐 **Firebase Auth** — Register / Login ด้วย Email + Password
- 👤 **User Profiles** — โปรไฟล์ส่วนตัว (ชื่อ, รูป Avatar, Tagline, Discord, Steam, Style Traits)
- 🔄 **Real-time Party Feed** — มีคนสร้างตี้ที่ไหน ฟีดอัปเดตทันที
- ✋ **Join / Leave Party** — กดปุ่ม "เข้าร่วมตี้" (ใช้ Firestore transaction ป้องกันคนเข้าเกินจำนวน)
- 🗑️ **Delete Party** — หัวตี้ลบตี้ของตัวเองได้ (ลบประวัติการแชทพร้อมกันอัตโนมัติ)
- 👥 **Member Tracking** — รู้ว่าใครอยู่ในตี้บ้าง โชว์ Avatar และกดเข้าไปดูโปรไฟล์เพื่อนได้
- 💬 **Chat in Party** — แชทเรียลไทม์ในตี้ นัดแนะ ส่งชื่อ/Discord ให้แอดกัน
- ⭐ **Reviews System** — รีวิวเพื่อนร่วมตี้หลังเล่นเสร็จ (ให้ดาว + ข้อความ + ชื่อ + วันเวลา)
- 🖼️ **Remote Network Icons** — ดึงรูปภาพไอคอนเกมจาก Firebase Storage (ลดขนาดไฟล์แอป) พร้อมระบบ Fallback Material Icon

---

## 📁 โครงสร้างโปรเจกต์ (ว่าอะไรอยู่ตรงไหน)

```text
lib/
├── main.dart                          # จุดเริ่มต้นแอป, ตั้งค่า Theme, เช็ค Auth State (ล็อกอินหรือยัง)
├── firebase_options.dart              # ตั้งค่าการเชื่อมต่อ Firebase
├── constants.dart                     # เก็บค่าสี (Colors) และค่าคงที่ต่างๆ ของแอป
│
├── config/
│   └── game_config.dart               # โมเดล GameConfig (แปลงข้อมูล json จาก Firestore ให้เป็น Object)
│
├── models/
│   ├── party_model.dart               # โครงสร้างข้อมูลตี้ (หัวตี้, สมาชิก, จำนวนรับ, เกมที่เล่น)
│   ├── user_profile_model.dart        # โครงสร้างข้อมูลโปรไฟล์ผู้ใช้
│   ├── review_model.dart              # โครงสร้างข้อมูลรีวิวคะแนน
│   └── message_model.dart             # โครงสร้างข้อมูลข้อความแชทในตี้
│
├── services/
│   ├── auth_service.dart              # จัดการ Login, Register, SignOut (Firebase Auth)
│   ├── game_service.dart              # ดึงข้อมูลรายชื่อเกมทั้งหมดจาก Firestore Collection 'games'
│   ├── user_service.dart              # CRUD ข้อมูลโปรไฟล์และระบบรีวิว
│   ├── party_service.dart             # จัดการสร้าง, เข้าร่วม, ออก, ลบตี้ (ใช้ Transaction)
│   └── chat_service.dart              # จัดการส่งข้อความและดึงข้อความแชท (Real-time Stream)
│
└── screens/
    ├── login_screen.dart              # หน้าเข้าสู่ระบบ
    ├── register_screen.dart           # หน้าสมัครสมาชิก
    ├── game_selection_screen.dart     # หน้าแรกหลังล็อกอิน: แสดงรายการเกม, ช่องค้นหา, และปุ่ม Filter หมวดหมู่
    ├── party_feed_screen.dart         # หน้ากระดานหาตี้ของเกมนั้นๆ (Party Feed)
    ├── create_party_screen.dart       # หน้าสร้างตี้: รองรับกฎของแต่ละเกม (เช่น เลือกได้หลาย Role สำหรับ Valorant)
    ├── party_detail_screen.dart       # หน้าห้องตี้: แสดงสมาชิก, ปุ่ม Join/Leave/Delete, และช่องแชท
    ├── profile_screen.dart            # หน้าแสดงโปรไฟล์ผู้ใช้ และโชว์คะแนนรีวิว
    ├── edit_profile_screen.dart       # หน้าแก้ไขโปรไฟล์ตัวเอง
    └── write_review_screen.dart       # หน้าเขียนรีวิวให้ผู้อื่น
```

---

## 🔥 Firestore Schema (ฐานข้อมูล)

ระบบถูกออกแบบมาให้ข้อมูลแยกกันอย่างชัดเจนและรองรับการ Scale:

```text
games/{gameId}                          <-- (จัดการผ่าน Firebase Console)
  └─ displayName, iconUrl, category, hasRank, ranks[], hasRole, roles[], allowMultiRole, maxPartySize, memberLabel

users/{uid}
  ├─ username, email, avatarUrl, discordTag, steamId, tagline, traits[]
  └─ reviews/{reviewId}                 <-- (Sub-collection เก็บรีวิวที่คนอื่นเขียนให้ user นี้)
       └─ reviewerUid, reviewerName, reviewerAvatar, rating, text, createdAt

parties/{partyId}
  ├─ title, gameId, rank?, role?
  ├─ current, max?
  ├─ ownerId, ownerName, leadAvatar
  ├─ memberIds[]
  ├─ createdAt
  └─ messages/{msgId}                   <-- (Sub-collection เก็บข้อความแชทภายในตี้)
       └─ senderId, senderName, senderAvatar, text, createdAt
```

---

## 🚀 การจัดการเกมแบบ Dynamic (วิธีเพิ่มเกมใหม่)

แอปพลิเคชันไม่ต้องแก้ไขโค้ดหรือ Build ใหม่เมื่อต้องการเพิ่มเกม หากต้องการเพิ่มเกมให้ทำตามนี้:

1. ไปที่ Firebase Console -> Firestore Database
2. ไปที่ Collection `games` -> กด **Add Document**
3. ตั้งชื่อ **Document ID** เป็นตัวพิมพ์เล็ก (เช่น `apex`)
4. เพิ่ม Field ดังนี้:
   * `displayName` (string): ชื่อที่จะแสดง เช่น "Apex Legends"
   * `iconUrl` (string): URL รูปภาพจาก Firebase Storage
   * `category` (string): หมวดหมู่ (เช่น "Battle Royale", "FPS")
   * `hasRank` (boolean): `true` ถ้ามีระบบแรงค์
   * `ranks` (array): รายชื่อแรงค์ เช่น `["Bronze", "Silver", "Gold"]`
   * `hasRole` (boolean): `true` ถ้าต้องเลือกตำแหน่ง
   * `roles` (array): รายชื่อตำแหน่ง
   * `allowMultiRole` (boolean): `true` ถ้ายอมให้กดเลือกหาหลายตำแหน่งพร้อมกันได้
   * `maxPartySize` (number/int64): จำนวนคนรับสูงสุดต่อตี้ (เช่น `3`)
   * `memberLabel` (string): สรรพนามเรียกคน (เช่น "คน", "ผู้เล่น")

> ทันทีที่กด Save เกมใหม่จะโผล่ในหน้า `GameSelectionScreen` ทันทีแบบ Real-time

---

## 🔒 Firestore Rules ที่อัปเดตล่าสุด

เพื่อความปลอดภัย ป้องกันผู้ใช้ทั่วไปแก้ไขรายชื่อเกม และป้องกันการแก้ไขโปรไฟล์คนอื่น:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // กฎสำหรับรายชื่อเกม: ให้ทุกคนอ่านได้ แต่แก้ไขจากแอปไม่ได้ (ต้องแก้ผ่าน Console เท่านั้น)
    match /games/{gameId} {
      allow read: if true; 
      allow write: if false; 
    }

    match /parties/{partyId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null;        // join/leave
      allow delete: if request.auth != null
                    && resource.data.ownerId == request.auth.uid;
      match /messages/{msgId} {
        allow read, create: if request.auth != null;
        allow delete: if request.auth != null;       // ให้หัวตี้ลบแชทตอนลบห้องได้
      }
    }

    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId; // แก้โปรไฟล์ตัวเองได้เท่านั้น
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null && request.auth.uid != userId; // เขียนรีวิวให้ตัวเองไม่ได้
      }
    }
  }
}
```

---

## 📝 TODO List (สิ่งที่พัฒนาต่อยอดได้)

- [ ] Auto-redirect: นัดแนะพาทุกคนออกจากหน้าแชทกลับไปหน้าฟีดอัตโนมัติเมื่อหัวตี้ลบห้อง
- [ ] My Parties: หน้าตรวจสอบว่าตอนนี้ฉัน Join ตี้ไหนค้างไว้บ้าง (`where memberIds array-contains <my uid>`)
- [ ] Image Picker: อัปโหลดรูปโปรไฟล์จาก Gallery ในเครื่องขึ้น Firebase Storage
- [ ] Push Notification: แจ้งเตือนเมื่อมีคน Join ตี้ หรือมีข้อความแชทใหม่ (Firebase Messaging)
```
