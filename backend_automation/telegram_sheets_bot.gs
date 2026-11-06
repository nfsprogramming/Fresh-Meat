/**
 * FRESH MEAT MARKET - TELEGRAM INLINE BUTTONS CONTROL DASHBOARD (v3.0)
 * ---------------------------------------------------------------------
 * 100% Free, Serverless Daily Pricing & Order Records System.
 * 
 * FEATURES:
 * • 100% Inline Buttons UI - Control daily pricing directly with buttons!
 * • Quick steppers: [+₹10], [-₹10], [+₹50], [-₹50]
 * • Quick presets: [₹800], [₹850], [₹900], etc.
 * • In-place message updating (no messy chat spam)
 * • Instant haptic feedback toasts on button tap
 * • Safe HTML rendering & zero 302 redirects
 * • Live real-time sync with Google Sheets & Fresh Meat Flutter App
 */

// =============================================================================
// CONFIGURATION
// =============================================================================
const TELEGRAM_BOT_TOKEN = "PASTE_YOUR_TELEGRAM_BOT_TOKEN_HERE";
const WEB_APP_URL = "https://script.google.com/macros/s/AKfycbyso5g4C2erayybtWs1mM8BIk-KgcYCbYGG0yWgEMOcaFkutQppW7hyohrlEe2XOzVO/exec";

const SHEET_PRICING = "Daily_Pricing";
const SHEET_RECORDS = "Daily_Records";
const SHEET_ORDERS  = "Daily_Orders";

// Initial Catalog Baseline (Rates in ₹/Kg)
const INITIAL_PRODUCTS = [
  // Mutton
  { id: "m1", name: "Mutton Curry Cut (Bone-in)", category: "mutton", price: 820 },
  { id: "m2", name: "Mutton Biryani Special Cut", category: "mutton", price: 880 },
  { id: "m3", name: "Prime Mutton Rib Chops", category: "mutton", price: 960 },
  { id: "m4", name: "Boneless Tender Mutton", category: "mutton", price: 980 },
  { id: "m5", name: "Kashmiri Rogan Josh Shank", category: "mutton", price: 920 },
  { id: "m6", name: "Mutton Paya (Cleaned)", category: "mutton", price: 540 },
  // Chicken
  { id: "c1", name: "Tender Chicken Curry Cut", category: "chicken", price: 260 },
  { id: "c2", name: "Fresh Boneless Chicken Breast", category: "chicken", price: 340 },
  { id: "c3", name: "Tandoori Chicken Drumsticks", category: "chicken", price: 310 },
  { id: "c4", name: "Chicken Biryani Cut (Skinless)", category: "chicken", price: 280 },
  { id: "c5", name: "Fresh Chicken Keema (Mince)", category: "chicken", price: 360 },
  { id: "c6", name: "Crispy Chicken Lollipop Wings", category: "chicken", price: 290 },
  // Beef
  { id: "b1", name: "Prime Halal Beef Steak Cut", category: "beef", price: 420 },
  { id: "b2", name: "Beef Curry Cut (Bone-in)", category: "beef", price: 380 },
  { id: "b3", name: "Boneless Beef Tenderloin", category: "beef", price: 460 },
  { id: "b4", name: "Marinated Beef Nihari Shank", category: "beef", price: 440 },
  { id: "b5", name: "Beef Ribs / Pot Roast Cut", category: "beef", price: 400 },
  { id: "b6", name: "Lean Ground Beef Keema", category: "beef", price: 390 }
];

// =============================================================================
// DATABASE INITIALIZER
// =============================================================================
function setupDatabaseSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  let priceSheet = ss.getSheetByName(SHEET_PRICING);
  if (!priceSheet) priceSheet = ss.insertSheet(SHEET_PRICING);
  priceSheet.clear();
  priceSheet.getRange(1, 1, 1, 6).setValues([["Product ID", "Category", "Cut / Item Name", "Price Per Kg (₹)", "Last Updated", "Updated By"]])
    .setBackground("#8B0000").setFontColor("#FFFFFF").setFontWeight("bold");
  
  const initialRows = INITIAL_PRODUCTS.map(p => [
    p.id, p.category, p.name, p.price, new Date().toISOString(), "System Default"
  ]);
  priceSheet.getRange(2, 1, initialRows.length, 6).setValues(initialRows);
  priceSheet.setFrozenRows(1);
  priceSheet.autoResizeColumns(1, 6);

  let recordSheet = ss.getSheetByName(SHEET_RECORDS);
  if (!recordSheet) recordSheet = ss.insertSheet(SHEET_RECORDS);
  if (recordSheet.getLastRow() === 0) {
    recordSheet.getRange(1, 1, 1, 8).setValues([["Timestamp", "Target (Category/ID)", "Cut Name", "Old Price (₹)", "New Price (₹)", "Difference (₹)", "Telegram User", "Notes"]])
      .setBackground("#1E3A8A").setFontColor("#FFFFFF").setFontWeight("bold");
    recordSheet.setFrozenRows(1);
    recordSheet.autoResizeColumns(1, 8);
  }

  let orderSheet = ss.getSheetByName(SHEET_ORDERS);
  if (!orderSheet) orderSheet = ss.insertSheet(SHEET_ORDERS);
  if (orderSheet.getLastRow() === 0) {
    orderSheet.getRange(1, 1, 1, 8).setValues([["Order ID", "Date Time", "Customer Name", "Phone/Email", "Address", "Payment Method", "Total Amount (₹)", "Items Ordered"]])
      .setBackground("#065F46").setFontColor("#FFFFFF").setFontWeight("bold");
    orderSheet.setFrozenRows(1);
    orderSheet.autoResizeColumns(1, 8);
  }

  Logger.log("✅ Fresh Meat Market sheets created and formatted successfully!");
}

function setTelegramWebhook() {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook?url=${encodeURIComponent(WEB_APP_URL)}&drop_pending_updates=true`;
  const response = UrlFetchApp.fetch(url);
  Logger.log("Telegram setWebhook response: " + response.getContentText());
}

// =============================================================================
// HTTP GET (API Endpoint for Flutter App)
// =============================================================================
function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let priceSheet = ss.getSheetByName(SHEET_PRICING);
    if (!priceSheet) {
      setupDatabaseSheets();
      priceSheet = ss.getSheetByName(SHEET_PRICING);
    }

    // Support updating prices via GET
    if (e && e.parameter && e.parameter.action === "update") {
      const target = (e.parameter.target || "").toLowerCase().trim();
      const price = parseFloat(e.parameter.price);
      const user = e.parameter.user || "Manager";

      if (["mutton", "chicken", "beef"].indexOf(target) >= 0) {
        updateCategoryPrice(target, price, user);
      } else {
        updateCutPrice(target, price, user);
      }

      return ContentService.createTextOutput(JSON.stringify({
        status: "success",
        target: target,
        newPrice: price,
        updatedAt: new Date().toISOString()
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const data = priceSheet.getDataRange().getValues().slice(1);
    const prices = {};
    const categories = { mutton: 0, chicken: 0, beef: 0 };
    const counts = { mutton: 0, chicken: 0, beef: 0 };

    data.forEach(r => {
      const id = String(r[0]).trim();
      const cat = String(r[1]).trim().toLowerCase();
      const price = Number(r[3]) || 0;
      if (id) {
        prices[id] = price;
        if (categories[cat] !== undefined) {
          categories[cat] += price;
          counts[cat]++;
        }
      }
    });

    for (const cat in categories) {
      if (counts[cat] > 0) {
        categories[cat] = Math.round(categories[cat] / counts[cat]);
      }
    }

    const payload = {
      status: "success",
      store: "Fresh Meat Market",
      updatedAt: new Date().toISOString(),
      categories: categories,
      prices: prices
    };

    return ContentService.createTextOutput(JSON.stringify(payload)).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ status: "error", message: err.toString() })).setMimeType(ContentService.MimeType.JSON);
  }
}

// =============================================================================
// HTTP POST (Receives Telegram Messages & Button Clicks)
// =============================================================================
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return HtmlService.createHtmlOutput("OK");
    }

    const update = JSON.parse(e.postData.contents);

    // -------------------------------------------------------------------------
    // A. HANDLE INLINE BUTTON CLICKS (Callback Queries)
    // -------------------------------------------------------------------------
    if (update.callback_query) {
      const q = update.callback_query;
      const queryId = q.id;
      const data = q.data || "";
      const chatId = q.message.chat.id;
      const messageId = q.message.message_id;
      const user = q.from.first_name || "Manager";

      handleCallback(chatId, messageId, queryId, data, user);
      return HtmlService.createHtmlOutput("OK");
    }

    // -------------------------------------------------------------------------
    // B. HANDLE TEXT MESSAGES
    // -------------------------------------------------------------------------
    if (update.message && update.message.text) {
      const chatId = update.message.chat.id;
      const text = update.message.text.trim();
      const lower = text.toLowerCase().replace(/@[a-zA-Z0-9_]+/g, "");
      const user = update.message.from.first_name || update.message.from.username || "Manager";

      // 1. Check if user was prompted to type a custom price
      const cache = CacheService.getScriptCache();
      const pendingCat = cache.get("pending_cat_" + chatId);
      const numOnly = parseFloat(text.replace(/[^0-9.]/g, ""));

      if (pendingCat && !isNaN(numOnly) && numOnly > 0) {
        cache.remove("pending_cat_" + chatId);
        updateCategoryPrice(pendingCat, numOnly, user);
        sendTelegramMessage(chatId, `✅ <b>${pendingCat.toUpperCase()}</b> price updated to <b>₹${Math.round(numOnly)}/kg</b>!`);
        sendDashboardMessage(chatId);
        return HtmlService.createHtmlOutput("OK");
      }

      // 2. Direct shortcut typing: e.g. "mutton 850" or "chicken 280" or "/price mutton 850"
      const match = lower.match(/^(?:\/price\s+|\/set\s+)?(mutton|chicken|beef|[mcb][1-6])\s+(\d+)$/i);
      if (match) {
        const target = match[1];
        const newPrice = parseFloat(match[2]);
        if (["mutton", "chicken", "beef"].indexOf(target) >= 0) {
          updateCategoryPrice(target, newPrice, user);
          sendTelegramMessage(chatId, `✅ <b>${target.toUpperCase()}</b> set to <b>₹${Math.round(newPrice)}/kg</b>!`);
        } else {
          updateCutPrice(target, newPrice, user);
          sendTelegramMessage(chatId, `✅ Cut <code>${target}</code> set to <b>₹${Math.round(newPrice)}/kg</b>!`);
        }
        sendDashboardMessage(chatId);
        return HtmlService.createHtmlOutput("OK");
      }

      // 3. Default: Show the Main Interactive Dashboard
      sendDashboardMessage(chatId);
    }

    return HtmlService.createHtmlOutput("OK");
  } catch (err) {
    Logger.log("doPost error: " + err);
    return HtmlService.createHtmlOutput("OK");
  }
}

// =============================================================================
// INLINE BUTTON CALLBACK DISPATCHER
// =============================================================================
function handleCallback(chatId, messageId, queryId, data, user) {
  try {
    const parts = data.split(":");
    const action = parts[0];

    if (action === "menu") {
      const page = parts[1];
      if (page === "main") {
        answerCallbackQuery(queryId);
        renderMainDashboard(chatId, messageId);
      } else if (page === "mutton" || page === "chicken" || page === "beef") {
        answerCallbackQuery(queryId);
        renderCategoryAdjuster(chatId, messageId, page);
      } else if (page === "catalog") {
        answerCallbackQuery(queryId);
        renderFullCatalog(chatId, messageId);
      } else if (page === "orders") {
        answerCallbackQuery(queryId);
        renderOrdersView(chatId, messageId);
      }
    } 
    else if (action === "adjust") {
      // Delta adjustment: e.g. adjust:mutton:10 or adjust:chicken:-20
      const cat = parts[1];
      const delta = parseInt(parts[2], 10);
      const current = getCategoryAverage(cat);
      const newPrice = Math.max(50, current + delta);

      updateCategoryPrice(cat, newPrice, user);
      answerCallbackQuery(queryId, `✅ ${cat.toUpperCase()} set to ₹${newPrice}/kg!`);
      renderCategoryAdjuster(chatId, messageId, cat);
    } 
    else if (action === "set") {
      // Preset direct set: e.g. set:mutton:850
      const cat = parts[1];
      const newPrice = parseInt(parts[2], 10);

      updateCategoryPrice(cat, newPrice, user);
      answerCallbackQuery(queryId, `✅ ${cat.toUpperCase()} set to ₹${newPrice}/kg!`);
      renderCategoryAdjuster(chatId, messageId, cat);
    } 
    else if (action === "custom") {
      const cat = parts[1];
      const cache = CacheService.getScriptCache();
      cache.put("pending_cat_" + chatId, cat, 180);
      answerCallbackQuery(queryId, `Type the new ${cat} price in chat`);
      sendTelegramMessage(chatId, `✏️ <b>Enter new ${cat.toUpperCase()} price in ₹/kg:</b>\n<i>(Simply send the number, e.g. <b>870</b>)</i>`);
    }
  } catch (err) {
    Logger.log("handleCallback error: " + err);
    answerCallbackQuery(queryId, "Error: " + err);
  }
}

// =============================================================================
// SCREEN RENDERERS (With Rich Inline Buttons)
// =============================================================================

function sendDashboardMessage(chatId) {
  const content = buildDashboardContent();
  sendTelegramMessage(chatId, content.text, content.keyboard);
}

function renderMainDashboard(chatId, messageId) {
  const content = buildDashboardContent();
  editTelegramMessage(chatId, messageId, content.text, content.keyboard);
}

function buildDashboardContent() {
  const rates = getCategoryAverages();
  const timeStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+5:30", "dd MMM, hh:mm a");

  const text =
    `🥩 <b>FRESH MEAT MARKET — PRICE DASHBOARD</b> 🥩\n\n` +
    `Today's Live Base Rates:\n` +
    `🐐 <b>Mutton:</b>  <b>₹${rates.mutton}/kg</b>\n` +
    `🍗 <b>Chicken:</b> <b>₹${rates.chicken}/kg</b>\n` +
    `🥩 <b>Beef:</b>    <b>₹${rates.beef}/kg</b>\n\n` +
    `🕒 <i>Updated: ${timeStr}</i>\n` +
    `🟢 <i>Google Sheets & Mobile App are synced.</i>\n\n` +
    `👇 <b>Tap a button below to adjust prices:</b>`;

  const keyboard = [
    [
      { text: `🐐 Mutton (₹${rates.mutton})`, callback_data: "menu:mutton" },
      { text: `🍗 Chicken (₹${rates.chicken})`, callback_data: "menu:chicken" }
    ],
    [
      { text: `🥩 Beef (₹${rates.beef})`, callback_data: "menu:beef" },
      { text: "📋 Full Catalog (18 Cuts)", callback_data: "menu:catalog" }
    ],
    [
      { text: "📦 Today's Orders", callback_data: "menu:orders" },
      { text: "🔄 Refresh Live", callback_data: "menu:main" }
    ]
  ];

  return { text: text, keyboard: keyboard };
}

function renderCategoryAdjuster(chatId, messageId, cat) {
  const current = getCategoryAverage(cat);
  const emoji = cat === "mutton" ? "🐐" : cat === "chicken" ? "🍗" : "🥩";
  const catTitle = cat.toUpperCase();

  const text =
    `${emoji} <b>${catTitle} RATE ADJUSTER</b> ${emoji}\n\n` +
    `Current Active Rate: <b>₹${current}/kg</b>\n\n` +
    `Tap <b>[+ / -]</b> steppers or <b>preset amounts</b> to update instantly:`;

  let presets = [];
  if (cat === "mutton") {
    presets = [800, 850, 900, 950];
  } else if (cat === "chicken") {
    presets = [240, 260, 280, 300];
  } else {
    presets = [380, 400, 420, 440];
  }

  const stepDelta = cat === "mutton" ? 50 : 20;

  const keyboard = [
    [
      { text: `-${stepDelta}`, callback_data: `adjust:${cat}:-${stepDelta}` },
      { text: `-10`, callback_data: `adjust:${cat}:-10` },
      { text: `+10`, callback_data: `adjust:${cat}:10` },
      { text: `+${stepDelta}`, callback_data: `adjust:${cat}:${stepDelta}` }
    ],
    [
      { text: `₹${presets[0]}`, callback_data: `set:${cat}:${presets[0]}` },
      { text: `₹${presets[1]}`, callback_data: `set:${cat}:${presets[1]}` },
      { text: `₹${presets[2]}`, callback_data: `set:${cat}:${presets[2]}` },
      { text: `₹${presets[3]}`, callback_data: `set:${cat}:${presets[3]}` }
    ],
    [
      { text: "✏️ Type Custom Price", callback_data: `custom:${cat}` },
      { text: "◀ Back to Dashboard", callback_data: "menu:main" }
    ]
  ];

  editTelegramMessage(chatId, messageId, text, keyboard);
}

function renderFullCatalog(chatId, messageId) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_PRICING);
  const data = sheet.getDataRange().getValues().slice(1);

  let mutton = [];
  let chicken = [];
  let beef = [];

  data.forEach(r => {
    const id = r[0];
    const cat = String(r[1]).toLowerCase();
    const name = r[2];
    const p = Math.round(Number(r[3]));
    const line = `• <code>${id}</code> ${escapeHtml(name)}: <b>₹${p}</b>`;
    if (cat === "mutton") mutton.push(line);
    else if (cat === "chicken") chicken.push(line);
    else if (cat === "beef") beef.push(line);
  });

  const text =
    `📋 <b>FULL DAILY MEAT CATALOG (₹/kg)</b>\n\n` +
    `🐐 <b>MUTTON CUTS:</b>\n` + mutton.join("\n") + `\n\n` +
    `🍗 <b>CHICKEN CUTS:</b>\n` + chicken.join("\n") + `\n\n` +
    `🥩 <b>BEEF CUTS:</b>\n` + beef.join("\n") + `\n\n` +
    `<i>To change an individual cut, type:</i> <code>m1 890</code>`;

  const keyboard = [
    [{ text: "◀ Back to Dashboard", callback_data: "menu:main" }]
  ];

  editTelegramMessage(chatId, messageId, text, keyboard);
}

function renderOrdersView(chatId, messageId) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ORDERS);
  const rows = sheet ? sheet.getDataRange().getValues().slice(1) : [];

  let rev = 0;
  rows.forEach(r => rev += Number(r[6]) || 0);

  const text =
    `📦 <b>TODAY'S ORDERS & REVENUE</b>\n\n` +
    `• Total Orders: <b>${rows.length}</b>\n` +
    `• Total Revenue: <b>₹${Math.round(rev)}</b>\n\n` +
    `<i>Customer details and addresses are stored in the <b>Daily_Orders</b> sheet.</i>`;

  const keyboard = [
    [{ text: "🔄 Refresh", callback_data: "menu:orders" }],
    [{ text: "◀ Back to Dashboard", callback_data: "menu:main" }]
  ];

  editTelegramMessage(chatId, messageId, text, keyboard);
}

// =============================================================================
// DATABASE HELPERS
// =============================================================================

function getCategoryAverages() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_PRICING);
  if (!sheet) {
    setupDatabaseSheets();
    sheet = ss.getSheetByName(SHEET_PRICING);
  }

  const data = sheet.getDataRange().getValues().slice(1);
  const cats = { mutton: 0, chicken: 0, beef: 0 };
  const counts = { mutton: 0, chicken: 0, beef: 0 };

  data.forEach(r => {
    const cat = String(r[1]).toLowerCase().trim();
    const p = Number(r[3]) || 0;
    if (cats[cat] !== undefined) {
      cats[cat] += p;
      counts[cat]++;
    }
  });

  return {
    mutton: counts.mutton > 0 ? Math.round(cats.mutton / counts.mutton) : 820,
    chicken: counts.chicken > 0 ? Math.round(cats.chicken / counts.chicken) : 280,
    beef: counts.beef > 0 ? Math.round(cats.beef / counts.beef) : 420
  };
}

function getCategoryAverage(cat) {
  return getCategoryAverages()[cat.toLowerCase()] || 500;
}

function updateCategoryPrice(cat, newPrice, user) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const priceSheet = ss.getSheetByName(SHEET_PRICING);
  const recordSheet = ss.getSheetByName(SHEET_RECORDS);

  const data = priceSheet.getDataRange().getValues();
  let oldPrice = 0;
  let count = 0;
  const nowIso = new Date().toISOString();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][1]).toLowerCase().trim() === cat.toLowerCase()) {
      if (oldPrice === 0) oldPrice = Number(data[i][3]);
      priceSheet.getRange(i + 1, 4).setValue(newPrice);
      priceSheet.getRange(i + 1, 5).setValue(nowIso);
      priceSheet.getRange(i + 1, 6).setValue("Telegram @" + user);
      count++;
    }
  }

  const diff = Math.round(newPrice - oldPrice);
  recordSheet.appendRow([
    nowIso,
    cat.toUpperCase(),
    cat.toUpperCase() + " (All Cuts)",
    oldPrice,
    newPrice,
    diff,
    user,
    `Updated via Telegram Buttons (${count} cuts)`
  ]);
}

function updateCutPrice(id, newPrice, user) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const priceSheet = ss.getSheetByName(SHEET_PRICING);
  const recordSheet = ss.getSheetByName(SHEET_RECORDS);

  const data = priceSheet.getDataRange().getValues();
  let oldPrice = 0;
  let cutName = "";
  const nowIso = new Date().toISOString();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).toLowerCase().trim() === id.toLowerCase()) {
      oldPrice = Number(data[i][3]);
      cutName = String(data[i][2]);
      priceSheet.getRange(i + 1, 4).setValue(newPrice);
      priceSheet.getRange(i + 1, 5).setValue(nowIso);
      priceSheet.getRange(i + 1, 6).setValue("Telegram @" + user);
      break;
    }
  }

  const diff = Math.round(newPrice - oldPrice);
  recordSheet.appendRow([
    nowIso,
    id.toUpperCase(),
    cutName,
    oldPrice,
    newPrice,
    diff,
    user,
    `Specific cut updated via Telegram`
  ]);
}

// =============================================================================
// TELEGRAM API CLIENT
// =============================================================================

function sendTelegramMessage(chatId, htmlText, inlineKeyboard) {
  const payload = {
    chat_id: chatId,
    text: htmlText,
    parse_mode: "HTML"
  };
  if (inlineKeyboard) payload.reply_markup = { inline_keyboard: inlineKeyboard };

  callTelegramApi("sendMessage", payload);
}

function editTelegramMessage(chatId, messageId, htmlText, inlineKeyboard) {
  const payload = {
    chat_id: chatId,
    message_id: messageId,
    text: htmlText,
    parse_mode: "HTML"
  };
  if (inlineKeyboard) payload.reply_markup = { inline_keyboard: inlineKeyboard };

  callTelegramApi("editMessageText", payload);
}

function answerCallbackQuery(queryId, toastText) {
  const payload = {
    callback_query_id: queryId
  };
  if (toastText) payload.text = toastText;

  callTelegramApi("answerCallbackQuery", payload);
}

function callTelegramApi(method, payload) {
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}`;
  const options = {
    method: "post",
    contentType: "application/json",
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };
  try {
    UrlFetchApp.fetch(url, options);
  } catch (e) {
    Logger.log(`callTelegramApi ${method} error: ` + e);
  }
}

function escapeHtml(text) {
  if (!text) return "";
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}
