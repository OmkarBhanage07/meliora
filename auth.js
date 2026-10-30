/* Connects meliora.html to the Flask backend. Loaded AFTER the page's own script. */
(function () {
  var css = document.createElement('style');
  css.textContent =
    '#authbg{position:fixed;inset:0;background:rgba(20,15,10,.55);display:none;align-items:center;justify-content:center;z-index:999}' +
    '#authbg.on{display:flex}' +
    '#authbox{background:#fffdf9;color:#1a1512;border-radius:24px;padding:32px;width:min(380px,92vw);box-shadow:0 20px 60px rgba(0,0,0,.25)}' +
    '#authbox h3{margin:0 0 16px;font-size:26px}' +
    '#authbox input{width:100%;box-sizing:border-box;padding:12px 14px;margin-bottom:10px;border:1px solid #d9d0c4;border-radius:12px;font:inherit}' +
    '#authbox button.go{width:100%;padding:12px;border:0;border-radius:999px;background:var(--gold,#b8903f);color:#fff;font:inherit;cursor:pointer}' +
    '#autherr{color:#b3261e;font-size:13px;min-height:18px;margin:0 0 8px}' +
    '#authsw{font-size:13px;margin-top:12px;text-align:center;cursor:pointer;color:#6b6258}';
  document.head.appendChild(css);

  var bg = document.createElement('div');
  bg.id = 'authbg';
  bg.innerHTML = '<div id="authbox"><h3 id="authtitle"></h3>' +
    '<input id="an" placeholder="Your name" autocomplete="name">' +
    '<input id="ae" type="email" placeholder="Email" autocomplete="email">' +
    '<input id="ap" type="password" placeholder="Password (6+ characters)" autocomplete="current-password">' +
    '<p id="autherr"></p><button class="go" id="authgo"></button><div id="authsw"></div></div>';
  document.body.appendChild(bg);
  bg.onclick = function (e) { if (e.target === bg) bg.classList.remove('on'); };

  var mode = 'login';
  function setMode(m) {
    mode = m;
    document.getElementById('authtitle').textContent = m === 'login' ? 'Welcome back' : 'Create your account';
    document.getElementById('an').style.display = m === 'login' ? 'none' : 'block';
    document.getElementById('authgo').textContent = m === 'login' ? 'Sign In' : 'Create Account';
    document.getElementById('authsw').textContent = m === 'login' ? 'New here? Create an account' : 'Already have an account? Sign in';
    document.getElementById('autherr').textContent = '';
  }
  function open(m) { setMode(m); bg.classList.add('on'); }
  document.getElementById('authsw').onclick = function () { setMode(mode === 'login' ? 'register' : 'login'); };

  function post(url, body) {
    return fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) })
      .then(function (r) { return r.json().then(function (j) { j.ok = r.ok; return j; }); });
  }

  document.getElementById('authgo').onclick = function () {
    post('/api/' + mode, {
      name: document.getElementById('an').value,
      email: document.getElementById('ae').value,
      password: document.getElementById('ap').value
    }).then(function (j) {
      if (!j.ok) { document.getElementById('autherr').textContent = j.error; return; }
      bg.classList.remove('on');
      showUser(j.user);
      loadHistory();
    });
  };

  var navr = document.querySelector('.navr');
  function showUser(u) {
    if (u) {
      navr.innerHTML = '<span style="margin-right:14px">Hi, ' + u.name.replace(/</g, '&lt;') + '</span><a class="btn btn-out" href="#" id="lo">Log out</a>';
      document.getElementById('lo').onclick = function (e) {
        e.preventDefault();
        post('/api/logout').then(function () { location.reload(); });
      };
    } else {
      navr.innerHTML = '<a href="#" id="si">Sign In</a><a class="btn btn-out" href="#" id="ca">Create Account</a>';
      document.getElementById('si').onclick = function (e) { e.preventDefault(); open('login'); };
      document.getElementById('ca').onclick = function (e) { e.preventDefault(); open('register'); };
    }
  }

  /* replace the scripted demo chat with the real backend */
  window.send = function (t) {
    add('u', t.replace(/</g, '&lt;'));
    var d = add('b', '…');
    post('/api/chat', { message: t })
      .then(function (j) { d.innerHTML = j.reply || j.error; msgs.scrollTop = msgs.scrollHeight; })
      .catch(function () { d.textContent = 'Mili is offline right now. Please try again.'; });
  };

  function loadHistory() {
    fetch('/api/chat/history').then(function (r) { return r.json(); }).then(function (j) {
      if (!j.messages.length) return;
      msgs.innerHTML = '';
      j.messages.forEach(function (m) {
        add(m.role === 'user' ? 'u' : 'b', m.role === 'user' ? m.content.replace(/</g, '&lt;') : m.content);
      });
    });
  }

  fetch('/api/me').then(function (r) { return r.json(); }).then(function (j) {
    showUser(j.user);
    if (j.user) loadHistory();
  });
})();
