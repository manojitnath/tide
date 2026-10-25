// Tide's game and bedtime rules, shared by the panel and the dashboard.
// In the app this file is added to both pages before they load; in a browser preview the pages load it themselves.
// Everything is worked out from the session log, the nights the Mac was last used (tide.nights) and a few settings (tide.game).
(function () {
  const MIN = 60e3, DAY = 864e5, MORNING = 5 * 60;   // a "night" runs until 5 AM

  const pad = n => String(n).padStart(2, '0');
  const dayStart = ts => { const d = new Date(ts); return +new Date(d.getFullYear(), d.getMonth(), d.getDate()); };
  const dayKey = ts => { const d = new Date(ts); return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`; };
  const minutesOf = ts => { const d = new Date(ts); return d.getHours() * 60 + d.getMinutes(); };
  const hhmm = s => { const [h, m] = String(s || '').split(':').map(Number); return (h || 0) * 60 + (m || 0); };
  // The night a moment belongs to: before 5 AM it's still the evening before.
  const nightKey = ts => dayKey(minutesOf(ts) < MORNING ? ts - DAY : ts);

  const DEFAULTS = {goalMin: 120, bedOn: true, bedAt: '22:00', factsAt: '22:01', nightOff: '', vacation: []};
  const settings = g => Object.assign({}, DEFAULTS, g || {}, {vacation: Array.isArray(g && g.vacation) ? g.vacation : []});

  /* ---------- bedtime ---------- */
  const isBedtime = (g, ts = Date.now()) => {
    if (!g.bedOn || g.nightOff === nightKey(ts)) return false;
    const m = minutesOf(ts); return m >= hhmm(g.bedAt) || m < MORNING;
  };
  const factsOn = (g, ts = Date.now()) => { const m = minutesOf(ts); return m >= hhmm(g.factsAt) || m < MORNING; };
  // A night counts as "lights out" when the Mac was last used within 30 minutes of bedtime.
  const lightsOutBy = g => hhmm(g.bedAt) + 30;
  const FACTS = [
    'Adults need at least 7 hours of sleep a night to stay healthy.',
    'People who sleep under 6 hours are about 4 times more likely to catch a cold.',
    'After 17 to 19 hours awake, your reactions slow as much as after a couple of drinks.',
    'Screens before bed delay your sleep hormone and leave you groggier in the morning.',
    'Deep sleep is when your brain clears out waste linked to Alzheimer’s.',
    'A single night of lost sleep raises a brain protein linked to Alzheimer’s.',
    'Short sleep raises your hunger hormone, so you crave more food the next day.',
    'Regularly sleeping too little is linked to heart disease, diabetes and depression.',
  ];

  /* ---------- goal and streak ---------- */
  function totals(logs) {
    const t = new Map();
    for (const l of logs) { const d = dayStart(l.start); t.set(d, (t.get(d) || 0) + l.ms); }
    return t;
  }
  const onVacation = (g, key) => g.vacation.some(([a, b]) => key >= a && (!b || key <= b));
  // Days that close the daily goal keep the streak; vacation days are skipped, today can still be closed.
  function streak(logs, g, now = Date.now()) {
    const t = totals(logs), goal = g.goalMin * MIN, today = dayStart(now);
    const met = d => (t.get(d) || 0) >= goal;
    const prev = d => dayStart(d - DAY / 2);
    let current = 0, d = met(today) ? today : prev(today);
    const first = logs.length ? Math.min(...logs.map(l => dayStart(l.start))) : today;
    while (d >= first) {
      if (met(d)) current++;
      else if (!onVacation(g, dayKey(d))) break;
      d = prev(d);
    }
    let best = 0, run = 0;
    for (let x = first; x <= today; x = dayStart(x + DAY * 1.5)) {
      if (met(x)) run++;
      else if (!onVacation(g, dayKey(x)) && x !== today) run = 0;
      best = Math.max(best, run);
    }
    const monday = today - ((new Date(now).getDay() + 6) % 7) * DAY;
    const week = [...Array(7)].map((_, i) => {
      const x = dayStart(monday + i * DAY + DAY / 2), ms = t.get(x) || 0;
      const state = x > today ? 'future' : ms >= goal ? 'done' : x === today ? 'now' : onVacation(g, dayKey(x)) ? 'off' : 'missed';
      return {day: x, ms, p: Math.min(1, ms / goal), state};
    });
    return {current, best, week, today: t.get(today) || 0, goal};
  }

  /* ---------- levels: 1 XP for every focused minute ---------- */
  const LEVELS = ['Drop', 'Ripple', 'Wavelet', 'Wave', 'Breaker', 'Current', 'Swell', 'Surge', 'Riptide', 'High tide', 'Spring tide', 'King tide'];
  const xpFor = n => 150 * (n - 1) * (n - 1);   // XP needed to reach level n
  function level(logs) {
    const xp = Math.floor(logs.reduce((n, l) => n + l.ms, 0) / MIN);
    let n = 1; while (xp >= xpFor(n + 1)) n++;
    const name = k => LEVELS[Math.min(k, LEVELS.length) - 1];
    return {n, name: name(n), next: name(n + 1), xp, from: xpFor(n), to: xpFor(n + 1)};
  }

  /* ---------- badges: coins with a picture each, in the style of Duolingo's ---------- */
  const shade = (c, f) => {
    const v = [1, 3, 5].map(i => parseInt(c.slice(i, i + 2), 16));
    return '#' + v.map(x => Math.round(f < 1 ? x * f : x + (255 - x) * (f - 1))).map(x => pad(Math.max(0, Math.min(255, x)).toString(16))).join('');
  };
  const star = (cx, cy, r, ri, n = 5) => [...Array(2 * n)].map((_, i) => {
    const a = (-90 + 180 * i / n) * Math.PI / 180, rr = i % 2 ? ri : r; return `${(cx + rr * Math.cos(a)).toFixed(1)},${(cy + rr * Math.sin(a)).toFixed(1)}`;
  }).join(' ');
  const Y = '#ffd36b';
  // Two-tone pictures on a 100 x 100 coin: L is a light tint of the coin's colour, D a dark one.
  const ART = {
    candle: `<rect x="42" y="44" width="16" height="28" rx="3" fill="L"/><path d="M40 72h20" stroke="D" stroke-width="4" stroke-linecap="round"/><path d="M50 26c4 5 6 8 6 11a6 6 0 0 1-12 0c0-3 2-6 6-11z" fill="${Y}"/><rect x="49" y="40" width="2" height="5" fill="D"/>`,
    lantern: `<path d="M44 26h12M50 22v4" stroke="D" stroke-width="3.5" stroke-linecap="round"/><path d="M40 32h20l-2 6H42z" fill="D"/><rect x="40" y="38" width="20" height="26" rx="4" fill="L"/><path d="M50 44c3 4 4 6 4 8a4 4 0 0 1-8 0c0-2 1-4 4-8z" fill="${Y}"/><path d="M38 64h24l-3 8H41z" fill="D"/>`,
    lighthouse: `<path d="M42 72l3-36h10l3 36z" fill="L"/><path d="M43.5 52h13l.6 7h-14.2zM44.5 40h11l.4 5h-11.8z" fill="D"/><rect x="40" y="28" width="20" height="8" rx="2" fill="${Y}"/><path d="M42 28l8-8 8 8z" fill="L"/><path d="M60 31l16-6v14zM40 31l-16-6v14z" fill="${Y}" opacity=".6"/><rect x="34" y="72" width="32" height="5" rx="2.5" fill="L"/>`,
    moontide: `<circle cx="50" cy="40" r="15" fill="${Y}"/><path d="M22 60c5 0 5-4 10-4s5 4 10 4 5-4 10-4 5 4 10 4 5-4 10-4 5 4 6 4M24 70c5 0 5-4 10-4s5 4 10 4 5-4 10-4 5 4 10 4 5-4 10-4" stroke="L" stroke-width="5" fill="none" stroke-linecap="round"/>`,
    starcrown: `<path d="M28 66l-3-24 13 11 12-17 12 17 13-11-3 24z" fill="${Y}"/><rect x="28" y="68" width="44" height="6" rx="3" fill="${Y}"/><g fill="L"><polygon points="${star(30, 28, 6, 2.6)}"/><polygon points="${star(50, 22, 7, 3)}"/><polygon points="${star(70, 28, 6, 2.6)}"/></g><circle cx="50" cy="58" r="3.5" fill="D"/>`,
    seed: '<path d="M22 66c8-6 48-6 56 0v6H22z" fill="D"/><ellipse cx="50" cy="56" rx="9" ry="12" fill="L" transform="rotate(25 50 56)"/><path d="M47 50c2 3 3 7 2 11" stroke="D" stroke-width="2" fill="none" stroke-linecap="round"/>',
    sprout: '<path d="M22 66c8-6 48-6 56 0v6H22z" fill="D"/><path d="M50 64V44" stroke="L" stroke-width="4.5" stroke-linecap="round"/><path d="M50 48c-2-10-14-14-20-10 2 8 12 12 20 10zM50 44c2-10 14-14 20-10-2 8-12 12-20 10z" fill="L"/>',
    sapling: '<path d="M22 70c8-6 48-6 56 0v4H22z" fill="D"/><path d="M50 68V34" stroke="D" stroke-width="5" stroke-linecap="round"/><path d="M50 56c-4-8-16-10-20-4 4 6 14 8 20 4zM50 46c4-8 16-10 20-4-4 6-14 8-20 4zM50 36c-3-8-12-10-16-5 3 5 11 7 16 5z" fill="L"/>',
    tree: '<rect x="46" y="54" width="8" height="18" rx="2" fill="D"/><circle cx="50" cy="40" r="17" fill="L"/><circle cx="36" cy="50" r="10" fill="L"/><circle cx="64" cy="50" r="10" fill="L"/><path d="M24 72h52" stroke="D" stroke-width="4" stroke-linecap="round"/>',
    forest: '<path d="M34 26l14 24h-6l10 16H18l10-16h-6z" fill="L"/><path d="M62 30l14 22h-6l10 16H48l10-16h-6z" fill="L" opacity=".8"/><path d="M33 66v8M63 68v6" stroke="D" stroke-width="4" stroke-linecap="round"/><path d="M20 74h60" stroke="D" stroke-width="4" stroke-linecap="round"/>',
    mountain: `<path d="M20 72l22-38 10 15 9-12 19 35z" fill="L"/><path d="M42 34l7 11-7 4-6-4z" fill="#fff"/><path d="M61 37l5 8-5 2-4-3z" fill="#fff"/><path d="M42 34V20l10 4-10 4" stroke="D" stroke-width="2.5" fill="${Y}" stroke-linejoin="round"/>`,
    paperboat: '<path d="M22 54h56l-12 16H34z" fill="L"/><path d="M36 54l14-24 14 24z" fill="L" opacity=".75"/><path d="M50 30v24M36 54l14 16 14-16" stroke="D" stroke-width="2" fill="none" stroke-linejoin="round"/><path d="M20 76c5 0 5-3 10-3s5 3 10 3 5-3 10-3 5 3 10 3 5-3 10-3 5 3 10 3" stroke="D" stroke-width="3" fill="none" stroke-linecap="round"/>',
    sailboat: '<path d="M48 22v38H26z" fill="L"/><path d="M52 30v30h18z" fill="L" opacity=".75"/><path d="M24 63h52l-8 11H32z" fill="D"/>',
    ship: `<path d="M20 58h60l-8 16H28z" fill="D"/><rect x="30" y="44" width="36" height="14" rx="2" fill="L"/><rect x="38" y="30" width="8" height="14" fill="L"/><rect x="52" y="34" width="8" height="10" fill="L"/><rect x="38" y="30" width="8" height="4" fill="${Y}"/><g fill="D"><circle cx="38" cy="51" r="2.2"/><circle cx="48" cy="51" r="2.2"/><circle cx="58" cy="51" r="2.2"/></g>`,
    globe: '<circle cx="50" cy="50" r="23" fill="D"/><path d="M34 36c6-2 10 2 12 6s-2 8 2 12-4 10-8 10c-6-4-10-14-6-28zM56 30c6 0 12 4 14 10-4 2-8 0-10 4s2 10-2 14c-4-2-6-8-4-14s-2-10 2-14z" fill="L"/><circle cx="50" cy="50" r="23" fill="none" stroke="L" stroke-width="3"/>',
    feet: '<g fill="L"><ellipse cx="40" cy="58" rx="7" ry="11"/><ellipse cx="60" cy="40" rx="7" ry="11"/><circle cx="34" cy="44" r="2.6"/><circle cx="39" cy="42" r="2.6"/><circle cx="44" cy="43" r="2.4"/><circle cx="54" cy="26" r="2.6"/><circle cx="59" cy="24" r="2.6"/><circle cx="64" cy="25" r="2.4"/></g>',
    sunrise: `<path d="M30 58a20 20 0 0 1 40 0z" fill="${Y}"/><g stroke="${Y}" stroke-width="4" stroke-linecap="round"><path d="M50 26v6M30 36l4 4M70 36l-4 4M22 52h5M73 52h5"/></g><path d="M20 62h60M28 70h44" stroke="L" stroke-width="5" stroke-linecap="round"/>`,
    helmet: `<circle cx="50" cy="48" r="22" fill="L"/><circle cx="50" cy="48" r="11" fill="D"/><circle cx="50" cy="48" r="11" fill="none" stroke="${Y}" stroke-width="3"/><path d="M47 44a5 5 0 0 1 5-2" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/><rect x="34" y="68" width="32" height="7" rx="3" fill="D"/><circle cx="31" cy="44" r="3" fill="${Y}"/><circle cx="69" cy="44" r="3" fill="${Y}"/>`,
    shoe: '<path d="M24 62c0-10 4-24 10-26 6 6 12 8 20 8 6 6 18 8 22 14v6H24z" fill="L"/><path d="M24 64h52v6a4 4 0 0 1-4 4H28a4 4 0 0 1-4-4z" fill="D"/><path d="M40 46l6-4M44 50l6-4M48 54l6-4" stroke="D" stroke-width="2.5" stroke-linecap="round"/>',
    target: `<circle cx="48" cy="52" r="22" fill="L"/><circle cx="48" cy="52" r="14" fill="D"/><circle cx="48" cy="52" r="7" fill="L"/><circle cx="48" cy="52" r="3" fill="D"/><path d="M48 52l22-22" stroke="#fff" stroke-width="3.5" stroke-linecap="round"/><path d="M70 30l-8 1 7 7z" fill="${Y}"/>`,
    wave: '<path d="M20 66c10-2 12-30 32-34 14-2 22 8 18 18-6-6-14-2-12 6 2 6 10 8 22 4v10H20z" fill="L"/><path d="M62 42c-6 0-8 6-6 10" stroke="D" stroke-width="3" fill="none" stroke-linecap="round"/>',
  };
  function coin(color, pic) {
    const d = shade(color, .68), l = shade(color, 1.55), k = shade(color, .5);
    const art = ART[pic].replace(/(fill|stroke)="L"/g, `$1="${l}"`).replace(/(fill|stroke)="D"/g, `$1="${k}"`);
    return `<svg viewBox="0 0 100 100" aria-hidden="true"><circle cx="50" cy="54" r="46" fill="${d}"/><circle cx="50" cy="50" r="46" fill="${color}"/>` +
      `<circle cx="50" cy="50" r="37" fill="${d}" opacity=".35"/>${art}` +
      `<clipPath id="coin-${pic}"><circle cx="50" cy="50" r="46"/></clipPath><path clip-path="url(#coin-${pic})" d="M8 86L80 6 96 18 24 98z" fill="#fff" opacity=".1"/></svg>`;
  }
  // [id, colour, picture, what it's for, test(facts)]
  const BADGES = [
    ['night7', '#5b6cf0', 'candle', 'Lights out · 7 nights with the laptop closed on time', f => f.nights >= 7],
    ['night30', '#4a55d8', 'lantern', 'Lights out · 30 nights', f => f.nights >= 30],
    ['night90', '#3a44bf', 'lighthouse', 'Lights out · 90 nights', f => f.nights >= 90],
    ['night180', '#2f369f', 'moontide', 'Lights out · 180 nights', f => f.nights >= 180],
    ['night365', '#262b80', 'starcrown', 'Lights out · 365 nights', f => f.nights >= 365],
    ['hours10', '#8a6a3d', 'seed', 'Focus · 10 hours', f => f.hours >= 10],
    ['hours50', '#5aa64a', 'sprout', 'Focus · 50 hours', f => f.hours >= 50],
    ['hours100', '#3f9a46', 'sapling', 'Focus · 100 hours', f => f.hours >= 100],
    ['hours250', '#2f8a43', 'tree', 'Focus · 250 hours', f => f.hours >= 250],
    ['hours500', '#21733a', 'forest', 'Focus · 500 hours', f => f.hours >= 500],
    ['hours1000', '#5a6a86', 'mountain', 'Focus · 1,000 hours', f => f.hours >= 1000],
    ['streak7', '#3aa6d6', 'paperboat', 'Streak · 7 days', f => f.best >= 7],
    ['streak30', '#2a8fc4', 'sailboat', 'Streak · 30 days', f => f.best >= 30],
    ['streak100', '#1f74a8', 'ship', 'Streak · 100 days', f => f.best >= 100],
    ['streak365', '#185a8a', 'globe', 'Streak · 365 days', f => f.best >= 365],
    ['first', '#e0a23a', 'feet', 'First steps · your first session', f => f.sessions >= 1],
    ['early', '#ff7a3d', 'sunrise', 'Early bird · a session started before 7 AM', f => f.early],
    ['deep', '#1fa99b', 'helmet', 'Deep diver · a full 90-minute session', f => f.longest >= 90 * MIN],
    ['marathon', '#e8336b', 'shoe', 'Marathon · 6 hours of focus in one day', f => f.bestDay >= 6 * 60 * MIN],
    ['goals', '#8a5cf6', 'target', 'Goal getter · your daily goal reached on 25 days', f => f.goalDays >= 25],
    ['hightide', '#1f5cf2', 'wave', 'High tide · reach level 10', f => f.level >= 10],
  ];
  function badges(logs, nights, g) {
    const t = totals(logs), by = lightsOutBy(g);
    const facts = {
      nights: Object.values(nights || {}).filter(v => v <= by).length,
      hours: logs.reduce((n, l) => n + l.ms, 0) / 36e5,
      best: streak(logs, g).best,
      sessions: logs.length,
      early: logs.some(l => { const m = minutesOf(l.start); return m >= 4 * 60 && m < 7 * 60; }),
      longest: Math.max(0, ...logs.map(l => l.ms)),
      bestDay: Math.max(0, ...t.values()),
      goalDays: [...t.values()].filter(ms => ms >= g.goalMin * MIN).length,
      level: level(logs).n,
    };
    return BADGES.map(([id, color, pic, tip, test]) => ({id, tip, art: coin(color, pic), got: !!test(facts)}));
  }

  const greeting = (name, ts = Date.now(), bed = false) => {
    const h = new Date(ts).getHours();
    const part = bed ? 'Good night' : h < 5 ? 'Good night' : h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return name ? `${part}, ${name}` : part;
  };

  window.Game = {MIN, DAY, dayStart, dayKey, nightKey, hhmm, settings, isBedtime, factsOn, lightsOutBy, FACTS, streak, level, badges, greeting, onVacation};
})();
