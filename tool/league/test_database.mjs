import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const root = fileURLToPath(new URL('../../', import.meta.url));
const db = new PGlite();
await db.exec(`create role anon; create role authenticated; create schema auth;
create table auth.users(id uuid primary key, email_confirmed_at timestamptz default now());
create function auth.uid() returns uuid language sql stable as $$
select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
grant usage on schema auth to authenticated;`);
for (const file of ['20261030112653_weekly_leagues.sql','20261030112659_question_catalog.sql']) {
  await db.exec(readFileSync(root + 'supabase/migrations/' + file, 'utf8'));
}
async function scalar(sql, params = []) { return Object.values((await db.query(sql, params)).rows[0])[0]; }
async function user(n) {
  const id = '00000000-0000-4000-8000-' + String(n).padStart(12, '0');
  await db.query('insert into auth.users(id) values($1) on conflict do nothing', [id]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id]);
  return id;
}
async function denied(fn) { await assert.rejects(fn); }
async function expireMinimum(id) {
  await db.query("update league_private.rounds set created_at=created_at-interval '6 seconds' where id=$1",[id]);
}
async function round() { return scalar('select public.league_begin_round()'); }
async function answers(id) { return scalar('select answers from league_private.rounds where id=$1',[id]); }
async function submit(id, choices) { return scalar('select public.league_submit_round($1,$2::integer[])',[id,choices]); }
async function board() { return scalar('select public.league_board()'); }
assert.equal(await scalar('select count(*)::integer from league_private.questions'),502);
assert.equal(await scalar('select count(distinct lesson_id)::integer from league_private.questions'),112);
await db.exec('set role anon');
await denied(() => board());
await db.exec('reset role');
await denied(() => board());
const first = await user(1);
assert.equal((await board()).joined,false);
await db.query('update auth.users set email_confirmed_at=null where id=$1',[first]);
await denied(()=>db.query('select public.league_join($1,0)',['Unverified']));
await db.query('update auth.users set email_confirmed_at=now() where id=$1',[first]);
await db.query('select public.league_join($1,0)',['Learner 1']);
for (let n=2;n<=21;n++) { await user(n); await db.query('select public.league_join($1,1)',['Learner '+n]); }
const sizes=(await db.query('select count(*)::integer n from league_private.members group by group_id order by n')).rows.map(x=>x.n);
assert.deepEqual(sizes,[1,20]);
await user(1);
let b=await board();
assert.equal(b.rows.length,20);
assert.equal(b.rows.filter(x=>x.mine).length,1);
assert.ok(!JSON.stringify(b).includes(first));
assert.ok(!JSON.stringify(b).includes('email'));
await db.exec('set role authenticated');
await denied(() => db.query('select * from league_private.rounds'));
await denied(() => db.query('update league_private.members set points=100000'));
let r=await round();
assert.ok(r.questions.length>0 && r.questions.length<=5);
assert.ok(!('answers' in r));
assert.ok(r.questions.every(q => !('answer' in q) && !('answers' in q)));
assert.deepEqual(await round(),r); // Resume, never generate unlimited parallel rounds.
await db.exec('reset role');
let correct=await answers(r.id);
await denied(()=>submit(r.id,correct)); // Too early.
await expireMinimum(r.id);
await user(2);
await denied(()=>submit(r.id,correct)); // Another user's attempt.
await user(1);
await denied(()=>submit(r.id,[4]));
await denied(()=>submit(r.id,null));
await db.exec('set role authenticated');
const result=await submit(r.id,correct);
assert.equal(result.bonus,20);
assert.equal(result.earned,correct.length*5+20);
assert.deepEqual(await submit(r.id,correct),result); // Idempotent retry.
await db.exec('reset role');
assert.equal((await board()).daily_points,result.earned);
assert.equal((await board()).rows.find(x=>x.mine).points,result.earned);
// Every correct answer is checked on the server. Wrong choices earn nothing.
r=await round(); correct=await answers(r.id); await expireMinimum(r.id);
const wrong=correct.map(x=>(x+1)%4);
const wrongResult=await submit(r.id,wrong);
assert.equal(wrongResult.correct,0); assert.equal(wrongResult.earned,0);
// Replaying the same lesson cannot farm its review credit or completion bonus.
// Force a new round of the first lesson and verify the unique credit guards.
const paid=(await db.query('select * from league_private.rounds where user_id=$1 and result is not null order by created_at limit 1',[first])).rows[0];
const duplicateId=await scalar(`insert into league_private.rounds(user_id,week,lesson_id,phrase_ids,payload,answers,created_at)
select user_id,week,lesson_id,phrase_ids,payload,answers,clock_timestamp()-interval '6 seconds' from league_private.rounds where id=$1 returning id`,[paid.id]);
const replay=await submit(duplicateId,paid.answers);
assert.equal(replay.earned,0);
// A fresh account can never exceed the server's 100-point Bangkok daily cap.
await user(21);
let earned=0;
while(earned<100) {
  r=await round(); await expireMinimum(r.id); correct=await answers(r.id);
  const scored=await submit(r.id,correct); earned+=scored.earned;
}
assert.equal(earned,100);
await denied(()=>round());
assert.equal((await board()).daily_points,100);
// Opt-out hides the profile and blocks further scoring, without deleting auth.
await db.query('select public.league_leave()');
assert.equal((await board()).joined,false);
await denied(()=>round());
assert.equal(await scalar('select count(*)::integer from auth.users'),21);
// Old-week rounds cannot be submitted after rollover.
await user(2); r=await round(); await expireMinimum(r.id);
await db.query("update league_private.rounds set week=week-7 where id=$1",[r.id]);
await denied(()=>submit(r.id,[]));
// Rollover promotion: at least five active scorers, highest quarter advances.
await user(1);
const group=await scalar('select group_id from league_private.members where user_id=$1',[first]);
await db.query('update league_private.members set points=case when user_id=$1 then 200 else 10 end where group_id=$2',[first,group]);
await db.exec('update league_private.members set week=week-7; update league_private.groups set week=week-7;');
b=await board(); assert.equal(b.tier,1); assert.equal(b.rows.find(x=>x.mine).points,0);
// The new week's board is stable on repeated loads (no double promotion).
assert.equal((await board()).tier,1);
await db.close();
console.log('PASS: catalog, privacy, group capacity, auth, scoring, retries, cap, opt-out and rollover');
