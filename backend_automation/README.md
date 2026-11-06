# 🥩 Fresh Meat Market — Telegram Bot & Google Sheets Live Automation

A **100% free**, zero-maintenance, serverless automation that allows the shop owner or butcher to update daily meat prices directly from a **Telegram chat**, records every price update and order in **Google Sheets**, and live-syncs the new rates directly to the **Fresh Meat Flutter Mobile App** with offline caching.

---

## ⚡ System Architecture

```text
               ┌───────────────────────┐
               │  Owner's Telegram     │
               │  /price mutton 850    │
               └───────────┬───────────┘
                           │ Webhook (HTTPS)
                           ▼
               ┌───────────────────────┐
               │ Google Apps Script    │ (100% Free Serverless)
               │ Web App [doPost/doGet]│
               └─────┬───────────┬─────┘
                     │           │
     Writes & Audits │           │ Delivers Live JSON
                     ▼           ▼
        ┌──────────────────┐   ┌───────────────────────────┐
        │  Google Sheets   │   │  Fresh Meat Flutter App   │
        │  - Daily_Pricing │   │  - Auto-sync on startup   │
        │  - Daily_Records │   │  - Pull-to-refresh        │
        │  - Daily_Orders  │   │  - SharedPreferences cache│
        └──────────────────┘   └───────────────────────────┘
```

---

## 🚀 3-Minute Setup Guide

### Step 1: Create your Free Telegram Bot (30 seconds)
1. Open Telegram and search for **`@BotFather`** (the official verified bot).
2. Send: `/newbot`
3. Enter a display name (e.g. `Fresh Meat Manager`).
4. Enter a username ending in `bot` (e.g. `fresh_meat_market_bot`).
5. **Copy the HTTP API Token** given to you (e.g. `7891234567:AAFl...`).

---

### Step 2: Create your Google Sheet & Paste the Script
1. Go to [Google Sheets](https://sheets.new) and create a new sheet.
2. Name it **"Fresh Meat Market Database"**.
3. In the top menu, click **Extensions** > **Apps Script**.
4. Clear out `function myFunction() {}` and paste the entire content of:
   [`backend_automation/telegram_sheets_bot.gs`](file:///e:/Fresh%20Meat/backend_automation/telegram_sheets_bot.gs)
5. At the top of the file, replace:
   ```javascript
   const TELEGRAM_BOT_TOKEN = "PASTE_YOUR_TELEGRAM_BOT_TOKEN_HERE";
   ```
6. Click the **Save** (💾) icon.
7. Select **`setupDatabaseSheets`** from the function dropdown and click **Run**.
   *(Google will prompt for a one-time permission — click Advanced > Proceed).*
   This creates the formatted `Daily_Pricing`, `Daily_Records`, and `Daily_Orders` sheets automatically!

---

### Step 3: Deploy as a Web App & Register Webhook
1. In the Apps Script top bar, click **Deploy** > **New deployment**.
2. Click the gear icon (⚙️) next to *Select type* and choose **Web app**.
3. Configure the settings:
   - **Description**: `Fresh Meat Live Pricing Webhook`
   - **Execute as**: `Me`
   - **Who has access**: `Anyone` *(Important: required for Telegram and Flutter to access)*
4. Click **Deploy** and **copy the Web App URL** (e.g. `https://script.google.com/macros/s/AKfycbx.../exec`).
5. Back in the Apps Script editor:
   - Paste that URL into:
     ```javascript
     const WEB_APP_URL = "https://script.google.com/macros/s/AKfycbx.../exec";
     ```
   - Click **Save** (💾).
   - Select **`setTelegramWebhook`** from the dropdown and click **Run**.
   - The execution log will print: `✅ Telegram Webhook registered successfully!`.

---

### Step 4: Link to Fresh Meat Flutter App
You have two easy ways:

#### Option A: Inside the App (Instant UI)
1. Open the Fresh Meat app.
2. Tap your Profile picture (or the top left menu) to open your Profile.
3. Tap **"Daily Pricing Automation"**.
4. Paste your **Google Apps Script Web App URL** and tap **"Save & Sync"**.
5. The app immediately fetches the live prices and displays a green **"Live Synced"** badge.

#### Option B: Set as Permanent Project Default
Open [`lib/services/price_sync_service.dart`](file:///e:/Fresh%20Meat/lib/services/price_sync_service.dart) and set line 16:
```dart
static String? defaultEndpoint = 'https://script.google.com/macros/s/AKfycbx.../exec';
```

---

## 📱 Telegram Bot: Interactive Buttons & Commands

The bot features a **persistent bottom keyboard** with one-tap buttons, plus natural shortcuts and standard slash commands:

### 🔘 One-Tap Buttons (No typing needed!)
- **`📊 Check Today's Rates`** — Shows full catalog with live ₹/kg rates.
- **`🐐 Set Mutton Rate`** — Prompt to set Mutton rate (just reply with number like `850`).
- **`🍗 Set Chicken Rate`** — Prompt to set Chicken rate (e.g. `280`).
- **`🥩 Set Beef Rate`** — Prompt to set Beef rate (e.g. `420`).
- **`📦 Today's Orders`** — Shows today's order count & revenue.

### ⚡ Natural Shortcuts (Fastest for the butcher)
You can simply type:
- `mutton 850`
- `chicken 280`
- `beef 420`
- `m1 890` (Updates Mutton Curry Cut specifically)
- `c2 360` (Updates Boneless Chicken Breast)
- `rates`

### 📋 Full Command Reference

| Action | Quick Syntax | Full Slash Command |
| :--- | :--- | :--- |
| View Rates | Tap `📊 Rates` or type `rates` | `/rates` |
| Set Mutton | `mutton 850` | `/price mutton 850` |
| Set Chicken | `chicken 280` | `/price chicken 280` |
| Set Beef | `beef 420` | `/price beef 420` |
| Set Specific Cut | `m1 890` | `/price m1 890` |
| Today's Orders | Tap `📦 Orders` or type `orders` | `/orders` |


---

## 📊 Google Sheets Structure

### 1. `Daily_Pricing`
| Product ID | Name | Category | Base Rate | Live Rate (₹/Kg) | Difference | Last Updated |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `m1` | Mutton Curry Cut | mutton | ₹820 | **₹850** | +₹30 | Today 06:30 AM |
| `c2` | Boneless Chicken Breast | chicken | ₹340 | **₹360** | +₹20 | Today 06:30 AM |

### 2. `Daily_Records` (Audit Log)
Every single change made via Telegram is permanently logged:
- **Timestamp**: e.g. `2026-10-16 06:30:15`
- **Target Item**: `Mutton Curry Cut (m1)` or `Category: chicken`
- **Old Price**: `₹820`
- **New Price**: `₹850`
- **Difference**: `+₹30`
- **Updated By**: `@owner_username (ID: 12345678)`

### 3. `Daily_Orders`
- Records incoming customer orders, customer contact, items purchased, slot, and total revenue.

---

## 🛡️ Offline & Fail-Safe Design
- If internet is temporarily lost, the app seamlessly serves the **last synced rates** stored in device `SharedPreferences`.
- If no sync has occurred yet, the app falls back safely to the baseline catalogue values in [`lib/data.dart`](file:///e:/Fresh%20Meat/lib/data.dart).
- Zero paid API keys, zero cloud server bills, zero maintenance.
