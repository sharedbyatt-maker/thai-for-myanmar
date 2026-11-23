const $ = (id) => document.getElementById(id);
const value = (id) => $(id).value.trim();
const config = await fetch("/assets/assets/data/league_config.json").then(r => r.json());
const course = await fetch("/assets/assets/data/course_v2.json").then(r => r.json());
const romanizations = await fetch("/assets/assets/data/course_pronunciation.json").then(r => r.json());
let token, draft, published, settings, previewUrl;
let busy = false;
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
    try { await action(event); }
    catch (error) { status(error.message); }
    finally { busy = false; }
  };
}

async function readRow(table) {
  const [row] = await api(`/rest/v1/${table}?id=eq.1&select=revision,settings`);
  if (!row) throw new Error("Admin ခွင့်ပြုချက် မရှိပါ။");
  return row;
}

async function writeRow(table, row) {
  const [updated] = await api(
    `/rest/v1/${table}?id=eq.1&revision=eq.${row.revision}&select=revision,settings`,
    { method: "PATCH", body: { settings }, headers: { Prefer: "return=representation" } },
  );
  if (!updated) throw new Error("တခြားသူက ပြင်ထားပါတယ်။ ပြန်ဝင်ပြီး နောက်ဆုံး version ကို ဖတ်ပါ။");
  return updated;
}

function revision() {
  $("unit-count").textContent = `${course.units.length} ယူနစ်`;
  $("live-banner").textContent = published.settings.androidBanner === true ? "ဖွင့်ထား" : "ပိတ်ထား";
  const announcement = published.settings.announcement;
  $("live-announcement").textContent = announcement?.enabled === true &&
    new Date(announcement.expiresAt) > new Date() ? "ပြနေပါတယ်" : "မရှိသေးပါ";
  $("revision").textContent = `Live v${published.revision} · Draft v${draft.revision}`;
}

function showPage(id) {
  $("publish-bar").hidden = id === "overview";
  for (const button of document.querySelectorAll("[data-page]")) {
    const active = button.dataset.page === id;
    $(button.dataset.page).hidden = !active;
    if (active) {
      button.setAttribute("aria-current", "page");
      $("heading").textContent = button.textContent;
    } else button.removeAttribute("aria-current");
  }
}

function setFields() {
  $("banner-enabled").checked = settings.androidBanner === true;
  const a = settings.announcement ?? {};
  $("announcement-enabled").checked = a.enabled === true;
  $("announcement-title").value = a.title ?? "";
  $("announcement-body").value = a.body ?? "";
  const date = new Date(a.expiresAt);
  $("announcement-expiry").value = Number.isFinite(date.valueOf())
    ? new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16)
    : "";
  for (const [id, key] of [["latest-code", "latestCode"], ["minimum-code", "minimumCode"], ["update-message", "message"]]) {
    $(id).value = settings.androidUpdate?.[key] ?? "";
  }
  options($("unit"), course.units.map(u => [u.id, u.title]));
  showUnit();
}

const selectedUnit = () => course.units.find(u => u.id === value("unit"));
const selectedLesson = () => selectedUnit().lessons.find(l => l.id === value("lesson"));
const selectedLine = () => course.lines[value("line")];

function showUnit() {
  const u = selectedUnit();
  const custom = settings.units?.[u.id] ?? {};
  for (const key of ["title", "goal", "tips"]) $("unit-" + key).value = custom[key] ?? u[key];
  options($("lesson"), u.lessons.map(l => [l.id, l.title]));
  showLesson();
}
function showLesson() {
  const l = selectedLesson();
  $("lesson-title").value = settings.lessons?.[l.id]?.title ?? l.title;
  const ids = new Set(l.steps.flatMap(s => [s.line, ...(s.lines ?? [])]).filter(id => course.lines[id]));
  for (const id of ids) {
    for (const parts of Object.values(course.lines[id].parts ?? {})) {
      for (const part of parts) if (course.lines[part]) ids.add(part);
    }
  }
  const lines = [...ids];
  options($("line"), lines.map(id => [id, course.lines[id].female]));
  $("line-fields").disabled = lines.length === 0;
  showLine();
}
function showLine() {
  const line = selectedLine();
  const voice = value("voice");
  const custom = settings.lines?.[value("line")]?.[voice] ?? {};
  const thai = line?.[voice] ?? "";
  $("thai-text").value = custom.thai ?? thai;
  $("my-text").value = custom.my ?? line?.[voice === "male" ? "myMale" : "myFemale"] ?? line?.my ?? "";
  $("romanization").value = custom.romanization ?? romanizations[thai] ?? "";
  $("lesson-audio").value = "";
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  previewUrl = null;
  if (custom.audio) $("audio-preview").src = config.url + "/storage/v1/object/public/chang-thai-lesson-audio/" + custom.audio;
  else $("audio-preview").removeAttribute("src");
}

$("sign-in").addEventListener("submit", run(async event => {
  const form = event.currentTarget;
  token = null;
  try {
    const session = await api("/auth/v1/token?grant_type=password", {
      method: "POST", body: { email: form.elements.email.value.trim(), password: form.elements.password.value },
    });
    token = session.access_token;
    draft = await readRow("chang_thai_admin_draft");
    published = await readRow("chang_thai_controls");
    settings = structuredClone(draft.settings);
    setFields();
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
  }
}));
$("sign-out").addEventListener("click", run(async () => {
  try { await api("/auth/v1/logout?scope=local", { method: "POST" }); }
  finally {
    token = null;
    $("workspace").hidden = true;
    $("login").hidden = false;
    status("");
  }
}));
for (const button of document.querySelectorAll("[data-page]")) {
  button.addEventListener("click", () => showPage(button.dataset.page));
}
$("unit").addEventListener("change", showUnit);
$("lesson").addEventListener("change", showLesson);
$("line").addEventListener("change", showLine);
$("voice").addEventListener("change", showLine);
$("lesson-audio").addEventListener("change", () => {
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  const file = $("lesson-audio").files[0];
  previewUrl = file ? URL.createObjectURL(file) : null;
  if (previewUrl) $("audio-preview").src = previewUrl;
});

$("save-lesson").addEventListener("click", run(async () => {
  const unit = selectedUnit(), lesson = selectedLesson(), line = selectedLine();
  const voice = value("voice"), lineId = value("line");
  const previous = settings.lines?.[lineId]?.[voice] ?? {};
  const file = $("lesson-audio").files[0];
  if (line && (!value("thai-text") || !value("my-text"))) throw new Error("ထိုင်းစာနဲ့ မြန်မာအဓိပ္ပာယ် ဖြည့်ပါ။");
  if (line && value("thai-text") !== (previous.thai ?? line[voice]) && !file) {
    throw new Error("ထိုင်းစာပြောင်းရင် ကိုက်ညီတဲ့ MP3 အသစ်ပါ ထည့်ပါ။");
  }
  let audio = previous.audio;
  if (file) {
    if (file.size > 5242880 || !file.name.toLowerCase().endsWith(".mp3")) throw new Error("5 MiB အောက် MP3 ဖိုင်ကို ရွေးပါ။");
    audio = `${crypto.randomUUID()}.mp3`;
    await api("/storage/v1/object/chang-thai-lesson-audio/" + audio, {
      method: "POST", body: file, headers: { "Content-Type": "audio/mpeg", "x-upsert": "false" },
    });
  }
  (settings.units ??= {})[unit.id] = Object.fromEntries(["title", "goal", "tips"].map(k => [k, value("unit-" + k) || unit[k]]));
  (settings.lessons ??= {})[lesson.id] = { title: value("lesson-title") || lesson.title };
  if (line) {
    ((settings.lines ??= {})[lineId] ??= {})[voice] = {
      thai: value("thai-text"), my: value("my-text"), romanization: value("romanization"),
      ...(audio ? { audio } : {}),
    };
  }
  draft = await writeRow("chang_thai_admin_draft", draft);
  revision();
  showLine();
  status("Lesson draft သိမ်းပြီးပါပြီ။");
}));

function collect() {
  if (!$("controls").reportValidity()) throw new Error("ဖြည့်ထားတာတွေကို စစ်ပါ။");
  const enabled = $("announcement-enabled").checked;
  const title = value("announcement-title"), body = value("announcement-body");
  const localExpiry = value("announcement-expiry");
  if (enabled && (!title || !body || !localExpiry || new Date(localExpiry) <= new Date())) {
    throw new Error("ကြေညာချက်ခေါင်းစဉ်၊ စာသားနဲ့ ရှေ့ရက် သက်တမ်းကုန်ချိန် လိုပါတယ်။");
  }
  const latestCode = Number(value("latest-code")), minimumCode = Number(value("minimum-code"));
  if (!Number.isInteger(latestCode) || !Number.isInteger(minimumCode) || latestCode < minimumCode) {
    throw new Error("နောက်ဆုံး version code က အနည်းဆုံး version code ထက် မငယ်ရပါ။");
  }
  settings.androidBanner = $("banner-enabled").checked;
  settings.announcement = { enabled, title, body, expiresAt: localExpiry ? new Date(localExpiry).toISOString() : null };
  settings.androidUpdate = { latestCode, minimumCode, message: value("update-message") };
}
$("save-draft").addEventListener("click", run(async () => {
  collect();
  draft = await writeRow("chang_thai_admin_draft", draft);
  revision();
  status("Draft သိမ်းပြီးပါပြီ။");
}));
$("publish").addEventListener("click", run(async () => {
  if (!window.confirm("ဒီ setting တွေကို Chang Thai app နဲ့ web ဆီ ထုတ်မလား?")) {
    status("");
    return;
  }
  collect();
  draft = await writeRow("chang_thai_admin_draft", draft);
  published = await writeRow("chang_thai_controls", published);
  revision();
  status("Publish လုပ်ပြီးပါပြီ။");
}));

$("push-send").disabled = false;
$("push-send").addEventListener("click", run(async () => {
  if (!published.settings?.announcement?.enabled) {
    throw new Error("App ကြေညာချက်ကို အရင် Publish လုပ်ပါ။");
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
