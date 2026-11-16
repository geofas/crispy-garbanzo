// Tests for the waitlist function. Run: node --test tools/
import test from "node:test";
import assert from "node:assert/strict";
import { onRequestPost, onRequest } from "../functions/api/waitlist.js";

const env = { SUPABASE_URL: "https://example.supabase.co/", SUPABASE_KEY: "test-key" };
let calls = [];
let upstream = () => new Response(null, { status: 204 });
globalThis.fetch = async (url, init) => { calls.push({ url, init }); return upstream(); };

function post(body, { type = "application/json", origin = "https://nudgytimer.app", e = env } = {}) {
  calls = [];
  const headers = { "content-type": type };
  if (origin) headers.origin = origin;
  const request = new Request("https://nudgytimer.app/api/waitlist", {
    method: "POST", headers, body: typeof body === "string" ? body : JSON.stringify(body),
  });
  return onRequestPost({ request, env: e });
}

test("valid email is stored, lower-cased and trimmed", async () => {
  const r = await post({ email: "  Ada@Example.COM ", website: "", source: "hero" });
  assert.equal(r.status, 200);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://example.supabase.co/rest/v1/rpc/join_waitlist");
  assert.deepEqual(JSON.parse(calls[0].init.body), { p_email: "ada@example.com", p_source: "hero" });
  assert.equal(calls[0].init.headers.apikey, "test-key");
});

for (const bad of ["", "nope", "a@b", "a b@c.de", "@c.de", "x".repeat(250) + "@c.de"]) {
  test(`invalid email rejected: ${bad.slice(0, 12)}`, async () => {
    const r = await post({ email: bad });
    assert.equal(r.status, 400);
    assert.equal(calls.length, 0);
  });
}

test("honeypot filled: reports ok but stores nothing", async () => {
  const r = await post({ email: "bot@example.com", website: "http://spam" });
  assert.equal(r.status, 200);
  assert.equal(calls.length, 0);
});

test("other origin is refused", async () => {
  const r = await post({ email: "a@example.com" }, { origin: "https://evil.example" });
  assert.equal(r.status, 403);
  assert.equal(calls.length, 0);
});

test("malformed JSON is rejected", async () => {
  const r = await post("{not json");
  assert.equal(r.status, 400);
});

test("oversized body is rejected", async () => {
  const r = await post({ email: "a@example.com", pad: "x".repeat(3000) });
  assert.equal(r.status, 400);
  assert.equal(calls.length, 0);
});

test("missing configuration gives 503, no upstream call", async () => {
  const r = await post({ email: "a@example.com" }, { e: {} });
  assert.equal(r.status, 503);
  assert.equal(calls.length, 0);
});

test("database error gives 503", async () => {
  upstream = () => new Response("boom", { status: 500 });
  const r = await post({ email: "a@example.com" });
  assert.equal(r.status, 503);
  upstream = () => new Response(null, { status: 204 });
});

test("network failure gives 503", async () => {
  upstream = () => { throw new Error("down"); };
  const r = await post({ email: "a@example.com" });
  assert.equal(r.status, 503);
  upstream = () => new Response(null, { status: 204 });
});

test("form post without JavaScript redirects back with the result", async () => {
  const r = await post("email=ada%40example.com&website=", { type: "application/x-www-form-urlencoded" });
  assert.equal(r.status, 303);
  assert.equal(r.headers.get("location"), "https://nudgytimer.app/?waitlist=ok#waitlist");
  assert.equal(calls.length, 1);
});

test("form post with a bad email redirects with invalid", async () => {
  const r = await post("email=nope", { type: "application/x-www-form-urlencoded" });
  assert.equal(r.status, 303);
  assert.match(r.headers.get("location"), /waitlist=invalid/);
});

test("GET is not allowed", () => {
  assert.equal(onRequest().status, 405);
});
