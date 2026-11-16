// Cloudflare Pages Function: POST /api/waitlist
//
// Stores a waitlist email in Supabase by calling the join_waitlist() database
// function (see ../../supabase/waitlist.sql). The browser never talks to
// Supabase directly.
//
// Environment variables (Cloudflare Pages → Settings → Variables and Secrets):
//   SUPABASE_URL  e.g. https://<project-ref>.supabase.co
//   SUPABASE_KEY  the project's publishable (anon) key

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const MAX_BODY = 2000;

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

function reply(wantsJson, requestUrl, kind) {
  const status = kind === "ok" ? 200 : kind === "invalid" ? 400 : 503;
  if (wantsJson) return json(status, { result: kind });
  // No-JavaScript form post: send the visitor back to the page with the result.
  const back = new URL("/", requestUrl);
  back.searchParams.set("waitlist", kind);
  back.hash = "waitlist";
  return Response.redirect(back.toString(), 303);
}

export async function onRequestPost({ request, env }) {
  const type = request.headers.get("content-type") || "";
  const wantsJson = type.includes("application/json");

  // Only accept posts that come from this site's own pages.
  const origin = request.headers.get("origin");
  if (origin && new URL(origin).host !== new URL(request.url).host) {
    return json(403, { result: "forbidden" });
  }

  let fields = {};
  try {
    const text = await request.text();
    if (text.length > MAX_BODY) return reply(wantsJson, request.url, "invalid");
    fields = wantsJson ? JSON.parse(text) : Object.fromEntries(new URLSearchParams(text));
  } catch {
    return reply(wantsJson, request.url, "invalid");
  }

  // Honeypot: real visitors never see or fill this field. Pretend it worked.
  if (typeof fields.website === "string" && fields.website.trim() !== "") {
    return reply(wantsJson, request.url, "ok");
  }

  const email = String(fields.email || "").trim().toLowerCase();
  if (email.length > 254 || !EMAIL.test(email)) {
    return reply(wantsJson, request.url, "invalid");
  }
  const source = String(fields.source || "site").slice(0, 40);

  if (!env.SUPABASE_URL || !env.SUPABASE_KEY) {
    console.error("waitlist: SUPABASE_URL or SUPABASE_KEY is not set");
    return reply(wantsJson, request.url, "error");
  }

  try {
    const response = await fetch(`${env.SUPABASE_URL.replace(/\/$/, "")}/rest/v1/rpc/join_waitlist`, {
      method: "POST",
      headers: {
        apikey: env.SUPABASE_KEY,
        authorization: `Bearer ${env.SUPABASE_KEY}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ p_email: email, p_source: source }),
    });
    if (!response.ok) {
      console.error("waitlist: Supabase returned", response.status, await response.text());
      return reply(wantsJson, request.url, "error");
    }
  } catch (error) {
    console.error("waitlist: request to Supabase failed", error);
    return reply(wantsJson, request.url, "error");
  }

  // Same answer whether or not the address was already on the list.
  return reply(wantsJson, request.url, "ok");
}

export function onRequest() {
  return json(405, { result: "method_not_allowed" });
}
