"use strict";
const token = new URLSearchParams(location.search).get("token");
const el = id => document.getElementById(id);
const privateUrl = path => `${path}?token=${encodeURIComponent(token)}`;
let busy = false, lastJob = "", closed = false;
async function api(path, data) {
  const response = await fetch(path, {method: data ? "POST" : "GET", headers: {"X-Studio-Token": token, ...(data ? {"Content-Type": "application/json"} : {})}, ...(data ? {body: JSON.stringify(data)} : {})});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || "Request failed");
  return result;
}
function showError(message) {document.body.classList.add("error"); el("message").textContent = message;}
function settings(mode) {
  return {mode, male: Number(el("male").value), female: Number(el("female").value), speed: Number(el("speed").value), text: el("text").value, speaker: Number(el(el("previewForm").value).value)};
}
async function start(mode) {
  if (busy) return;
  busy = true;
  for (const id of ["preview", "sample", "all"]) el(id).disabled = true;
  document.body.classList.remove("error");
  el("download").hidden = true; el("partial").hidden = true; el("player").hidden = true;
  el("message").textContent = "Preparing...";
  try {await api("/api/start", settings(mode)); await poll();}
  catch (e) {showError(e.message); busy = false; for (const id of ["preview", "sample", "all"]) el(id).disabled = false;}
}
async function poll() {
  if (closed) return;
  try {
    const state = await api("/api/state");
    busy = state.status === "running";
    for (const id of ["preview", "sample", "all"]) el(id).disabled = busy;
    el("stop").disabled = !busy;
    el("progress").max = state.total || 1;
    el("progress").value = state.done || 0;
    el("counter").textContent = `${state.done || 0} / ${state.total || 0}`;
    el("statusLabel").textContent = {idle:"အဆင်သင့်ပါ",running:"လုပ်ဆောင်နေပါတယ်…",complete:"ပြီးပါပြီ",stopped:"ရပ်ထားပါတယ်",error:"ပြန်စစ်ရန် လိုပါတယ်"}[state.status] || state.status;
    el("message").textContent = state.message;
    document.body.classList.toggle("error", state.status === "error");
    if (state.audio && state.job !== lastJob) {el("player").src = privateUrl(`/audio/${state.job}`); el("player").hidden = false; lastJob = state.job;}
    if (state.download) {el("download").href = privateUrl(`/download/${state.job}`); el("download").hidden = false; el("partial").hidden = state.status === "complete";}
  } catch (e) {el("message").textContent = "Studio connection lost. Keep the launcher window open, or reopen Start_Audio_Studio.bat.";}
}
async function init() {
  try {
    const config = await api("/api/config");
    el("phraseCount").textContent = config.phraseCount; el("fileCount").textContent = config.files;
    for (const [id, gender, name] of config.speakers) {const option = document.createElement("option"); option.value = id; option.textContent = name; el(gender).appendChild(option);}
    el("male").value = "9"; el("female").value = "2";
    for (const mode of ["preview", "sample", "all"]) el(mode).addEventListener("click", () => start(mode));
    el("example").addEventListener("change", () => {const key=el("example").value; el("text").value = {male:"สวัสดีครับ",female:"สวัสดีค่ะ",question:"อันนี้ราคาเท่าไหร่คะ",tones:"ข้าว ขาว ข่าว"}[key]; el("previewForm").value = key === "male" ? "male" : "female";});
    el("stop").addEventListener("click", async () => {try {await api("/api/stop", {}); el("message").textContent = "Stopping after the current CPU operation...";} catch(e) {showError(e.message);}});
    el("shutdown").addEventListener("click", async () => {try {await api("/api/shutdown", {}); closed = true; el("message").textContent = "Studio closed. You can close this tab and the launcher window."; for (const id of ["preview","sample","all","stop","shutdown"]) el(id).disabled=true;} catch(e) {showError(e.message);}});
    await poll(); setInterval(poll, 1200);
  } catch (e) {showError(e.message);}
}
init();
