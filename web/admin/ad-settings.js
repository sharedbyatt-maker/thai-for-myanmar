const formats = [
  ["banner", "Banner", "သင်ယူနဲ့ ကိုယ်ပိုင် tab အပေါ်ပိုင်း", "2759288917"],
  ["native", "Native", "နေ့စဉ်စကား၊ ပြန်လေ့ကျင့်၊ စိန်ခေါ်မှုနဲ့ League ဇယားထဲက ကြော်ငြာကတ်", "7523375488"],
  ["interstitial", "Interstitial", "သင်ခန်းစာပြီး ရလဒ်မပြမီ", "8474650024"],
  ["rewarded", "Rewarded", "အပိုလေ့ကျင့်ခန်းအတွက် ကိုယ်တိုင် ရွေးကြည့်ချိန်", "2567717227"],
  ["rewardedInterstitial", "Rewarded interstitial", "သင်ခန်းစာရလဒ်မပြမီ အပိုလေ့ကျင့်ခန်း ကမ်းလှမ်းမှု", "1801430466"],
  ["appOpen", "App open", "နောက်ခံကနေ ပြန်ဖွင့်ပြီး သင်ယူ သို့မဟုတ် စိန်ခေါ်မှု tab ပြန်ဝင်ချိန်", "4897212146"],
];

const numericFields = [
  ["ads-cooldown", "cooldownMinutes", 8, 8, 120],
  ["ads-daily-limit", "dailyLimit", 3, 1, 3],
  ["ads-lesson-interval", "lessonInterval", 2, 2, 30],
];
const unitIdPattern = /^ca-app-pub-[0-9]{16}\/[0-9]{10}$/;
const $ = id => document.getElementById(id);
const toggleId = key => `ads-${key}-enabled`;
const unitId = key => `ads-${key}-id`;
export const adsFields = [
  "ads-master", "ads-delivery",
  ...numericFields.map(([id]) => id),
  ...formats.flatMap(([key]) => [toggleId(key), unitId(key)]),
];

export function setupAdFields() {
  $("ads-formats").replaceChildren(...formats.map(([key, title, placement]) => {
    const card = document.createElement("div");
    card.className = "ad-format";
    const toggle = document.createElement("label");
    toggle.className = "setting-row";
    const text = document.createElement("span");
    const heading = document.createElement("strong");
    heading.textContent = title;
    const description = document.createElement("small");
    description.textContent = placement;
    text.append(heading, description);
    const enabled = document.createElement("input");
    enabled.id = toggleId(key);
    enabled.type = "checkbox";
    enabled.className = "switch";
    enabled.setAttribute("role", "switch");
    toggle.append(text, enabled);
    const label = document.createElement("label");
    label.textContent = "Ad Unit ID";
    const unit = document.createElement("input");
    unit.id = unitId(key);
    unit.type = "text";
    unit.maxLength = 42;
    unit.autocomplete = "off";
    unit.spellcheck = false;
    unit.placeholder = "ca-app-pub-…/…";
    label.append(unit);
    card.append(toggle, label);
    return card;
  }));
}

function adsConfig(settings) {
  return settings.androidAds ?? {
    enabled: true,
    delivery: "test",
    formats: Object.fromEntries(formats.map(([key]) => [key, { enabled: true }])),
  };
}

export function loadAdFields(settings) {
  const config = adsConfig(settings);
  $("ads-master").checked = config.enabled === true;
  $("ads-delivery").value = config.delivery === "live" ? "live" : "test";
  for (const [id, name, fallback, min, max] of numericFields) {
    const value = config[name];
    $(id).value = Number.isInteger(value) ? Math.min(max, Math.max(min, value)) : fallback;
  }
  for (const [key, , , suffix] of formats) {
    const entry = config.formats?.[key];
    $(toggleId(key)).checked = entry?.enabled === true;
    $(unitId(key)).value = entry?.unitId ?? `ca-app-pub-7351657203026829/${suffix}`;
  }
}

export function renderAdPreview() {
  const testing = $("ads-delivery").value === "test";
  $("ads-delivery-help").textContent = testing
    ? "ဒီ feature ပါတဲ့ Android app သုံးနေတဲ့ ဖုန်းတိုင်းမှာ Google Test ads ပြပါမယ်။"
    : "Live ads ပြဖို့ Master switch နဲ့ သက်ဆိုင်ရာ format တွေကို ဖွင့်ပြီး Publish လုပ်ပါ။";
  const showing = $("ads-master").checked && $(toggleId("banner")).checked;
  $("ads-preview-slot").hidden = !showing;
  $("ads-preview-state").textContent = showing ? "ဖွင့်ထား" : "ပိတ်ထား";
  $("ads-preview-state").dataset.enabled = String(showing);
}

export function adCount(settings) {
  const config = adsConfig(settings);
  if (config.enabled !== true) return 0;
  if (config.delivery !== "live" && config.delivery !== "test") {
    return 0;
  }
  return formats.filter(([key]) => {
    const entry = config.formats?.[key];
    return entry?.enabled === true && (config.delivery === "test" || unitIdPattern.test(entry.unitId));
  }).length;
}

export function adStatus(settings) {
  const config = adsConfig(settings);
  const count = adCount(settings);
  const mode = config.delivery === "test" ? "Test" : "Live";
  return count ? `${mode} · ${count}/6 ဖွင့်ထား` : "0/6 ဖွင့်ထား";
}

export function collectAdFields() {
  const delivery = $("ads-delivery").value === "live" ? "live" : "test";
  const config = { enabled: $("ads-master").checked, delivery, formats: {} };
  for (const [id, key, , min, max] of numericFields) {
    const value = Number($(id).value);
    if (!Number.isInteger(value) || value < min || value > max) {
      throw new Error(`ကြော်ငြာကန့်သတ်ချက်ကို ${min} မှ ${max} အတွင်း ထည့်ပါ။`);
    }
    config[key] = value;
  }
  for (const [key, name] of formats) {
    const id = $(unitId(key)).value.trim();
    const enabled = $(toggleId(key)).checked;
    if ((id || (delivery === "live" && enabled)) && !unitIdPattern.test(id)) {
      throw new Error(`${name} အတွက် မှန်ကန်တဲ့ Ad Unit ID ထည့်ပါ။`);
    }
    config.formats[key] = { enabled, unitId: id };
  }
  return config;
}

export function adChangeLabels(before, after) {
  const old = adsConfig(before), next = adsConfig(after);
  const labels = [];
  if ((old.delivery ?? "test") !== (next.delivery ?? "test")) {
    labels.push(next.delivery === "live" ? "Production Live ads mode သို့ပြောင်းမယ်" : "Google Test ads mode သို့ပြောင်းမယ်");
  }
  if (old.enabled !== next.enabled) labels.push(next.enabled ? "Android ကြော်ငြာအားလုံး ဖွင့်မယ်" : "Android ကြော်ငြာအားလုံး ပိတ်မယ်");
  for (const [key, name] of formats) {
    const first = old.formats?.[key];
    const second = next.formats?.[key];
    if (Boolean(first?.enabled) !== Boolean(second?.enabled)) {
      labels.push(`${name} — ${second.enabled ? "ဖွင့်မယ်" : "ပိတ်မယ်"}`);
    }
    if ((first?.unitId ?? "") !== (second?.unitId ?? "")) labels.push(`${name} — Ad Unit ID ပြောင်းမယ်`);
  }
  if (numericFields.some(([, key, fallback]) => (old[key] ?? fallback) !== (next[key] ?? fallback))) {
    labels.push("Full-screen ကြော်ငြာ ကန့်သတ်ချက် ပြောင်းမယ်");
  }
  return labels;
}
