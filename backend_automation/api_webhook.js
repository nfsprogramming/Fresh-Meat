// Vercel Serverless Function: Telegram Webhook & Google Sheets Price Controller
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || "PASTE_YOUR_TELEGRAM_BOT_TOKEN_HERE";
const APPS_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbyso5g4C2erayybtWs1mM8BIk-KgcYCbYGG0yWgEMOcaFkutQppW7hyohrlEe2XOzVO/exec";

// In-memory / baseline rates
const liveRates = {
  mutton: 900,
  chicken: 280,
  beef: 420
};

// Cut Metadata
const CUT_METADATA = {
  m1: { name: "Mutton Curry Cut (Bone-in)", short: "Curry Cut", cat: "mutton", defaultPrice: 900 },
  m2: { name: "Mutton Biryani Special Cut", short: "Biryani Cut", cat: "mutton", defaultPrice: 960 },
  m3: { name: "Prime Mutton Rib Chops", short: "Rib Chops", cat: "mutton", defaultPrice: 1040 },
  m4: { name: "Boneless Tender Mutton", short: "Boneless", cat: "mutton", defaultPrice: 1060 },
  m5: { name: "Kashmiri Rogan Josh Shank", short: "Rogan Josh", cat: "mutton", defaultPrice: 1000 },
  m6: { name: "Mutton Paya (Cleaned)", short: "Paya Cleaned", cat: "mutton", defaultPrice: 585 },

  c1: { name: "Tender Chicken Curry Cut", short: "Curry Cut", cat: "chicken", defaultPrice: 280 },
  c2: { name: "Boneless Chicken Breast", short: "Boneless Breast", cat: "chicken", defaultPrice: 360 },
  c3: { name: "Tandoori Chicken Drumsticks", short: "Drumsticks", cat: "chicken", defaultPrice: 330 },
  c4: { name: "Chicken Biryani Cut", short: "Biryani Cut", cat: "chicken", defaultPrice: 300 },
  c5: { name: "Fresh Chicken Keema", short: "Chicken Keema", cat: "chicken", defaultPrice: 380 },
  c6: { name: "Chicken Lollipop Wings", short: "Lollipop Wings", cat: "chicken", defaultPrice: 310 },

  b1: { name: "Prime Beef Steak Cut", short: "Steak Cut", cat: "beef", defaultPrice: 420 },
  b2: { name: "Beef Curry Cut (Bone-in)", short: "Curry Cut", cat: "beef", defaultPrice: 380 },
  b3: { name: "Boneless Beef Tenderloin", short: "Tenderloin", cat: "beef", defaultPrice: 460 },
  b4: { name: "Marinated Beef Nihari", short: "Beef Nihari", cat: "beef", defaultPrice: 440 },
  b5: { name: "Beef Ribs Cut", short: "Beef Ribs", cat: "beef", defaultPrice: 400 },
  b6: { name: "Ground Beef Keema", short: "Beef Keema", cat: "beef", defaultPrice: 390 }
};

const liveCutPrices = {};
for (const [id, meta] of Object.entries(CUT_METADATA)) {
  liveCutPrices[id] = meta.defaultPrice;
}

let lastSyncTime = 0;
async function ensureSynced() {
  const now = Date.now();
  if (now - lastSyncTime > 30000) { // Sync every 30 seconds
    lastSyncTime = now;
    try {
      const response = await fetch(APPS_SCRIPT_URL);
      const data = await response.json();
      if (data.categories) {
        if (data.categories.mutton) liveRates.mutton = data.categories.mutton;
        if (data.categories.chicken) liveRates.chicken = data.categories.chicken;
        if (data.categories.beef) liveRates.beef = data.categories.beef;
      }
      if (data.prices) {
        for (const [k, v] of Object.entries(data.prices)) {
          if (liveCutPrices[k] !== undefined && Number(v) > 0) {
            liveCutPrices[k] = Number(v);
          }
        }
      }
    } catch (e) {
      console.error("Sync error:", e);
    }
  }
}

export default async function handler(req, res) {
  if (req.method === 'GET') {
    try {
      const response = await fetch(APPS_SCRIPT_URL);
      const data = await response.json();
      return res.status(200).json(data);
    } catch (e) {
      return res.status(200).json({ status: "success", categories: liveRates, prices: liveCutPrices });
    }
  }

  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const update = req.body;
  if (!update) {
    return res.status(200).send('OK');
  }

  try {
    await ensureSynced();

    // -------------------------------------------------------------------------
    // A. INLINE BUTTON CLICKS (Callback Queries)
    // -------------------------------------------------------------------------
    if (update.callback_query) {
      const q = update.callback_query;
      const queryId = q.id;
      const data = q.data || "";
      const chatId = q.message.chat.id;
      const messageId = q.message.message_id;
      const user = q.from.first_name || "Manager";

      await handleCallback(chatId, messageId, queryId, data, user);
      return res.status(200).send('OK');
    }

    // -------------------------------------------------------------------------
    // B. TEXT MESSAGES
    // -------------------------------------------------------------------------
    if (update.message && update.message.text) {
      const chatId = update.message.chat.id;
      const text = update.message.text.trim();
      const lower = text.toLowerCase().replace(/@[a-zA-Z0-9_]+/g, "");
      const user = update.message.from.first_name || "Manager";

      console.log(`Received message from ${user} (${chatId}): ${text}`);

      // 1. Natural price typing: e.g. "mutton 850", "chicken 280", "beef 420", or "m1 890"
      const match = lower.match(/^(?:\/price\s+|\/set\s+)?(mutton|chicken|beef|[mcb][1-6])\s+(\d+)$/i);
      if (match) {
        const target = match[1].toLowerCase();
        const newPrice = parseInt(match[2], 10);

        if (["mutton", "chicken", "beef"].includes(target)) {
          liveRates[target] = newPrice;
        } else if (liveCutPrices[target] !== undefined) {
          liveCutPrices[target] = newPrice;
        }

        await updatePriceOnSheets(target, newPrice, user);
        await sendTelegramMessage(chatId, `✅ <b>${target.toUpperCase()}</b> updated to <b>₹${newPrice}/kg</b>!`);
        await sendDashboard(chatId);
        return res.status(200).send('OK');
      }

      // 2. Default: Send the Interactive Buttons Dashboard
      await sendDashboard(chatId);
      return res.status(200).send('OK');
    }
  } catch (err) {
    console.error("Webhook processing error:", err);
  }

  return res.status(200).send('OK');
}

// -----------------------------------------------------------------------------
// INLINE BUTTONS DISPATCHER
// -----------------------------------------------------------------------------
async function handleCallback(chatId, messageId, queryId, data, user) {
  const parts = data.split(":");
  const action = parts[0];

  if (action === "menu") {
    const page = parts[1];
    if (page === "main") {
      await answerCallback(queryId);
      await editDashboard(chatId, messageId);
    } else if (page === "mutton" || page === "chicken" || page === "beef") {
      await answerCallback(queryId);
      await renderAdjuster(chatId, messageId, page);
    } else if (page === "catalog") {
      await answerCallback(queryId);
      await renderCatalog(chatId, messageId);
    } else if (page === "orders") {
      await answerCallback(queryId);
      await renderOrders(chatId, messageId);
    }
  } 
  else if (action === "adjust") {
    const cat = parts[1];
    const delta = parseInt(parts[2], 10);
    const current = liveRates[cat] || 500;
    const newPrice = Math.max(50, current + delta);

    liveRates[cat] = newPrice;
    updatePriceOnSheets(cat, newPrice, user).catch(() => {});
    await answerCallback(queryId, `✅ ${cat.toUpperCase()} set to ₹${newPrice}/kg!`);
    await renderAdjuster(chatId, messageId, cat);
  } 
  else if (action === "set") {
    const cat = parts[1];
    const newPrice = parseInt(parts[2], 10);

    liveRates[cat] = newPrice;
    updatePriceOnSheets(cat, newPrice, user).catch(() => {});
    await answerCallback(queryId, `✅ ${cat.toUpperCase()} set to ₹${newPrice}/kg!`);
    await renderAdjuster(chatId, messageId, cat);
  }
  else if (action === "cuts") {
    const cat = parts[1] || "mutton";
    await answerCallback(queryId);
    await renderCutPicker(chatId, messageId, cat);
  }
  else if (action === "cut_adj") {
    const cutId = parts[1];
    await answerCallback(queryId);
    await renderCutAdjuster(chatId, messageId, cutId);
  }
  else if (action === "cut_step") {
    const cutId = parts[1];
    const delta = parseInt(parts[2], 10);
    const current = liveCutPrices[cutId] || (CUT_METADATA[cutId] ? CUT_METADATA[cutId].defaultPrice : 500);
    const newPrice = Math.max(50, current + delta);

    liveCutPrices[cutId] = newPrice;
    updatePriceOnSheets(cutId, newPrice, user).catch(() => {});
    await answerCallback(queryId, `✅ ${cutId.toUpperCase()} set to ₹${newPrice}/kg!`);
    await renderCutAdjuster(chatId, messageId, cutId);
  }
  else if (action === "cut_set") {
    const cutId = parts[1];
    const newPrice = parseInt(parts[2], 10);

    liveCutPrices[cutId] = newPrice;
    updatePriceOnSheets(cutId, newPrice, user).catch(() => {});
    await answerCallback(queryId, `✅ ${cutId.toUpperCase()} set to ₹${newPrice}/kg!`);
    await renderCutAdjuster(chatId, messageId, cutId);
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD & SCREENS
// -----------------------------------------------------------------------------
async function sendDashboard(chatId) {
  const { text, keyboard } = buildDashboard();
  await sendTelegramMessage(chatId, text, keyboard);
}

async function editDashboard(chatId, messageId) {
  const { text, keyboard } = buildDashboard();
  await editTelegramMessage(chatId, messageId, text, keyboard);
}

function buildDashboard() {
  const now = new Date();
  const timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });

  const text =
    `🥩 <b>FRESH MEAT MARKET — PRICE DASHBOARD</b> 🥩\n\n` +
    `Today's Live Base Rates:\n` +
    `🐐 <b>Mutton:</b>  <b>₹${liveRates.mutton}/kg</b>\n` +
    `🍗 <b>Chicken:</b> <b>₹${liveRates.chicken}/kg</b>\n` +
    `🥩 <b>Beef:</b>    <b>₹${liveRates.beef}/kg</b>\n\n` +
    `🕒 <i>Updated: Today at ${timeStr}</i>\n` +
    `🟢 <i>Google Sheets & Mobile App are synced live.</i>\n\n` +
    `👇 <b>Tap any button below to adjust prices:</b>`;

  const keyboard = [
    [
      { text: `🐐 Mutton (₹${liveRates.mutton})`, callback_data: "menu:mutton" },
      { text: `🍗 Chicken (₹${liveRates.chicken})`, callback_data: "menu:chicken" }
    ],
    [
      { text: `🥩 Beef (₹${liveRates.beef})`, callback_data: "menu:beef" },
      { text: "🔪 Edit Specific Cuts", callback_data: "cuts:mutton" }
    ],
    [
      { text: "📋 Full Catalog (18 Cuts)", callback_data: "menu:catalog" },
      { text: "📦 Today's Orders", callback_data: "menu:orders" }
    ],
    [
      { text: "🔄 Refresh Live", callback_data: "menu:main" }
    ]
  ];

  return { text, keyboard };
}

async function renderAdjuster(chatId, messageId, cat) {
  const current = liveRates[cat] || 500;
  const emoji = cat === "mutton" ? "🐐" : cat === "chicken" ? "🍗" : "🥩";
  const catTitle = cat.toUpperCase();

  const text =
    `${emoji} <b>${catTitle} BASE RATE ADJUSTER</b> ${emoji}\n\n` +
    `Current Active Rate: <b>₹${current}/kg</b>\n\n` +
    `Tap <b>[+ / -]</b> steppers or <b>preset amounts</b> to update base price,\n` +
    `or tap below to adjust individual ${catTitle} cuts:`;

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
      { text: `🔪 Edit Individual ${catTitle} Cuts`, callback_data: `cuts:${cat}` }
    ],
    [
      { text: "◀ Back to Dashboard", callback_data: "menu:main" }
    ]
  ];

  await editTelegramMessage(chatId, messageId, text, keyboard);
}

// -----------------------------------------------------------------------------
// INDIVIDUAL CUTS SELECTION & ADJUSTER
// -----------------------------------------------------------------------------
async function renderCutPicker(chatId, messageId, cat) {
  const emoji = cat === "mutton" ? "🐐" : cat === "chicken" ? "🍗" : "🥩";
  const catTitle = cat.toUpperCase();
  const text =
    `${emoji} <b>SELECT ${catTitle} CUT TO ADJUST</b> ${emoji}\n\n` +
    `Tap any individual cut button below to adjust its price with steppers:`;

  const cutIds = Object.keys(CUT_METADATA).filter(id => CUT_METADATA[id].cat === cat);
  const keyboard = [];

  // 2 cuts per row
  for (let i = 0; i < cutIds.length; i += 2) {
    const row = [];
    const id1 = cutIds[i];
    const p1 = liveCutPrices[id1] || CUT_METADATA[id1].defaultPrice;
    const m1 = CUT_METADATA[id1];
    row.push({ text: `${id1.toUpperCase()}: ${m1.short} (₹${p1})`, callback_data: `cut_adj:${id1}` });

    if (i + 1 < cutIds.length) {
      const id2 = cutIds[i + 1];
      const p2 = liveCutPrices[id2] || CUT_METADATA[id2].defaultPrice;
      const m2 = CUT_METADATA[id2];
      row.push({ text: `${id2.toUpperCase()}: ${m2.short} (₹${p2})`, callback_data: `cut_adj:${id2}` });
    }
    keyboard.push(row);
  }

  // Switch category tabs row
  const catTabs = [];
  if (cat !== "mutton") catTabs.push({ text: "🐐 Mutton", callback_data: "cuts:mutton" });
  if (cat !== "chicken") catTabs.push({ text: "🍗 Chicken", callback_data: "cuts:chicken" });
  if (cat !== "beef") catTabs.push({ text: "🥩 Beef", callback_data: "cuts:beef" });
  keyboard.push(catTabs);

  keyboard.push([
    { text: "📋 View Full Catalog", callback_data: "menu:catalog" },
    { text: "🏠 Dashboard", callback_data: "menu:main" }
  ]);

  await editTelegramMessage(chatId, messageId, text, keyboard);
}

async function renderCutAdjuster(chatId, messageId, cutId) {
  const meta = CUT_METADATA[cutId] || { name: cutId, short: cutId, cat: "mutton", defaultPrice: 500 };
  const current = liveCutPrices[cutId] || meta.defaultPrice;
  const emoji = meta.cat === "mutton" ? "🐐" : meta.cat === "chicken" ? "🍗" : "🥩";

  const text =
    `🔪 <b>${cutId.toUpperCase()} RATE ADJUSTER</b>\n` +
    `<b>${meta.name}</b>\n\n` +
    `Category: ${emoji} <b>${meta.cat.toUpperCase()}</b>\n` +
    `Current Active Rate: <b>₹${current}/kg</b>\n\n` +
    `👇 <b>Tap [+ / -] steppers or quick presets to update instantly:</b>`;

  const delta = meta.cat === "mutton" ? 50 : 20;

  // Generate 4 dynamic presets around current price
  const baseRound = Math.round(current / 50) * 50;
  const presets = [
    Math.max(50, baseRound - 100),
    Math.max(50, baseRound - 50),
    baseRound,
    baseRound + 50
  ];

  const keyboard = [
    [
      { text: `-${delta}`, callback_data: `cut_step:${cutId}:-${delta}` },
      { text: `-10`, callback_data: `cut_step:${cutId}:-10` },
      { text: `+10`, callback_data: `cut_step:${cutId}:10` },
      { text: `+${delta}`, callback_data: `cut_step:${cutId}:${delta}` }
    ],
    [
      { text: `₹${presets[0]}`, callback_data: `cut_set:${cutId}:${presets[0]}` },
      { text: `₹${presets[1]}`, callback_data: `cut_set:${cutId}:${presets[1]}` },
      { text: `₹${presets[2]}`, callback_data: `cut_set:${cutId}:${presets[2]}` },
      { text: `₹${presets[3]}`, callback_data: `cut_set:${cutId}:${presets[3]}` }
    ],
    [
      { text: `◀ Back to ${meta.cat.toUpperCase()} Cuts`, callback_data: `cuts:${meta.cat}` },
      { text: "🏠 Dashboard", callback_data: "menu:main" }
    ]
  ];

  await editTelegramMessage(chatId, messageId, text, keyboard);
}

async function renderCatalog(chatId, messageId) {
  const text =
    `📋 <b>DAILY MEAT CATALOG (₹/kg)</b>\n\n` +
    `🐐 <b>MUTTON CUTS:</b>\n` +
    `• <code>m1</code> Mutton Curry Cut (Bone-in): <b>₹${liveCutPrices.m1}</b>\n` +
    `• <code>m2</code> Mutton Biryani Special Cut: <b>₹${liveCutPrices.m2}</b>\n` +
    `• <code>m3</code> Prime Mutton Rib Chops: <b>₹${liveCutPrices.m3}</b>\n` +
    `• <code>m4</code> Boneless Tender Mutton: <b>₹${liveCutPrices.m4}</b>\n` +
    `• <code>m5</code> Kashmiri Rogan Josh Shank: <b>₹${liveCutPrices.m5}</b>\n` +
    `• <code>m6</code> Mutton Paya (Cleaned): <b>₹${liveCutPrices.m6}</b>\n\n` +
    `🍗 <b>CHICKEN CUTS:</b>\n` +
    `• <code>c1</code> Tender Chicken Curry Cut: <b>₹${liveCutPrices.c1}</b>\n` +
    `• <code>c2</code> Boneless Chicken Breast: <b>₹${liveCutPrices.c2}</b>\n` +
    `• <code>c3</code> Tandoori Chicken Drumsticks: <b>₹${liveCutPrices.c3}</b>\n` +
    `• <code>c4</code> Chicken Biryani Cut: <b>₹${liveCutPrices.c4}</b>\n` +
    `• <code>c5</code> Fresh Chicken Keema: <b>₹${liveCutPrices.c5}</b>\n` +
    `• <code>c6</code> Chicken Lollipop Wings: <b>₹${liveCutPrices.c6}</b>\n\n` +
    `🥩 <b>BEEF CUTS:</b>\n` +
    `• <code>b1</code> Prime Beef Steak Cut: <b>₹${liveCutPrices.b1}</b>\n` +
    `• <code>b2</code> Beef Curry Cut (Bone-in): <b>₹${liveCutPrices.b2}</b>\n` +
    `• <code>b3</code> Boneless Beef Tenderloin: <b>₹${liveCutPrices.b3}</b>\n` +
    `• <code>b4</code> Marinated Beef Nihari: <b>₹${liveCutPrices.b4}</b>\n` +
    `• <code>b5</code> Beef Ribs Cut: <b>₹${liveCutPrices.b5}</b>\n` +
    `• <code>b6</code> Ground Beef Keema: <b>₹${liveCutPrices.b6}</b>\n\n` +
    `<i>Tap any category below to adjust individual cuts with buttons:</i>`;

  const keyboard = [
    [
      { text: "🐐 Edit Mutton Cuts", callback_data: "cuts:mutton" },
      { text: "🍗 Edit Chicken Cuts", callback_data: "cuts:chicken" }
    ],
    [
      { text: "🥩 Edit Beef Cuts", callback_data: "cuts:beef" },
      { text: "◀ Back to Dashboard", callback_data: "menu:main" }
    ]
  ];
  await editTelegramMessage(chatId, messageId, text, keyboard);
}

async function renderOrders(chatId, messageId) {
  const text =
    `📦 <b>TODAY'S ORDERS & REVENUE</b>\n\n` +
    `• Total Orders Placed: <b>Live tracking active</b>\n` +
    `• Synchronization: <b>Real-time connected</b>\n\n` +
    `<i>All individual customer checkout records are safely stored in your <b>Daily_Orders</b> sheet!</i>`;

  const keyboard = [
    [{ text: "🔄 Refresh", callback_data: "menu:orders" }],
    [{ text: "◀ Back to Dashboard", callback_data: "menu:main" }]
  ];
  await editTelegramMessage(chatId, messageId, text, keyboard);
}

// -----------------------------------------------------------------------------
// GOOGLE SHEETS & TELEGRAM HTTP HELPERS
// -----------------------------------------------------------------------------
async function updatePriceOnSheets(target, price, user) {
  try {
    await fetch(`${APPS_SCRIPT_URL}?action=update&target=${encodeURIComponent(target)}&price=${price}&user=${encodeURIComponent(user)}`);
  } catch (e) {
    console.error("updatePriceOnSheets error:", e);
  }
}

async function sendTelegramMessage(chatId, htmlText, inlineKeyboard) {
  const payload = { chat_id: chatId, text: htmlText, parse_mode: "HTML" };
  if (inlineKeyboard) payload.reply_markup = { inline_keyboard: inlineKeyboard };
  await callTelegram("sendMessage", payload);
}

async function editTelegramMessage(chatId, messageId, htmlText, inlineKeyboard) {
  const payload = { chat_id: chatId, message_id: messageId, text: htmlText, parse_mode: "HTML" };
  if (inlineKeyboard) payload.reply_markup = { inline_keyboard: inlineKeyboard };
  await callTelegram("editMessageText", payload);
}

async function answerCallback(queryId, toastText) {
  const payload = { callback_query_id: queryId };
  if (toastText) payload.text = toastText;
  await callTelegram("answerCallbackQuery", payload);
}

async function callTelegram(method, payload) {
  try {
    const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    console.log(`Telegram ${method} result:`, data);
  } catch (e) {
    console.error(`Telegram API ${method} error:`, e);
  }
}
