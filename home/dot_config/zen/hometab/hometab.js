// tick() must stay the only timer: tools/hometab.test.mjs holds it to that.

const HOUR = 3600000;
// j2, not a text format: wttr.in wraps text answers in an HTML page for any
// browser, and j2 is its smallest JSON (3 KB, no hourly forecast).
const WEATHER = "https://wttr.in/G%C3%B6lc%C3%BCk,Kocaeli?format=j2";
const $ = id => document.getElementById(id);
const pad = n => String(n).padStart(2, "0");

// isoWeek and greeting are copies of Calc.mjs, which the Desk uses and
// calc.test.mjs checks. hometab.test.mjs fails if a copy drifts.
function isoWeek(d) {
    const thu = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7);
    const jan1 = new Date(thu.getFullYear(), 0, 1);
    // Round before dividing: a DST boundary in between leaves the raw
    // millisecond gap an hour short of a whole number of days.
    return Math.floor(Math.round((thu - jan1) / 86400000) / 7) + 1;
}

function greeting(h) {
    return h < 5 ? "night" : h < 12 ? "morning" : h < 18 ? "afternoon" : "evening";
}

// Text only: wttr.in's icons are colour emoji.
function drawWeather() {
    const [temp, sky] = (localStorage.getItem("weather") ?? "").split("|");
    $("weather").textContent = sky ? `${temp} · ${sky}` : "";
}

function weather(now) {
    if (now - Number(localStorage.getItem("weatherAt")) < HOUR)
        return;
    // Stamped before the request, so a pending or failed one counts too: offline,
    // or with several hometabs open, it is still one request an hour.
    localStorage.setItem("weatherAt", now);
    fetch(WEATHER)
        .then(r => (r.ok ? r.json() : Promise.reject(r.status)))
        .then(j => {
            const c = j.current_condition[0];
            localStorage.setItem("weather", `${c.temp_C}°|${c.weatherDesc[0].value}`);
            drawWeather();
        })
        .catch(() => {});
}

function tick() {
    const now = Date.now();
    const d = new Date(now);
    const name = opt => d.toLocaleDateString("en-GB", opt);
    $("time").textContent = `${pad(d.getHours())}:${pad(d.getMinutes())}`;
    $("date").textContent = `${name({ weekday: "long" })} · ${d.getDate()} ${name({ month: "long" })} · week ${isoWeek(d)}`;
    $("greeting").textContent = `Good ${greeting(d.getHours())},`;
    drawWeather();
    weather(now);
    setTimeout(tick, 60000 - now % 60000);
}

tick();
