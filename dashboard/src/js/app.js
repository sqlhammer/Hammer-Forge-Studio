/**
 * app.js — Hammer Forge Studio Dashboard
 *
 * Core data loading module. Fetches pre-baked JSON from the data/ directory
 * and coordinates rendering. Structured so that additional rendering modules
 * (TICKET-0193 through TICKET-0196) can register render functions without
 * modifying this core loader.
 */

/* ── Configuration ────────────────────────────────────────────────────────── */

const DATA_BASE = "data/";

const DATA_FILES = {
  milestones: DATA_BASE + "milestones.json",
  tickets: DATA_BASE + "tickets.json",
  phases: DATA_BASE + "phases.json",
  dependencies: DATA_BASE + "dependencies.json",
};

/* ── Global Data Store ────────────────────────────────────────────────────── */

const DashboardData = {
  milestones: null,
  tickets: null,
  phases: null,
  dependencies: null,
  diagrams: {},
};

/* ── Render Registry ──────────────────────────────────────────────────────── */
/*
 * External modules can register render functions via:
 *   Dashboard.registerRenderer("name", renderFn)
 *
 * renderFn receives (DashboardData, containerElement) and is called after
 * all data is loaded.
 */

const renderRegistry = [];

/* ── Public API ───────────────────────────────────────────────────────────── */

const Dashboard = {
  data: DashboardData,

  registerRenderer: function (name, fn) {
    renderRegistry.push({ name: name, fn: fn });
  },

  getData: function (key) {
    return DashboardData[key];
  },
};

/* ── Data Loading ─────────────────────────────────────────────────────────── */

async function fetchJSON(url) {
  try {
    var response = await fetch(url);
    if (!response.ok) throw new Error("HTTP " + response.status);
    return await response.json();
  } catch (err) {
    console.warn("Failed to fetch " + url + ": " + err.message);
    return null;
  }
}

async function loadAllData() {
  var results = await Promise.all([
    fetchJSON(DATA_FILES.milestones),
    fetchJSON(DATA_FILES.tickets),
    fetchJSON(DATA_FILES.phases),
    fetchJSON(DATA_FILES.dependencies),
  ]);

  DashboardData.milestones = results[0];
  DashboardData.tickets = results[1];
  DashboardData.phases = results[2];
  DashboardData.dependencies = results[3];
}

/* ── Status Badge Helper ──────────────────────────────────────────────────── */

function statusBadge(status) {
  var cls = "badge badge-" + status.toLowerCase().replace(/\s+/g, "-");
  return '<span class="' + cls + '">' + escapeHtml(status) + "</span>";
}

function escapeHtml(str) {
  var div = document.createElement("div");
  div.appendChild(document.createTextNode(str));
  return div.innerHTML;
}

/* ── Progress Bar Helper ──────────────────────────────────────────────────── */

function progressBar(pct) {
  return (
    '<div class="progress-bar">' +
    '<div class="progress-fill" style="width:' + pct + '%"></div>' +
    "</div>" +
    '<div class="progress-label">' + pct + "%</div>"
  );
}

/* ── Navigation ───────────────────────────────────────────────────────────── */

function initNavigation() {
  document.querySelectorAll(".nav-link").forEach(function (link) {
    link.addEventListener("click", function (e) {
      e.preventDefault();
      var section = this.getAttribute("data-section");
      navigateTo(section, this.textContent);
    });
  });
}

function navigateTo(sectionId, title) {
  // Update active nav link
  document.querySelectorAll(".nav-link").forEach(function (link) {
    link.classList.remove("active");
    if (link.getAttribute("data-section") === sectionId) {
      link.classList.add("active");
    }
  });

  // Show target section, hide others
  document.querySelectorAll(".section").forEach(function (s) {
    s.classList.remove("active");
  });

  var target = document.getElementById("section-" + sectionId);
  if (target) {
    target.classList.add("active");
  }

  // Update header title
  if (title) {
    document.getElementById("content-title").textContent = title;
  }
}

/* ── Render: Overview ─────────────────────────────────────────────────────── */

function renderOverview() {
  var milestones = DashboardData.milestones;
  var tickets = DashboardData.tickets;

  if (!milestones) {
    document.getElementById("milestones-grid").innerHTML =
      '<p class="no-data">No data available — run <code>python dashboard/build.py</code> to generate.</p>';
    return;
  }

  // Milestone cards
  var grid = document.getElementById("milestones-grid");
  var html = "";
  milestones.forEach(function (ms) {
    html +=
      '<div class="card">' +
      "<h3>" + escapeHtml(ms.id + " — " + ms.name) + "</h3>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">Status</span>' +
      statusBadge(ms.status) +
      "</div>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">Tickets</span>' +
      '<span class="card-stat-value">' + ms.done + " / " + ms.total + "</span>" +
      "</div>" +
      progressBar(ms.completion_pct) +
      '<div class="card-stat">' +
      '<span class="card-stat-label">Open</span>' +
      '<span class="card-stat-value">' + ms.open + "</span>" +
      "</div>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">In Progress</span>' +
      '<span class="card-stat-value">' + ms.in_progress + "</span>" +
      "</div>" +
      "</div>";
  });
  grid.innerHTML = html;

  // Tickets summary
  if (tickets) {
    var total = tickets.length;
    var done = tickets.filter(function (t) { return t.status === "DONE"; }).length;
    var inProg = tickets.filter(function (t) { return t.status === "IN_PROGRESS"; }).length;
    var open = total - done - inProg;

    document.getElementById("tickets-summary-content").innerHTML =
      '<div class="card-stat">' +
      '<span class="card-stat-label">Total Tickets</span>' +
      '<span class="card-stat-value">' + total + "</span>" +
      "</div>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">Done</span>' +
      '<span class="card-stat-value" style="color:var(--status-done)">' + done + "</span>" +
      "</div>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">In Progress</span>' +
      '<span class="card-stat-value" style="color:var(--status-in-progress)">' + inProg + "</span>" +
      "</div>" +
      '<div class="card-stat">' +
      '<span class="card-stat-label">Open</span>' +
      '<span class="card-stat-value" style="color:var(--status-open)">' + open + "</span>" +
      "</div>" +
      progressBar(total > 0 ? Math.round((done / total) * 100) : 0);
  }
}

/* ── Render: Sidebar Milestones ───────────────────────────────────────────── */

function renderSidebarMilestones() {
  var milestones = DashboardData.milestones;
  var navList = document.getElementById("nav-milestones");

  if (!milestones || milestones.length === 0) {
    navList.innerHTML = '<li class="nav-placeholder">No milestones</li>';
    return;
  }

  var html = "";
  milestones.forEach(function (ms) {
    html +=
      "<li>" +
      '<a href="#ms-' + ms.id + '" class="nav-link" data-section="milestones" ' +
      'data-milestone="' + escapeHtml(ms.id) + '">' +
      escapeHtml(ms.id + " — " + ms.name) +
      "</a></li>";
  });
  navList.innerHTML = html;

  // Bind click handlers for milestone detail views
  navList.querySelectorAll(".nav-link").forEach(function (link) {
    link.addEventListener("click", function (e) {
      e.preventDefault();
      var msId = this.getAttribute("data-milestone");
      navigateTo("milestones", this.textContent);
      renderMilestoneDetail(msId);
    });
  });
}

/* ── Render: Milestone Detail ─────────────────────────────────────────────── */

function renderMilestoneDetail(msId) {
  var container = document.getElementById("milestone-detail");
  var milestones = DashboardData.milestones;
  var tickets = DashboardData.tickets;
  var phases = DashboardData.phases;

  if (!milestones || !tickets) {
    container.innerHTML = '<p class="no-data">No data available</p>';
    return;
  }

  var ms = milestones.find(function (m) { return m.id === msId; });
  if (!ms) {
    container.innerHTML = '<p class="no-data">Milestone not found</p>';
    return;
  }

  var msTickets = tickets.filter(function (t) { return t.milestone === msId; });
  var msPhases = phases ? phases.filter(function (p) { return p.milestone === msId; }) : [];

  var html =
    '<div class="card" style="margin-bottom:1.25rem">' +
    "<h3>" + escapeHtml(ms.id + " — " + ms.name) + " " + statusBadge(ms.status) + "</h3>" +
    '<div class="card-stat">' +
    '<span class="card-stat-label">Completion</span>' +
    '<span class="card-stat-value">' + ms.completion_pct + "%</span>" +
    "</div>" +
    progressBar(ms.completion_pct) +
    '<div class="card-stat">' +
    '<span class="card-stat-label">Target Date</span>' +
    '<span class="card-stat-value">' + (ms.target_date || "—") + "</span>" +
    "</div>" +
    "</div>";

  // Phase breakdown
  if (msPhases.length > 0) {
    html += '<div class="card" style="margin-bottom:1.25rem"><h3>Phases</h3>';
    msPhases.forEach(function (phase) {
      var phasePct = phase.total > 0 ? Math.round((phase.done / phase.total) * 100) : 0;
      html +=
        '<div style="margin-bottom:0.75rem">' +
        '<div class="card-stat">' +
        '<span class="card-stat-label">' + escapeHtml(phase.phase) + "</span>" +
        '<span class="card-stat-value">' + phase.done + "/" + phase.total +
        (phase.gate_passed ? ' <span class="badge badge-done">GATE PASSED</span>' : "") +
        "</span></div>" +
        progressBar(phasePct) +
        "</div>";
    });
    html += "</div>";
  }

  // Tickets table
  html +=
    '<div class="card"><h3>Tickets</h3>' +
    '<table class="data-table"><thead><tr>' +
    "<th>ID</th><th>Title</th><th>Status</th><th>Owner</th><th>Priority</th>" +
    "</tr></thead><tbody>";

  msTickets.forEach(function (t) {
    html +=
      "<tr>" +
      "<td>" + escapeHtml(t.id) + "</td>" +
      "<td>" + escapeHtml(t.title) + "</td>" +
      "<td>" + statusBadge(t.status) + "</td>" +
      "<td>" + escapeHtml(t.owner) + "</td>" +
      "<td>" + escapeHtml(t.priority) + "</td>" +
      "</tr>";
  });

  html += "</tbody></table></div>";
  container.innerHTML = html;
}

/* ── Render: Diagrams ─────────────────────────────────────────────────────── */

async function renderDiagrams() {
  var container = document.getElementById("diagrams-container");
  var milestones = DashboardData.milestones;

  if (!milestones || milestones.length === 0) {
    container.innerHTML = '<p class="no-data">No data available</p>';
    return;
  }

  // Test diagram to verify Mermaid integration
  var html =
    '<div class="diagram-block">' +
    "<h4>Mermaid Integration Test</h4>" +
    '<div class="mermaid">graph LR\n' +
    "    A[Dashboard Scaffold] --> B[Data Parser]\n" +
    "    B --> C[Milestone View]\n" +
    "    B --> D[Ticket Board]\n" +
    "    B --> E[Dependency Graph]\n" +
    "    B --> F[Build Integration]\n" +
    '    style A fill:#28a745,color:#fff\n' +
    '    style B fill:#28a745,color:#fff\n' +
    '    style C fill:#6c757d,color:#fff\n' +
    '    style D fill:#6c757d,color:#fff\n' +
    '    style E fill:#6c757d,color:#fff\n' +
    '    style F fill:#6c757d,color:#fff\n' +
    "</div></div>";

  // Load per-milestone .mmd diagrams
  for (var i = 0; i < milestones.length; i++) {
    var ms = milestones[i];
    var mmdUrl = DATA_BASE + "diagrams/" + ms.id + ".mmd";
    try {
      var resp = await fetch(mmdUrl);
      if (resp.ok) {
        var mmdContent = await resp.text();
        DashboardData.diagrams[ms.id] = mmdContent;
        html +=
          '<div class="diagram-block">' +
          "<h4>" + escapeHtml(ms.id + " — " + ms.name) + " Dependencies</h4>" +
          '<div class="mermaid">' + escapeHtml(mmdContent) + "</div>" +
          "</div>";
      }
    } catch (err) {
      // Diagram not available for this milestone — skip silently
    }
  }

  container.innerHTML = html;

  // Re-initialize Mermaid to render newly added diagrams
  if (typeof mermaid !== "undefined") {
    mermaid.contentLoaded();
  }
}

/* ── Architecture Diagrams — TICKET-0196 ─────────────────────────────────── */
/*
 * Hand-curated architecture diagrams sourced from dashboard/diagrams/*.mmd.
 * build.py copies them to dashboard/dist/data/architecture/ for the static
 * site to fetch. Each entry maps to a file in that directory.
 */

var ARCHITECTURE_DIAGRAMS = [
  {
    id: "game-core-loop",
    title: "Game Core Loop",
    description: "The main gameplay loop: Land on a planet, scan the area, mine surface or deep nodes, return to the ship to recycle or fabricate, upgrade systems via the Tech Tree, then travel to the next destination.",
  },
  {
    id: "system-architecture",
    title: "System Architecture",
    description: "Autoload singletons, scene hierarchy (Main → Ship/Biome → Player), and key data flows between game systems (Inventory, FuelSystem, NavigationSystem, DepositRegistry, and more).",
  },
  {
    id: "agent-orchestration-flow",
    title: "Agent Orchestration Flow",
    description: "Producer → Conductor → parallel worker agents dispatch via worktrees. Shows ticket lifecycle (OPEN → IN_PROGRESS → DONE) and phase gate checkpoints requiring Studio Head approval.",
  },
];

async function loadArchitectureDiagrams() {
  var container = document.getElementById("architecture-diagrams-container");
  if (!container) return;

  var html = "";
  var loaded = 0;

  for (var i = 0; i < ARCHITECTURE_DIAGRAMS.length; i++) {
    var diagram = ARCHITECTURE_DIAGRAMS[i];
    var url = DATA_BASE + "architecture/" + diagram.id + ".mmd";
    try {
      var resp = await fetch(url);
      if (resp.ok) {
        var mmdContent = await resp.text();
        html +=
          '<div class="diagram-block">' +
          "<h4>" + escapeHtml(diagram.title) + "</h4>" +
          "<p>" + escapeHtml(diagram.description) + "</p>" +
          '<div class="mermaid">' + escapeHtml(mmdContent) + "</div>" +
          "</div>";
        loaded++;
      }
    } catch (err) {
      // Diagram not available — skip silently
    }
  }

  if (loaded === 0) {
    container.innerHTML =
      '<p class="no-data">No architecture diagrams found — run <code>python dashboard/build.py</code> to copy them to dist.</p>';
    return;
  }

  container.innerHTML = html;

  if (typeof mermaid !== "undefined") {
    mermaid.contentLoaded();
  }
}

/* ── Render: Build Timestamp ──────────────────────────────────────────────── */

function renderBuildTimestamp() {
  var el = document.getElementById("last-build");
  el.textContent = "Last build: " + new Date().toLocaleString();
}

/* ── Mermaid Initialization ───────────────────────────────────────────────── */

function initMermaid() {
  if (typeof mermaid !== "undefined") {
    mermaid.initialize({
      startOnLoad: true,
      theme: "dark",
      securityLevel: "loose",
      flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
      },
    });
  } else {
    console.warn("Mermaid.js not loaded — diagrams will not render.");
  }
}

/* ── Registered Renderers ─────────────────────────────────────────────────── */

function runRegisteredRenderers() {
  renderRegistry.forEach(function (entry) {
    try {
      entry.fn(DashboardData, document.querySelector(".content"));
    } catch (err) {
      console.error("Renderer '" + entry.name + "' failed:", err);
    }
  });
}

/* ── Bootstrap ────────────────────────────────────────────────────────────── */

async function init() {
  initMermaid();
  initNavigation();
  renderBuildTimestamp();

  await loadAllData();

  renderOverview();
  renderSidebarMilestones();
  await renderDiagrams();
  await loadArchitectureDiagrams(); // TICKET-0196
  runRegisteredRenderers();
}

// Expose public API for external modules
window.Dashboard = Dashboard;

// Start the app
document.addEventListener("DOMContentLoaded", init);
