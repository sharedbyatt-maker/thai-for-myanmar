"use strict";
const token = new URLSearchParams(location.search).get("token");
const el = id => document.getElementById(id);
const privateUrl = path => `${path}?token=${encodeURIComponent(token)}`;
let busy = false, lastJob = "", closed = false, courseMissing = 0, courseScopes = {};
const modes = ["preview", "sample", "all", "course", "course-sample"];
function updateScope() {
  const scope = courseScopes[el("scope").value] || {files: 0, sampleFiles: 0};
  courseMissing = scope.files;
  el("courseCount").textContent = scope.files; el("courseSampleCount").textContent = scope.sampleFiles;
  for (const id of modes) el(id).disabled = busy || (id.startsWith("course") && !courseMissing);
  for (const input of document.querySelectorAll("select, textarea")) input.disabled = busy;
}
async function api(path, data) {
  const response = await fetch(path, {method: data ? "POST" : "GET", headers: {"X-Studio-Token": token, ...(data ? {"Content-Type": "application/json"} : {})}, ...(data ? {body: JSON.stringify(data)} : {})});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || "Request failed");
  return result;
}
function showError(message) {document.body.classList.add("error"); el("message").textContent = message;}
function settings(mode) {
  return {mode, scope: el("scope").value, male: Number(el("male").value), female: Number(el("female").value), speed: Number(el("speed").value), text: el("text").value, speaker: Number(el(el("previewForm").value).value)};
}
async function start(mode) {
  if (busy) return;
  busy = true;
  updateScope();
  document.body.classList.remove("error");
  el("download").hidden = true; el("partial").hidden = true; el("player").hidden = true;
  el("message").textContent = "Preparing...";
  try {await api("/api/start", settings(mode)); await poll();}
  catch (e) {showError(e.message); busy = false; updateScope();}
}
async function poll() {
  if (closed) return;
  try {
    const state = await api("/api/state");
    busy = state.status === "running";
    updateScope();
    el("stop").disabled = !busy;
    el("progress").max = state.total || 1;
    el("progress").value = state.done || 0;
    el("counter").textContent = `${state.done || 0} / ${state.total || 0}`;
    el("statusLabel").textContent = {idle:"အဆင်သင့်ပါ",running:"လုပ်ဆောင်နေပါတယ်…",complete:"ပြီးပါပြီ",stopped:"ရပ်ထားပါတယ်",error:"ပြန်စစ်ရန် လိုပါတယ်"}[state.status] || state.status;
    el("message").textContent = state.message;
    el("activeSettings").textContent = state.settings ? `အသံရွေးထားမှု · Male ${state.settings.male} / Female ${state.settings.female} · Speed ${state.settings.speed}` : "";
    document.body.classList.toggle("error", state.status === "error");
    if (state.audio && state.job !== lastJob) {el("player").src = privateUrl(`/audio/${state.job}`); el("player").hidden = false; lastJob = state.job;}
    if (state.download) {el("download").download = state.downloadName || "thai-audio.zip"; el("download").href = privateUrl(`/download/${state.job}`); el("download").hidden = false; el("partial").hidden = state.status === "complete";}
  } catch (e) {el("message").textContent = "Studio connection lost. Keep the launcher window open, or reopen Start_Audio_Studio.bat.";}
}
async function init() {
  try {
    const config = await api("/api/config");
    el("existingCount").textContent = config.existingFiles; el("phraseCount").textContent = config.phraseCount; el("fileCount").textContent = config.files; courseScopes = config.courseScopes || {}; updateScope();
    for (const [id, gender, name] of config.speakers) {const option = document.createElement("option"); option.value = id; option.textContent = name; el(gender).appendChild(option);}
    const saved = config.settings || {male: 9, female: 2, speed: 1};
    el("male").value = String(saved.male); el("female").value = String(saved.female); el("speed").value = String(saved.speed);
    el("scope").addEventListener("change", updateScope);
    for (const mode of modes) el(mode).addEventListener("click", () => start(mode));
    el("example").addEventListener("change", () => {const key=el("example").value; el("text").value = {male:"สวัสดีครับ",female:"สวัสดีค่ะ",question:"อันนี้ราคาเท่าไหร่คะ",tones:"ข้าว ขาว ข่าว"}[key]; el("previewForm").value = key === "male" ? "male" : "female";});
    el("stop").addEventListener("click", async () => {try {await api("/api/stop", {}); el("message").textContent = "Stopping after the current CPU operation...";} catch(e) {showError(e.message);}});
    el("shutdown").addEventListener("click", async () => {try {await api("/api/shutdown", {}); closed = true; el("message").textContent = "Studio closed. You can close this tab and the launcher window."; for (const id of [...modes,"stop","shutdown"]) el(id).disabled=true;} catch(e) {showError(e.message);}});
    await poll(); setInterval(poll, 1200);
  } catch (e) {showError(e.message);}
}
init();
