// Waitlist forms: submit without a page reload. Without JavaScript the form
// still works: it posts to /api/waitlist and is redirected back to the page.
(function () {
  var messages = {
    ok: "You're on the list. We'll email you once, when Nudgy Timer is on the App Store.",
    invalid: "That email address doesn't look right. Please check it and try again.",
    error: "That didn't go through. Please try again in a minute."
  };

  function show(form, kind) {
    var status = form.querySelector(".form-status");
    if (!status) return;
    status.textContent = messages[kind];
    status.className = "form-status " + (kind === "ok" ? "ok" : "err");
  }

  // Result of a no-JavaScript submission, passed back in the query string.
  var result = new URLSearchParams(window.location.search).get("waitlist");
  if (result && messages[result]) {
    var first = document.querySelector("form.waitlist");
    if (first) show(first, result);
    history.replaceState(null, "", window.location.pathname + window.location.hash);
  }

  document.querySelectorAll("form.waitlist").forEach(function (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var button = form.querySelector("button");
      var email = form.querySelector('input[type="email"]');
      if (!email.checkValidity()) { show(form, "invalid"); email.focus(); return; }
      button.disabled = true;
      fetch(form.action, {
        method: "POST",
        headers: { "content-type": "application/json", accept: "application/json" },
        body: JSON.stringify({
          email: email.value,
          website: form.querySelector('input[name="website"]').value,
          source: form.dataset.source || "site"
        })
      })
        .then(function (response) {
          if (response.ok) { show(form, "ok"); form.reset(); }
          else if (response.status === 400) { show(form, "invalid"); }
          else { show(form, "error"); }
        })
        .catch(function () { show(form, "error"); })
        .then(function () { button.disabled = false; });
    });
  });
})();
