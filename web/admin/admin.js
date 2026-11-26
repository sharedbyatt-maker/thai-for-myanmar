import { adChangeLabels, adCount, adStatus, adsFields, collectAdFields, loadAdFields, renderAdPreview, setupAdFields } from "./ad-settings.js";

const $ = (id) => document.getElementById(id);
const value = (id) => $(id).value.trim();
async function loadAsset(name) {
  const response = await fetch(`/assets/assets/data/${name}.json`);
  if (!response.ok) throw new Error("Admin assets unavailable");
  return response.json();
}

let config, course, romanizations;
try {
  [config, course, romanizations] = await Promise.all([
    loadAsset("league_config"), loadAsset("course_v2"), loadAsset("course_pronunciation"),
  ]);
  $("login-submit").disabled = false;
  $("owner-setup").disabled = false;
} catch {
  $("status").textContent = "Admin ဖွင့်မရသေးပါ။ ချိတ်ဆက်မှု စစ်ပြီး စာမျက်နှာကို ပြန်ဖွင့်ပါ။";
  throw new Error("Cannot initialize Admin");
}
const voices = ["male", "female"];
const exerciseLines = Object.fromEntries(voices.map(voice => {
  const ids = new Set();
  for (const [id, line] of Object.entries(course.lines)) {
    const parts = line.parts?.[voice] ?? [];
    if (parts.length) ids.add(id);
    for (const part of parts) ids.add(part);
  }
  return [voice, ids];
}));

let token, draft, published, settings, previewUrl;
let busy = false;
let selection = {};
let savedForm = {};
const pickerIds = ["unit", "lesson", "line", "voice"];
let bundledAudio;
function audioKey(id, voice, thai) {
  return JSON.stringify([id, voice, thai]);
}

async function showSavedAudio() {
  const id = value("line");
  const voice = value("voice");
  const line = course.lines[id];
  const custom = settings.lines?.[id]?.[voice];
  if (custom?.audio) {
    setAudioPreview(config.url + "/storage/v1/object/public/chang-thai-lesson-audio/" + custom.audio);
    return;
  }
  setAudioPreview(null);
  if (!line) return;
  bundledAudio ??= Promise.allSettled([loadAsset("thai_audio_manifest"), loadAsset("course_audio_manifest")])
    .then(manifests => new Map(manifests.flatMap(result => result.value?.entries ?? [])
      .map(entry => [audioKey(entry.phraseId, entry.form, entry.thai), entry.asset])));
  const matches = await bundledAudio;
  if (!settings || id !== value("line") || voice !== value("voice") || previewUrl) return;
  const thai = custom?.thai ?? line[voice];
  const source = line.sources?.[voice];
  const asset = matches.get(audioKey(id, voice, thai)) ?? matches.get(audioKey(source, voice, thai));
  if (asset) setAudioPreview("/assets/assets/" + asset);
}
const lessonFields = [
  "unit-title", "unit-goal", "unit-tips", "lesson-title", "thai-text", "my-text", "romanization",
];
setupAdFields();
const controlFields = [
  ...adsFields, "announcement-enabled", "announcement-title", "announcement-body",
  "announcement-expiry", "latest-code", "minimum-code", "update-message",
];

function snapshot(ids) {
  return Object.fromEntries(ids.map(id => {
    const element = $(id);
    return [id, element.type === "checkbox" ? element.checked : element.value];
  }));
}

function formChanged(ids) {
  return Object.entries(snapshot(ids)).some(([id, current]) => savedForm[id] !== current);
}

function lessonChanged() {
  return formChanged(lessonFields) || $("lesson-audio").files.length > 0;
}

function rememberLesson() {
  selection = snapshot(pickerIds);
  Object.assign(savedForm, snapshot(lessonFields));
}

function formDirty() {
  return lessonChanged() || formChanged(controlFields);
}

function editStatus() {
  const dirty = formDirty();
  $("edit-state").textContent = dirty ? "မသိမ်းရသေးတဲ့ ပြင်ဆင်ချက်ရှိပါတယ်" : "Draft ကို သိမ်းထားပါတယ်";
  $("discard-edits").disabled = !dirty;
}

function equalSettings(first, second) {
  if (Object.is(first, second)) return true;
  if (!first || !second || typeof first !== "object" || typeof second !== "object") return false;
  const keys = Object.keys(first);
  return keys.length === Object.keys(second).length
    && keys.every(key => Object.hasOwn(second, key) && equalSettings(first[key], second[key]));
}

function changeLabels(candidate) {
  const live = published.settings;
  const labels = [];
  labels.push(...adChangeLabels(live, candidate));
  const groups = [
    ["units", "ယူနစ်"], ["lessons", "သင်ခန်းစာ"], ["lines", "ထိုင်းစာကြောင်းနှင့် အသံ"],
  ];
  for (const [key, label] of groups) {
    const before = live[key] ?? {};
    const after = candidate[key] ?? {};
    const ids = new Set([...Object.keys(before), ...Object.keys(after)]);
    const count = [...ids].filter(id => !equalSettings(before[id], after[id])).length;
    if (count) labels.push(`${label} ${count} ခု ပြောင်းမယ်`);
  }
  if ((live.announcement?.enabled || candidate.announcement?.enabled)
      && !equalSettings(live.announcement, candidate.announcement)) {
    labels.push(candidate.announcement?.enabled ? `ကြေညာချက် — ${candidate.announcement.title}` : "ကြေညာချက် ပိတ်မယ်");
  }
  const liveUpdate = live.androidUpdate ?? {};
  const nextUpdate = candidate.androidUpdate ?? {};
  if ((liveUpdate.latestCode || nextUpdate.latestCode) && !equalSettings(liveUpdate, nextUpdate)) {
    labels.push(nextUpdate.latestCode ? `Android update — version ${nextUpdate.latestCode}` : "Android update အသိပေးချက် ပိတ်မယ်");
  }
  return labels;
}
let ownerEmail, setupOnly = false;
const ownerRole = user => user?.app_metadata?.chang_thai_admin === true;
const status = message => { $("status").textContent = message; };
const options = (element, rows) => {
  element.replaceChildren(...rows.map(([id, text]) => new Option(text, id)));
};

async function api(path, { method = "GET", body, headers = {} } = {}) {
  const response = await fetch(config.url + path, {
    method,
    headers: {
      apikey: config.publishableKey,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body && !(body instanceof File) ? { "Content-Type": "application/json" } : {}),
      ...headers,
    },
    body: body instanceof File ? body : body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) throw new Error(`Request failed (${response.status})`);
  return response.status === 204 ? null : response.json();
}

function run(action) {
  return async event => {
    event?.preventDefault();
    if (busy) return;
    busy = true;
    status("လုပ်ဆောင်နေပါတယ်…");
    $("workspace").inert = true;
    try { await action(event); }
    catch (error) { status(error.message); }
    finally {
      $("workspace").inert = false;
      busy = false;
    }
  };
}

async function readRow(table) {
  const [row] = await api(`/rest/v1/${table}?id=eq.1&select=revision,settings`);
  if (!row) throw new Error("Admin ခွင့်ပြုချက် မရှိပါ။");
  return row;
}

async function writeRow(table, row, nextSettings) {
  const [updated] = await api(
    `/rest/v1/${table}?id=eq.1&revision=eq.${row.revision}&select=revision,settings`,
    { method: "PATCH", body: { settings: nextSettings }, headers: { Prefer: "return=representation" } },
  );
  if (!updated) throw new Error("တခြားသူက ပြင်ထားပါတယ်။ ပြန်ဝင်ပြီး နောက်ဆုံး version ကို ဖတ်ပါ။");
  return updated;
}

const pageDescriptions = {
  overview: "သင်ရိုး၊ Live settings နဲ့ Publish လုပ်ရန် ကျန်တဲ့ Draft ကို ကြည့်ပါ။",
  ads: "Android AdMob format ၆ မျိုးနဲ့ ပြသမှုအကြိမ်ရေကို စီမံပါ။",
  lessons: "သင်ခန်းစာ ရှာပါ၊ စာသားနဲ့ အသံကို ပြင်ပြီး Draft သိမ်းပါ။",
  announcements: "App ကြေညာချက်တင်ပြီး Android Push ပို့ပါ။",
  updates: "Android version အလိုက် update အသိပေးချက် သတ်မှတ်ပါ။",
  profile: "Owner အကောင့်နဲ့ ဝင်ရန် password ကို စီမံပါ။",
};

function renderCourseChart() {
  const sections = course.sections ?? [];
  const totals = sections.map(() => 0);
  let lessonCount = 0;
  for (const unit of course.units) {
    lessonCount += unit.lessons.length;
    if (unit.section > 0 && unit.section <= totals.length) totals[unit.section - 1] += unit.lessons.length;
  }
  $("unit-count").textContent = course.units.length;
  $("section-count").textContent = sections.length;
  $("lesson-count").textContent = lessonCount;
  const max = Math.max(1, ...totals);
  $("lesson-chart").replaceChildren(...sections.map((section, index) => {
    const row = document.createElement("li");
    const label = document.createElement("span");
    const value = document.createElement("strong");
    const track = document.createElement("span");
    const bar = document.createElement("span");
    label.textContent = section;
    value.textContent = totals[index];
    track.className = "chart-track";
    track.setAttribute("aria-hidden", "true");
    bar.style.inlineSize = `${100 * totals[index] / max}%`;
    track.append(bar);
    row.append(label, value, track);
    return row;
  }));
}

function showLiveStatus(id, active, offLabel) {
  const indicator = $(id);
  indicator.textContent = active ? "အသက်ဝင်" : offLabel;
  indicator.dataset.enabled = String(active);
}

function revision() {
  const announcement = published.settings.announcement;
  const enabledAds = adCount(published.settings);
  const announcementEnabled = announcement?.enabled === true && new Date(announcement.expiresAt) > new Date();
  const updateEnabled = Number(published.settings.androidUpdate?.latestCode) > 0;
  showLiveStatus("live-banner", enabledAds > 0, "ပိတ်ထား");
  showLiveStatus("live-announcement", announcementEnabled, "မရှိသေးပါ");
  showLiveStatus("live-update", updateEnabled, "မရှိသေးပါ");
  const active = Number(enabledAds > 0) + Number(announcementEnabled) + Number(updateEnabled);
  $("active-count").textContent = `${active}/3`;
  $("live-ring").style.setProperty("--progress", `${active / 3 * 100}%`);
  $("live-ring").setAttribute("aria-label", `Live control ၃ ခုတွင် ${active} ခု အသက်ဝင်ပါတယ်။`);
  $("revision").textContent = `Live v${published.revision} · Draft v${draft.revision}`;
  $("draft-state").textContent = changeLabels(draft.settings).length ? "Live တင်ရန် ကျန်ပါတယ်" : "Live နဲ့ ကိုက်ညီပါတယ်";
  $("ads-live").textContent = adStatus(published.settings);
  $("ads-draft").textContent = adStatus(draft.settings);
  const code = published.settings.androidUpdate?.latestCode;
  $("updates-live").textContent = code ? `Live နောက်ဆုံး version code — ${code}` : "Live update အသိပေးချက် မရှိသေးပါ";
  const canPush = announcementEnabled;
  $("push-send").disabled = !canPush;
  $("push-status").textContent = canPush
    ? `Android သို့ ပို့မယ့် Live ကြေညာချက် — ${announcement.title}`
    : "သက်တမ်းရှိတဲ့ ကြေညာချက်ကို Publish လုပ်ပြီးမှ Android Push ပို့နိုင်ပါတယ်။";
  editStatus();
}

function showPage(id) {
  $("page-description").textContent = pageDescriptions[id];
  $("controls").hidden = id === "profile";
  $("publish-bar").hidden = id === "overview" || id === "profile";
  for (const button of document.querySelectorAll("[data-page]")) {
    const active = button.dataset.page === id;
    $(button.dataset.page).hidden = !active;
    if (active) {
      button.setAttribute("aria-current", "page");
      $("heading").textContent = button.lastElementChild.textContent;
    } else button.removeAttribute("aria-current");
  }
}

function setFields() {
  loadAdFields(settings);
  const a = settings.announcement ?? {};
  $("announcement-enabled").checked = a.enabled === true;
  $("announcement-title").value = a.title ?? "";
  $("announcement-body").value = a.body ?? "";
  const date = a.expiresAt ? new Date(a.expiresAt) : null;
  $("announcement-expiry").value = date && Number.isFinite(date.valueOf())
    ? new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16)
    : "";
  for (const [id, key] of [["latest-code", "latestCode"], ["minimum-code", "minimumCode"], ["update-message", "message"]]) {
    $(id).value = settings.androidUpdate?.[key] ?? "";
  }
  options($("unit"), course.units.map(u => [u.id, settings.units?.[u.id]?.title ?? u.title]));
  showUnit();
  savedForm = snapshot([...controlFields, ...lessonFields]);
  rememberLesson();
  renderPreviews();
  editStatus();
}

const selectedUnit = () => course.units.find(u => u.id === value("unit"));
const selectedLesson = () => selectedUnit().lessons.find(l => l.id === value("lesson"));
const selectedLine = () => course.lines[value("line")];

function showUnit() {
  const u = selectedUnit();
  const custom = settings.units?.[u.id] ?? {};
  for (const key of ["title", "goal", "tips"]) $("unit-" + key).value = custom[key] ?? u[key];
  options($("lesson"), u.lessons.map(l => [l.id, settings.lessons?.[l.id]?.title ?? l.title]));
  showLesson();
}
function lessonLineIds(lesson) {
  const ids = new Set(lesson.steps.flatMap(step => [step.line, ...(step.lines ?? [])]).filter(id => course.lines[id]));
  for (const id of ids) {
    for (const parts of Object.values(course.lines[id].parts ?? {})) {
      for (const part of parts) if (course.lines[part]) ids.add(part);
    }
  }
  return [...ids];
}
function showLesson() {
  const lesson = selectedLesson();
  $("lesson-title").value = settings.lessons?.[lesson.id]?.title ?? lesson.title;
  const lines = lessonLineIds(lesson);
  options($("line"), lines.map(id => [id, settings.lines?.[id]?.female?.thai ?? course.lines[id].female]));
  $("line-fields").disabled = lines.length === 0;
  showLine();
}
function checkExerciseText(id, voice, nextThai, previousThai) {
  const bundledThai = course.lines[id]?.[voice];
  if (exerciseLines[voice].has(id) && nextThai !== previousThai && nextThai !== bundledThai) {
    throw new Error(`စာကြောင်း ${id} ကို စကားလုံးစီတဲ့ လေ့ကျင့်ခန်းတွေမှာ သုံးထားပါတယ်။ ထိုင်းစာပြောင်းလိုပါက course source ထဲမှာ လေ့ကျင့်ခန်းနဲ့အတူ ပြင်ပါ။`);
  }
}

function checkDraftExerciseTexts() {
  for (const [id, forms] of Object.entries(settings.lines ?? {})) {
    for (const voice of voices) {
      const bundledThai = course.lines[id]?.[voice];
      const nextThai = forms?.[voice]?.thai ?? bundledThai;
      const liveThai = published.settings.lines?.[id]?.[voice]?.thai ?? bundledThai;
      checkExerciseText(id, voice, nextThai, liveThai);
    }
  }
}

function showLine() {
  const line = selectedLine();
  const voice = value("voice");
  const custom = settings.lines?.[value("line")]?.[voice] ?? {};
  const thai = line?.[voice] ?? "";
  $("thai-text").value = custom.thai ?? thai;
  $("exercise-text-note").hidden = !exerciseLines[voice].has(value("line"));
  $("my-text").value = custom.my ?? line?.[voice === "male" ? "myMale" : "myFemale"] ?? line?.my ?? "";
  $("romanization").value = custom.romanization ?? romanizations[thai] ?? "";
  $("lesson-audio").value = "";
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  previewUrl = null;
  void showSavedAudio();
  renderPreviews();
}

function setAudioPreview(url) {
  const audio = $("audio-preview");
  if (url) audio.src = url;
  else audio.removeAttribute("src");
  audio.hidden = !url;
  audio.load();
}

function renderPreviews() {
  renderAdPreview();
  $("preview-thai").textContent = value("thai-text");
  $("preview-romanization").textContent = value("romanization");
  $("preview-meaning").textContent = value("my-text");
  const enabled = $("announcement-enabled").checked;
  $("announcement-preview-title").textContent = enabled ? value("announcement-title") || "ကြေညာချက် ခေါင်းစဉ်" : "App မှာ မပြပါ";
  $("announcement-preview-body").textContent = enabled ? value("announcement-body") : "";
  const preview = value("preview-version-code");
  const current = Number(preview);
  const latest = Number(value("latest-code"));
  const minimum = Number(value("minimum-code"));
  const result = $("version-preview");
  if (!preview) result.textContent = "ဖုန်းရဲ့ version code တစ်ခု ထည့်ပါ။";
  else if (!$("preview-version-code").checkValidity() || !Number.isInteger(current) || latest < minimum) {
    result.textContent = "Version code တွေကို ပြန်စစ်ပါ။";
  } else if (current >= latest) result.textContent = "Update အသိပေးချက် မပေါ်ပါ။";
  else {
    const title = current < minimum ? "App ကို Update လုပ်ပါ" : "App version အသစ် ရပါပြီ";
    const message = value("update-message");
    result.textContent = message ? `${title} — ${message}` : title;
  }
}

function openPage(page) {
  if (busy || (setupOnly && page !== "profile")) return;
  showPage(page);
  $("heading").focus();
}

function lessonNavigationAllowed() {
  return !lessonChanged() || window.confirm("ဒီစာကြောင်းမှာ မသိမ်းရသေးတဲ့ ပြင်ဆင်ချက်တွေရှိပါတယ်။ ပြန်ပယ်ပြီး ဆက်မလား?");
}

function restoreSelection(saved) {
  $("unit").value = saved.unit;
  showUnit();
  $("lesson").value = saved.lesson;
  showLesson();
  $("line").value = saved.line;
  $("voice").value = saved.voice;
  showLine();
  rememberLesson();
}

function searchLessons() {
  const query = value("lesson-search").toLocaleLowerCase().normalize("NFC");
  const results = $("lesson-results");
  results.replaceChildren();
  results.hidden = !query;
  if (!query) return;
  const contains = text => String(text ?? "").toLocaleLowerCase().normalize("NFC").includes(query);
  for (const unit of course.units) {
    const title = settings.units?.[unit.id]?.title ?? unit.title;
    for (const lesson of unit.lessons) {
      const lessonTitle = settings.lessons?.[lesson.id]?.title ?? lesson.title;
      const line = lessonLineIds(lesson).find(id => {
        if (contains(id)) return true;
        const original = course.lines[id];
        return voices.some(voice => {
          const override = settings.lines?.[id]?.[voice];
          return [override?.thai ?? original[voice], override?.my ?? original.my].some(contains);
        });
      });
      if (!line && ![unit.id, title, lesson.id, lessonTitle].some(contains)) continue;
      const button = document.createElement("button");
      button.type = "button";
      button.className = "quiet";
      button.textContent = `${title} / ${lessonTitle}`;
      button.addEventListener("click", () => {
        if (!lessonNavigationAllowed()) return;
        $("unit").value = unit.id;
        showUnit();
        $("lesson").value = lesson.id;
        showLesson();
        if (line && Array.from($("line").options).some(option => option.value === line)) {
          $("line").value = line;
          showLine();
        }
        rememberLesson();
        editStatus();
        $("lesson-search").value = "";
        searchLessons();
        $("lesson").focus();
      });
      results.append(button);
      if (results.childElementCount === 12) return;
    }
  }
  if (!results.childElementCount) results.textContent = "ကိုက်ညီတဲ့ သင်ခန်းစာ မတွေ့ပါ။";
}

$("sign-in").addEventListener("submit", run(async event => {
  const form = event.currentTarget;
  token = null;
  try {
    const session = await api("/auth/v1/token?grant_type=password", {
      method: "POST", body: { email: form.elements.email.value.trim(), password: form.elements.password.value },
    });
    if (!ownerRole(session.user)) throw new Error("Owner access required");
    ownerEmail = session.user.email;
    $("profile-email").textContent = ownerEmail;
    token = session.access_token;
    draft = await readRow("chang_thai_admin_draft");
    published = await readRow("chang_thai_controls");
    settings = structuredClone(draft.settings);
    setFields();
    renderCourseChart();
    revision();
    showPage("overview");
    $("login").hidden = true;
    $("workspace").hidden = false;
    status("Admin ဝင်ပြီးပါပြီ။");
  } catch {
    token = null;
    throw new Error("Email၊ password နဲ့ Admin ခွင့်ပြုချက်ကို စစ်ပါ။");
  } finally {
    form.elements.password.value = "";
    $("show-login-password").checked = false;
    $("show-login-password").dispatchEvent(new Event("change"));
  }
}));
$("sign-out").addEventListener("click", run(async () => {
  if (settings && !setupOnly && formDirty() && !window.confirm("မသိမ်းရသေးတဲ့ ပြင်ဆင်ချက်တွေကို ပြန်ပယ်ပြီး ထွက်မလား?")) { status(""); return; }
  try { await api("/auth/v1/logout?scope=local", { method: "POST" }); }
  finally {
    token = null;
    ownerEmail = null;
    setupOnly = false;
    settings = null;
    $("change-password").reset();
    $("password-heading").textContent = "Password ပြောင်းရန်";
    $("profile-email").textContent = "";
    $("show-profile-password").dispatchEvent(new Event("change"));
    for (const button of document.querySelectorAll("[data-page]")) button.hidden = false;
    $("current-password-label").hidden = false;
    $("change-password").elements.current.required = true;
    $("workspace").hidden = true;
    $("login").hidden = false;
    status("");
  }
}));
for (const button of document.querySelectorAll("[data-page], [data-go]")) {
  button.addEventListener("click", () => openPage(button.dataset.page ?? button.dataset.go));
}
$("brand").addEventListener("click", event => {
  event.preventDefault();
  openPage("overview");
});
for (const [id, render] of [["unit", showUnit], ["lesson", showLesson], ["line", showLine], ["voice", showLine]]) {
  $(id).addEventListener("change", () => {
    if (!lessonNavigationAllowed()) {
      $(id).value = selection[id];
      return;
    }
    render();
    rememberLesson();
    editStatus();
  });
}
$("lesson-search").addEventListener("input", searchLessons);
$("controls").addEventListener("submit", event => event.preventDefault());
$("controls").addEventListener("input", () => {
  if (!settings) return;
  renderPreviews();
  editStatus();
});
for (const [toggle, form] of [["show-login-password", "sign-in"], ["show-profile-password", "change-password"]]) {
  $(toggle).addEventListener("change", () => {
    for (const field of $(form).querySelectorAll("[autocomplete$='password']")) {
      field.type = $(toggle).checked ? "text" : "password";
    }
  });
}
window.addEventListener("beforeunload", event => {
  if (settings && !setupOnly && formDirty()) event.preventDefault();
});
$("lesson-audio").addEventListener("change", () => {
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  const file = $("lesson-audio").files[0];
  previewUrl = file ? URL.createObjectURL(file) : null;
  if (previewUrl) setAudioPreview(previewUrl);
  else void showSavedAudio();
  editStatus();
});

async function collectLesson(next) {
  if (!lessonChanged()) return;
  const fields = snapshot(lessonFields);
  const unit = selectedUnit(), lesson = selectedLesson(), line = selectedLine();
  const voice = value("voice"), lineId = value("line");
  const previous = next.lines?.[lineId]?.[voice] ?? {};
  const file = $("lesson-audio").files[0];
  if (line && (!value("thai-text") || !value("my-text"))) throw new Error("ထိုင်းစာနဲ့ မြန်မာအဓိပ္ပာယ် ဖြည့်ပါ။");
  const thai = value("thai-text");
  const previousThai = previous.thai ?? line?.[voice];
  const thaiChanged = line && thai !== previousThai;
  if (line) checkExerciseText(lineId, voice, thai, previousThai);
  if (thaiChanged && thai !== line[voice] && !file) {
    throw new Error("ထိုင်းစာပြောင်းရင် ကိုက်ညီတဲ့ MP3 အသစ်ပါ ထည့်ပါ။");
  }
  let audio = thaiChanged ? undefined : previous.audio;
  if (file) {
    if (file.size > 5242880 || !file.name.toLowerCase().endsWith(".mp3")) throw new Error("5 MiB အောက် MP3 ဖိုင်ကို ရွေးပါ။");
    audio = `${crypto.randomUUID()}.mp3`;
    await api("/storage/v1/object/chang-thai-lesson-audio/" + audio, {
      method: "POST", body: file, headers: { "Content-Type": "audio/mpeg", "x-upsert": "false" },
    });
  }
  const changed = id => fields[id] !== savedForm[id];
  if (["unit-title", "unit-goal", "unit-tips"].some(changed)) {
    (next.units ??= {})[unit.id] = Object.fromEntries(
      ["title", "goal", "tips"].map(key => [key, fields["unit-" + key].trim() || unit[key]]),
    );
  }
  if (changed("lesson-title")) {
    (next.lessons ??= {})[lesson.id] = { title: fields["lesson-title"].trim() || lesson.title };
  }
  if (line && (file || ["thai-text", "my-text", "romanization"].some(changed))) {
    ((next.lines ??= {})[lineId] ??= {})[voice] = {
      thai, my: fields["my-text"].trim(), romanization: fields.romanization.trim(),
      ...(audio ? { audio } : {}),
    };
  }
}

function collect(next) {
  if (!formChanged(controlFields)) return;
  const enabled = $("announcement-enabled").checked;
  const title = value("announcement-title"), body = value("announcement-body");
  const localExpiry = value("announcement-expiry");
  if (formChanged(adsFields)) {
    const config = collectAdFields();
    next.androidAds = config;
    next.androidBanner = config.enabled && config.delivery === "live" && config.formats.banner.enabled;
  }
  if (formChanged(["announcement-enabled", "announcement-title", "announcement-body", "announcement-expiry"])) {
    if (enabled && (!title || !body || !localExpiry || new Date(localExpiry) <= new Date())) {
      throw new Error("ကြေညာချက်ခေါင်းစဉ်၊ စာသားနဲ့ ရှေ့ရက် သက်တမ်းကုန်ချိန် လိုပါတယ်။");
    }
    next.announcement = { enabled, title, body, expiresAt: localExpiry ? new Date(localExpiry).toISOString() : null };
  }
  if (formChanged(["latest-code", "minimum-code", "update-message"])) {
    const latestCode = Number(value("latest-code"));
    const minimumCode = Number(value("minimum-code"));
    if (!$("latest-code").checkValidity() || !$("minimum-code").checkValidity() || latestCode < minimumCode) {
      throw new Error("Version code တွေကို 0 မှ 2100000000 အတွင်း ထည့်ပါ။ နောက်ဆုံး version code က အနည်းဆုံး version code ထက် မငယ်ရပါ။");
    }
    next.androidUpdate = { latestCode, minimumCode, message: value("update-message") };
  }
}
function resetFromDraft() {
  const previousSelection = selection;
  settings = structuredClone(draft.settings);
  setFields();
  restoreSelection(previousSelection);
  searchLessons();
  editStatus();
}

async function saveDraft() {
  if (!formDirty()) return;
  const next = structuredClone(draft.settings);
  collect(next);
  await collectLesson(next);
  if (!equalSettings(next, draft.settings)) draft = await writeRow("chang_thai_admin_draft", draft, next);
  resetFromDraft();
  revision();
}

$("save-draft").addEventListener("click", run(async () => {
  await saveDraft();
  status("Draft သိမ်းပြီးပါပြီ။");
}));

$("discard-edits").addEventListener("click", () => {
  if (!window.confirm("မသိမ်းရသေးတဲ့ ပြင်ဆင်ချက်တွေကို ပြန်ပယ်မလား?")) return;
  resetFromDraft();
  status("သိမ်းထားတဲ့ Draft ကို ပြန်ဖွင့်ထားပါတယ်။");
});

function reviewDraft(canPublish) {
  const labels = changeLabels(draft.settings);
  const dialog = $("publish-review");
  dialog.returnValue = "cancel";
  $("confirm-publish").hidden = !canPublish;
  $("confirm-publish").disabled = equalSettings(draft.settings, published.settings);
  $("publish-review-description").textContent = `Live v${published.revision} → Draft v${draft.revision}`;
  $("publish-changes").replaceChildren(...(labels.length ? labels : ["App မှာ မြင်ရမယ့် အပြောင်းအလဲ မရှိပါ။"]).map(label => {
    const item = document.createElement("li");
    item.textContent = label;
    return item;
  }));
  dialog.showModal();
}

$("review-live").addEventListener("click", () => reviewDraft(false));
$("publish").addEventListener("click", run(async () => {
  await saveDraft();
  checkDraftExerciseTexts();
  status("");
  reviewDraft(true);
}));

$("publish-review").addEventListener("close", run(async () => {
  if ($("publish-review").returnValue !== "publish") {
    status("");
    return;
  }
  status("Draft သိမ်းပြီးပါပြီ။ Live သို့ တင်နေပါတယ်…");
  try {
    published = await writeRow("chang_thai_controls", published, draft.settings);
  } catch {
    const live = await readRow("chang_thai_controls").catch(() => null);
    if (!live) {
      throw new Error("Draft သိမ်းပြီးပါပြီ။ Live သို့ တင်ပြီးမပြီး အတည်မပြုနိုင်ပါ။ ချိတ်ဆက်မှု ပြန်ရရင် စစ်ပါ။");
    }
    if (!equalSettings(live.settings, draft.settings)) {
      if (live.revision !== published.revision) {
        throw new Error("Draft သိမ်းပြီးပါပြီ။ Live version ပြောင်းသွားပါတယ်။ နောက်ဆုံး version ကို ပြန်ဝင်စစ်ပြီးမှ Publish လုပ်ပါ။");
      }
      throw new Error("Draft သိမ်းပြီးပါပြီ။ Live သို့ မတင်ရသေးပါ။ Publish ပြန်နှိပ်နိုင်ပါတယ်။");
    }
    published = live;
  }
  revision();
  status("Live သို့ Publish လုပ်ပြီးပါပြီ။");
}));

$("push-send").addEventListener("click", run(async () => {
  const announcement = published.settings.announcement;
  if (!announcement?.enabled || !(new Date(announcement.expiresAt) > new Date())) {
    revision();
    throw new Error("သက်တမ်းရှိတဲ့ App ကြေညာချက်ကို အရင် Publish လုပ်ပါ။");
  }
  if (!window.confirm("ထုတ်ထားတဲ့ ကြေညာချက်ကို Android ဖုန်းတွေဆီ ပို့မလား?")) {
    status("");
    return;
  }
  const result = await api("/functions/v1/send-chang-thai-notification", {
    method: "POST", body: { revision: published.revision },
  });
  if (result?.accepted !== true) throw new Error("Push ကို Firebase က လက်မခံသေးပါ။");
  status("Firebase က ပို့ရန် လက်ခံပြီးပါပြီ။");
}));


const pkceKey = "chang-thai-admin-pkce";
const codeKey = "chang-thai-admin-code";
const base64url = bytes => btoa(String.fromCharCode(...bytes))
  .replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");

$("owner-setup").addEventListener("click", run(async () => {
  const verifier = base64url(crypto.getRandomValues(new Uint8Array(48)));
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier));
  sessionStorage.setItem(pkceKey, verifier);
  const url = new URL("/auth/v1/authorize", config.url);
  url.search = new URLSearchParams({
    provider: "google", prompt: "select_account",
    redirect_to: location.origin + "/?league-auth=1",
    code_challenge: base64url(new Uint8Array(digest)), code_challenge_method: "s256",
  });
  location.assign(url);
}));

const completeOwnerSetup = run(async () => {
  const code = sessionStorage.getItem(codeKey);
  const verifier = sessionStorage.getItem(pkceKey);
  sessionStorage.removeItem(codeKey);
  sessionStorage.removeItem(pkceKey);
  if (!code || !verifier) throw new Error("Google နဲ့ ပြန်ဝင်ပါ။");
  const session = await api("/auth/v1/token?grant_type=pkce", {
    method: "POST", body: { auth_code: code, code_verifier: verifier },
  });
  if (!ownerRole(session.user)) throw new Error("Chang Thai owner Google account ကို ရွေးပါ။");
  token = session.access_token;
  ownerEmail = session.user.email;
  setupOnly = true;
  $("profile-email").textContent = ownerEmail;
  $("current-password-label").hidden = true;
  $("password-heading").textContent = "Owner password သတ်မှတ်ရန်";
  $("change-password").elements.current.required = false;
  for (const button of document.querySelectorAll("[data-page]")) button.hidden = button.dataset.page !== "profile";
  showPage("profile");
  $("login").hidden = true;
  $("workspace").hidden = false;
  status("Admin password အသစ် သတ်မှတ်ပါ။");
});

$("change-password").addEventListener("submit", run(async event => {
  const form = event.currentTarget;
  try {
    if (!token || !ownerEmail) throw new Error("Admin ပြန်ဝင်ပါ။");
    if (form.elements.next.value !== form.elements.confirm.value)
      throw new Error("Password အသစ် နှစ်ခု တူရပါမယ်။");
    if (!setupOnly) {
      let fresh;
      try {
        fresh = await api("/auth/v1/token?grant_type=password", {
          method: "POST", body: { email: ownerEmail, password: form.elements.current.value },
        });
      } catch {
        throw new Error("လက်ရှိ password ကို ပြန်စစ်ပါ။");
      }
      if (!ownerRole(fresh.user)) throw new Error("Admin ခွင့်ပြုချက် လိုပါတယ်။");
      await api("/auth/v1/logout?scope=local", { method: "POST" });
      token = fresh.access_token;
    }
    await api("/auth/v1/user", { method: "PUT", body: { password: form.elements.next.value } });
    await api("/auth/v1/logout?scope=local", { method: "POST" }).catch(() => {});
    location.replace("/admin/?password=updated");
  } finally {
    form.reset();
    $("show-profile-password").dispatchEvent(new Event("change"));
  }
}));

if (sessionStorage.getItem(codeKey) !== null) {
  await completeOwnerSetup();
} else if (new URLSearchParams(location.search).get("password") === "updated") {
  history.replaceState(null, "", "/admin/");
  status("Password သိမ်းပြီးပါပြီ။ Password အသစ်နဲ့ ပြန်ဝင်ပါ။");
}
