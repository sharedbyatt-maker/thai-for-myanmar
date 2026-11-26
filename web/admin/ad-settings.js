const formats = [
  ["banner", "Banner", "Profile အောက်ခြေ", "2759288917"],
  ["native", "Native", "Review စာရင်းထဲက ကြော်ငြာကတ်", "7523375488"],
  ["interstitial", "Interstitial", "သင်ခန်းစာပြီး နောက်သင်ခန်းစာ ကူးချိန်", "8474650024"],
  ["rewarded", "Rewarded", "အပိုလေ့ကျင့်ခန်းအတွက် ကိုယ်တိုင် ရွေးကြည့်ချိန်", "2567717227"],
  ["rewardedInterstitial", "Rewarded interstitial", "သင်ခန်းစာကူးချိန်မှာ အပိုလေ့ကျင့်ခန်း ကမ်းလှမ်းမှု", "1801430466"],
  ["appOpen", "App open", "နောက်ခံကနေ ပြန်ဖွင့်ပြီး သင်ယူ သို့မဟုတ် စိန်ခေါ်မှု tab ပြန်ဝင်ချိန်", "4897212146"],
];

const numericFields = [
  ["ads-cooldown", "cooldownMinutes", 8, 5, 120],
  ["ads-daily-limit", "dailyLimit", 3, 1, 5],
  ["ads-lesson-interval", "lessonInterval", 4, 4, 30],
];
const unitIdPattern = /^ca-app-pub-[0-9]{16}\/[0-9]{10}$/;
const $ = id => document.getElementById(id);
const toggleId = key => `ads-${key}-enabled`;
const unitId = key => `ads-${key}-id`;
export const adsFields = [
  "ads-master",
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
    enabled: settings.androidBanner === true,
    formats: { banner: { enabled: settings.androidBanner === true } },
  };
}

export function loadAdFields(settings) {
  const config = adsConfig(settings);
  $("ads-master").checked = config.enabled === true;
  for (const [id, name, fallback] of numericFields) $(id).value = config[name] ?? fallback;
  for (const [key, , , suffix] of formats) {
    const entry = config.formats?.[key];
    $(toggleId(key)).checked = entry?.enabled === true;
    $(unitId(key)).value = entry?.unitId ?? `ca-app-pub-7351657203026829/${suffix}`;
  }
}

export function renderAdPreview() {
  const showing = $("ads-master").checked && $(toggleId("banner")).checked;
  $("ads-preview-slot").hidden = !showing;
  $("ads-preview-state").textContent = showing ? "ဖွင့်ထား" : "ပိတ်ထား";
  $("ads-preview-state").dataset.enabled = String(showing);
}

export function adCount(settings) {
  const config = adsConfig(settings);
  if (config.enabled !== true) return 0;
  return formats.filter(([key]) => {
    const entry = config.formats?.[key];
    return entry?.enabled === true &&
      (unitIdPattern.test(entry.unitId) || (!settings.androidAds && key === "banner"));
  }).length;
}

export function collectAdFields() {
  const config = { enabled: $("ads-master").checked, formats: {} };
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
    if ((id || enabled) && !unitIdPattern.test(id)) {
      throw new Error(`${name} အတွက် မှန်ကန်တဲ့ Ad Unit ID ထည့်ပါ။`);
    }
    config.formats[key] = { enabled, unitId: id };
  }
  return config;
}

export function adChangeLabels(before, after) {
  const old = adsConfig(before), next = adsConfig(after);
  const labels = [];
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
