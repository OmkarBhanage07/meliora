/* Meliora extras: Mili answers from the skin guide, skin quiz, profile, save brands/routines. Loaded after auth.js. */
(function () {
  var $ = function (i) { return document.getElementById(i); };
  var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  var slug = function (s) { return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''); };
  function api(url, method, body) {
    return fetch(url, { method: method || 'GET', headers: { 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined })
      .then(function (r) { return r.json().then(function (j) { j.ok = r.ok; return j; }); });
  }
  function signIn() { closeModal(); var s = $('si'); if (s) s.click(); }
  function ask(text) { closeModal(); location.hash = 'mili'; setTimeout(function () { window.send(text); }, 400); }

  var css = document.createElement('style');
  css.textContent =
    '#xbg{position:fixed;inset:0;background:rgba(20,15,10,.55);display:none;align-items:center;justify-content:center;z-index:998;overflow:auto;padding:20px}#xbg.on{display:flex}' +
    '#xbox{position:relative;background:#fffdf9;color:#1a1512;border-radius:24px;padding:32px;width:min(520px,94vw);max-height:90vh;overflow:auto;box-shadow:0 20px 60px rgba(0,0,0,.25)}' +
    '#xbox h3{margin:0 0 8px;font-size:26px}#xbox h3 small{font-size:13px;color:var(--mute);font-weight:400}#xbox h4{margin:18px 0 8px;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--gold)}' +
    '#xbox .xc{position:absolute;top:14px;right:18px;border:0;background:none;font-size:26px;cursor:pointer;color:var(--mute)}' +
    '#xbox .xo{display:block;width:100%;text-align:left;margin:8px 0;padding:13px 16px;border:1px solid var(--line);border-radius:14px;background:#fff;font:inherit;cursor:pointer}#xbox .xo:hover{border-color:var(--gold);background:#fdf6e3}' +
    '#xbox .xr{display:flex;gap:10px;flex-wrap:wrap;margin-top:16px}#xbox .xr .btn{cursor:pointer;flex:1;justify-content:center;text-align:center}' +
    '#xbox .xi{padding:10px 14px;border:1px solid var(--line);border-radius:12px;margin:6px 0;font-size:14px}#xbox .xi ol{margin:6px 0 0 18px;padding:0}#xbox .xm{font-size:13px;color:var(--mute);min-height:18px;margin-top:10px}' +
    '.hrt{margin-top:10px;border:1px solid var(--line);background:#fff;border-radius:999px;padding:7px 14px;font:inherit;font-size:13px;cursor:pointer}.hrt.on{background:var(--rose);color:#fff;border-color:var(--rose)}';
  document.head.appendChild(css);

  function closeModal() { var b = $('xbg'); if (b) b.classList.remove('on'); }
  function modal(html) {
    var bg = $('xbg');
    if (!bg) { bg = document.createElement('div'); bg.id = 'xbg'; bg.onclick = function (e) { if (e.target === bg) closeModal(); }; document.body.appendChild(bg); }
    bg.innerHTML = '<div id="xbox">' + html + '<button class="xc" id="xclose" aria-label="Close">×</button></div>';
    $('xclose').onclick = closeModal;
    bg.classList.add('on');
  }

  /* ---- 1. skin guide + hero chips talk to Mili / the guide ---- */
  function curSkin() { var t = document.querySelector('#stabs [aria-selected="true"]'); return t ? t.dataset.k : 'Oily'; }
  $('guidebox').addEventListener('click', function (e) {
    var a = e.target.closest('a'); if (!a) return;
    var k = curSkin();
    if (a.classList.contains('btn')) { e.preventDefault(); ask('I have ' + k.toLowerCase() + ' skin. Which products and brands should I use?'); }
    else if (a.classList.contains('link')) { e.preventDefault(); ask('Build me a full AM and PM routine for ' + k.toLowerCase() + ' skin.'); }
  });
  [].forEach.call(document.querySelectorAll('.chips span'), function (c) {
    c.style.cursor = 'pointer';
    c.onclick = function () { window.showSkin(c.textContent.trim()); location.hash = 'guide'; };
  });

  /* ---- 2. skin quiz ---- */
  var SK = ['Dry', 'Normal', 'Oily', 'Combination', 'Sensitive'];
  var QZ = [
    ['An hour after washing, your face feels…', ['Tight or flaky', 'Comfortable', 'Shiny all over', 'Shiny only on forehead and nose', 'Red or stinging']],
    ['By midday your skin looks…', ['Dull and dry', 'Fresh and even', 'Greasy', 'Oily in the middle, dry on the cheeks', 'Flushed or irritated']],
    ['Your pores are…', ['Barely visible', 'Small', 'Large and visible', 'Large on the nose only', 'Hard to say, my skin is reactive']],
    ['New products usually…', ['Absorb fast but I still feel dry', 'Cause no issues', 'Cause breakouts', 'Give mixed results', 'Sting or turn me red']],
    ['Your biggest concern is…', ['Flaking and tightness', 'Keeping my skin balanced', 'Shine and blemishes', 'Balancing oily and dry areas', 'Redness and irritation']]
  ];
  function quiz() {
    var i = 0, votes = {};
    function step() {
      if (i >= QZ.length) return result();
      modal('<h3>Skin Quiz <small>' + (i + 1) + ' / ' + QZ.length + '</small></h3><p>' + QZ[i][0] + '</p>' +
        QZ[i][1].map(function (o, k) { return '<button class="xo" data-k="' + k + '">' + o + '</button>'; }).join(''));
      [].forEach.call(document.querySelectorAll('#xbox .xo'), function (b) {
        b.onclick = function () { var s = SK[b.dataset.k]; votes[s] = (votes[s] || 0) + 1; i++; step(); };
      });
    }
    function result() {
      var best = SK.reduce(function (a, b) { return (votes[b] || 0) > (votes[a] || 0) ? b : a; });
      var s = window.skins[best];
      modal('<h3>' + s.i + ' You have ' + best + ' skin</h3><p>' + esc(s.t) + '</p><h4>Main concerns</h4><p>' + s.c.map(esc).join(' · ') +
        '</p><div class="xr"><button class="btn btn-gold" id="qs">Save to my profile</button><button class="btn btn-out" id="qa">Ask Mili</button><button class="btn btn-out" id="qg">See guide</button></div><div class="xm" id="qm"></div>');
      $('qa').onclick = function () { ask('My quiz result is ' + best.toLowerCase() + ' skin. What routine do you recommend?'); };
      $('qg').onclick = function () { closeModal(); window.showSkin(best); location.hash = 'guide'; };
      $('qs').onclick = function () {
        api('/api/skin-type', 'POST', { skin: best.toLowerCase() }).then(function (j) {
          if (j.ok) $('qm').textContent = '✓ Saved. Mili will use this from now on.';
          else if (/sign in/i.test(j.error || '')) signIn();
          else $('qm').textContent = j.error || 'Could not save.';
        });
      };
    }
    step();
  }

  /* ---- 3. profile ---- */
  function profile() {
    api('/api/me').then(function (m) {
      if (!m.user) return signIn();
      Promise.all([api('/api/routines'), api('/api/favorites')]).then(function (r) {
        var u = m.user, rs = r[0].routines || [], bs = r[1].brands || [];
        modal('<h3>' + esc(u.name) + '</h3><p style="margin:0;color:var(--mute)">' + esc(u.email) + '</p>' +
          '<h4>Skin type</h4><div class="xi">' + (u.skin_type ? esc(u.skin_type.charAt(0).toUpperCase() + u.skin_type.slice(1)) + ' skin' : 'Not set yet') + '</div>' +
          '<div class="xr"><button class="btn btn-out" id="pq">' + (u.skin_type ? 'Retake quiz' : 'Take the skin quiz') + '</button></div>' +
          '<h4>Saved brands (' + bs.length + ')</h4>' + (bs.length ? bs.map(function (b) { return '<div class="xi"><b>' + esc(b.name) + '</b> · ' + esc(b.tier) + '<br><small>' + esc(b.hero_product) + '</small></div>'; }).join('') : '<p class="xm">Tap ♡ on a brand card to save it.</p>') +
          '<h4>Saved routines (' + rs.length + ')</h4>' + (rs.length ? rs.map(function (x) { return '<div class="xi"><b>' + esc(x.title) + '</b>' + x.content + '</div>'; }).join('') : '<p class="xm">Save a routine from the Routine Builder or ask Mili.</p>'));
        $('pq').onclick = quiz;
      });
    });
  }

  /* ---- nav links ---- */
  var ul = document.querySelector('nav ul'), pill = ul.lastElementChild;
  [['Skin Quiz', quiz], ['Profile', profile]].forEach(function (x) {
    var li = document.createElement('li'), a = document.createElement('a');
    a.href = '#'; a.textContent = x[0]; a.onclick = function (e) { e.preventDefault(); x[1](); };
    li.appendChild(a); ul.insertBefore(li, pill);
  });

  /* ---- 4. save brands (♡) ---- */
  var saved = {};
  function decorate() {
    [].forEach.call(document.querySelectorAll('#bgrid .brand'), function (card) {
      var name = card.querySelector('h3').textContent, s = slug(name), b = document.createElement('button');
      b.className = 'hrt' + (saved[s] ? ' on' : ''); b.textContent = saved[s] ? '♥ Saved' : '♡ Save';
      b.onclick = function () {
        api('/api/favorites/' + s, saved[s] ? 'DELETE' : 'POST').then(function (j) {
          if (j.ok) { saved[s] = !saved[s]; b.className = 'hrt' + (saved[s] ? ' on' : ''); b.textContent = saved[s] ? '♥ Saved' : '♡ Save'; }
          else signIn();
        });
      };
      card.querySelector('.body').appendChild(b);
    });
  }
  var oldDraw = window.drawBrands;
  window.drawBrands = function (f) { oldDraw(f); decorate(); };
  api('/api/favorites').then(function (j) { (j.brands || []).forEach(function (b) { saved[b.slug] = true; }); window.drawBrands(''); });

  /* ---- 5. routine builder: pick a skin type, load its routine from MySQL, save it ---- */
  var curRoutineSkin = 'Oily', period = 'am', rbar = document.createElement('div'), seg = document.querySelector('#routines .seg');
  rbar.className = 'tabs'; rbar.style.cssText = 'margin-bottom:14px;justify-content:flex-start';
  seg.parentNode.insertBefore(rbar, seg);
  SK.slice().sort(function (a, b) { return ['Normal', 'Oily', 'Dry', 'Combination', 'Sensitive'].indexOf(a) - ['Normal', 'Oily', 'Dry', 'Combination', 'Sensitive'].indexOf(b); }).forEach(function (k) {
    var b = document.createElement('button'); b.className = 'tab'; b.textContent = k; b.dataset.k = k;
    b.onclick = function () { setRoutine(k); }; rbar.appendChild(b);
  });
  $('tam').addEventListener('click', function () { period = 'am'; });
  $('tpm').addEventListener('click', function () { period = 'pm'; });
  function setRoutine(k) {
    api('/api/routine-templates/' + k.toLowerCase()).then(function (j) {
      if (!j.ok) return;
      curRoutineSkin = k;
      var R = {};
      ['am', 'pm'].forEach(function (p) {
        var t = j.routines[p]; if (!t) return;
        R[p] = { sub: t.subtitle, time: t.duration, s: t.steps.map(function (x) { return [x.step_name, x.brand_name, x.duration, x.product, x.why, x.tip]; }) };
      });
      window.R = R; window.drawR(R[period] ? period : 'am');
      [].forEach.call(rbar.children, function (b) { b.setAttribute('aria-selected', b.dataset.k === k); });
      sb.textContent = '♡ Save this routine';
    });
  }
  var left = document.querySelector('#routines .rout > div'), sb = document.createElement('button');
  sb.className = 'hrt'; sb.textContent = '♡ Save this routine'; left.appendChild(sb);
  sb.onclick = function () {
    var r = window.R[period] || window.R.am;
    api('/api/routines', 'POST', {
      title: curRoutineSkin + ' skin ' + (period === 'am' ? 'morning' : 'evening') + ' routine',
      content: '<ol>' + r.s.map(function (s) { return '<li>' + esc(s[0]) + ' (' + esc(s[1]) + ') – ' + esc(s[3]) + '</li>'; }).join('') + '</ol>'
    }).then(function (j) { if (j.ok) sb.textContent = '✓ Saved to your profile'; else signIn(); });
  };
  api('/api/me').then(function (j) {
    var k = j.user && j.user.skin_type ? j.user.skin_type.charAt(0).toUpperCase() + j.user.skin_type.slice(1) : 'Oily';
    setRoutine(k);
  });
  /* "Get X Skin Routine" in the guide also switches the builder */
  $('guidebox').addEventListener('click', function (e) { if (e.target.closest('a.link')) setRoutine(curSkin()); });
})();
