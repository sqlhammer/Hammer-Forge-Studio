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

/* ── Phase Gate Helpers ───────────────────────────────────────────────────── */

/**
 * Compute phase status from phase ticket data.
 * Returns "passed" | "in-progress" | "pending".
 */
function computePhaseStatus(phase) {
  if (phase.total === 0) return "pending";
  if (phase.done === phase.total) return "passed";
  if (phase.done > 0 || phase.in_progress > 0) return "in-progress";
  return "pending";
}

/**
 * Render phase gate indicator dots for a milestone's phases.
 */
function renderPhaseIndicators(msId) {
  var phases = DashboardData.phases;
  if (!phases) return "";

  var msPhases = phases.filter(function (p) { return p.milestone === msId; });
  if (msPhases.length === 0) return "";

  var html = '<div class="phase-indicators">';
  msPhases.forEach(function (phase) {
    var status = computePhaseStatus(phase);
    var title = escapeHtml(phase.phase) + " — " + phase.done + "/" + phase.total;
    html +=
      '<span class="phase-dot phase-dot-' + status + '" title="' + title + '">' +
      "</span>" +
      '<span class="phase-dot-label">' + escapeHtml(phase.phase) + "</span>";
  });
  html += "</div>";
  return html;
}

/* ── Milestone Card Builder ──────────────────────────────────────────────── */

function buildMilestoneCard(ms) {
  var isActive = ms.status === "Active";
  var cardClass = "card milestone-card" + (isActive ? " milestone-active" : "");
  var pct = Math.round(ms.completion_pct);

  return (
    '<div class="' + cardClass + '" data-milestone-id="' + escapeHtml(ms.id) + '">' +
    "<h3>" + escapeHtml(ms.id + " — " + ms.name) + " " + statusBadge(ms.status) + "</h3>" +
    '<div class="card-stat">' +
    '<span class="card-stat-label">Tickets</span>' +
    '<span class="card-stat-value">' + ms.done + " / " + ms.total + "</span>" +
    "</div>" +
    progressBar(pct) +
    '<div class="card-stat">' +
    '<span class="card-stat-label">Open</span>' +
    '<span class="card-stat-value">' + ms.open + "</span>" +
    "</div>" +
    '<div class="card-stat">' +
    '<span class="card-stat-label">In Progress</span>' +
    '<span class="card-stat-value">' + ms.in_progress + "</span>" +
    "</div>" +
    renderPhaseIndicators(ms.id) +
    "</div>"
  );
}

/* ── Status Group Builder ────────────────────────────────────────────────── */

function buildStatusGroup(label, milestones, collapsed) {
  if (milestones.length === 0) return "";

  var collapsedClass = collapsed ? " collapsed" : "";
  var html =
    '<div class="status-group' + collapsedClass + '">' +
    '<div class="status-group-header">' +
    '<span class="status-group-toggle">' + (collapsed ? "+" : "-") + "</span>" +
    '<span class="status-group-label">' + escapeHtml(label) + "</span>" +
    '<span class="status-group-count">' + milestones.length + "</span>" +
    "</div>" +
    '<div class="status-group-body">' +
    '<div class="card-grid">';

  milestones.forEach(function (ms) {
    html += buildMilestoneCard(ms);
  });

  html += "</div></div></div>";
  return html;
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

  // Group milestones by status: Active, Planning, Complete
  var active = milestones.filter(function (ms) { return ms.status === "Active"; });
  var planning = milestones.filter(function (ms) { return ms.status === "Planning"; });
  var complete = milestones.filter(function (ms) { return ms.status === "Complete"; });

  var grid = document.getElementById("milestones-grid");
  var html = "";
  html += buildStatusGroup("Active", active, false);
  html += buildStatusGroup("Planning", planning, false);
  html += buildStatusGroup("Complete", complete, true);
  grid.innerHTML = html;

  // Bind collapse/expand toggle on status group headers
  grid.querySelectorAll(".status-group-header").forEach(function (header) {
    header.addEventListener("click", function () {
      var group = this.parentElement;
      var toggle = this.querySelector(".status-group-toggle");
      group.classList.toggle("collapsed");
      toggle.textContent = group.classList.contains("collapsed") ? "+" : "-";
    });
  });

  // Bind click handlers on milestone cards — placeholder for TICKET-0194
  grid.querySelectorAll(".milestone-card").forEach(function (card) {
    card.addEventListener("click", function () {
      var msId = this.getAttribute("data-milestone-id");
      navigateTo("milestones", msId);
      renderMilestoneDetail(msId);
    });
  });

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

/* ── Render: Milestone Detail — TICKET-0194 ──────────────────────────────── */

/**
 * Look up the milestone ID for a given ticket ID by scanning all tickets.
 * Returns the milestone string or null if not found.
 */
function findTicketMilestone(ticketId) {
  var tickets = DashboardData.tickets;
  if (!tickets) return null;
  var t = tickets.find(function (tk) { return tk.id === ticketId; });
  return t ? t.milestone : null;
}

/**
 * Build a dependency cell value. Shows each dependency ticket ID; if the
 * dependency belongs to a different milestone, prefixes with "MS: ".
 * Each ID is a clickable link that scrolls to / highlights the target row.
 */
function renderDependencyCell(depends, currentMilestone) {
  if (!depends || depends.length === 0) return '<span class="text-muted">—</span>';

  var parts = [];
  depends.forEach(function (depId) {
    var depMs = findTicketMilestone(depId);
    var label = depId;
    if (depMs && depMs !== currentMilestone) {
      label = depMs + ": " + depId;
    }
    parts.push(
      '<a href="#" class="dep-link" data-dep-ticket="' + escapeHtml(depId) + '">' +
      escapeHtml(label) + "</a>"
    );
  });
  return parts.join(", ");
}

/**
 * Sort tickets by ID string (natural sort on the numeric suffix).
 */
function sortTicketsById(tickets) {
  return tickets.slice().sort(function (a, b) {
    var numA = parseInt(a.id.replace(/\D+/g, ""), 10) || 0;
    var numB = parseInt(b.id.replace(/\D+/g, ""), 10) || 0;
    return numA - numB;
  });
}

/**
 * Build the ticket table rows for a set of tickets.
 */
function buildTicketRows(tickets, milestoneId) {
  var html = "";
  tickets.forEach(function (t) {
    html +=
      '<tr id="ticket-row-' + escapeHtml(t.id) + '" class="ticket-row">' +
      '<td class="ticket-id">' + escapeHtml(t.id) + "</td>" +
      '<td class="ticket-title" title="' + escapeHtml(t.title) + '">' +
      '<span class="title-truncate">' + escapeHtml(t.title) + "</span></td>" +
      "<td>" + statusBadge(t.status) + "</td>" +
      "<td>" + escapeHtml(t.owner) + "</td>" +
      "<td>" + escapeHtml(t.phase || "—") + "</td>" +
      "<td>" + renderDependencyCell(t.depends_on, milestoneId) + "</td>" +
      "</tr>";
  });
  return html;
}

/**
 * Build the standard ticket table header row.
 */
function ticketTableHeader() {
  return (
    '<table class="data-table ticket-detail-table"><thead><tr>' +
    "<th>Ticket ID</th><th>Title</th><th>Status</th><th>Owner</th><th>Phase</th><th>Dependencies</th>" +
    "</tr></thead><tbody>"
  );
}

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

  // Compute per-status counts from actual ticket data
  var countDone = msTickets.filter(function (t) { return t.status === "DONE"; }).length;
  var countInProgress = msTickets.filter(function (t) { return t.status === "IN_PROGRESS"; }).length;
  var countOpen = msTickets.length - countDone - countInProgress;
  var pct = msTickets.length > 0 ? Math.round((countDone / msTickets.length) * 100) : 0;

  /* ── Summary Header ──────────────────────────────────────────────────── */
  var html =
    '<div class="card detail-summary-card">' +
    '<div class="detail-summary-header">' +
    "<h3>" + escapeHtml(ms.id + " — " + ms.name) + " " + statusBadge(ms.status) + "</h3>" +
    "</div>" +
    '<div class="detail-summary-counts">' +
    '<div class="summary-stat">' +
    '<span class="summary-stat-value">' + msTickets.length + "</span>" +
    '<span class="summary-stat-label">Total</span></div>' +
    '<div class="summary-stat">' +
    '<span class="summary-stat-value" style="color:var(--status-done)">' + countDone + "</span>" +
    '<span class="summary-stat-label">Done</span></div>' +
    '<div class="summary-stat">' +
    '<span class="summary-stat-value" style="color:var(--status-in-progress)">' + countInProgress + "</span>" +
    '<span class="summary-stat-label">In Progress</span></div>' +
    '<div class="summary-stat">' +
    '<span class="summary-stat-value" style="color:var(--status-open)">' + countOpen + "</span>" +
    '<span class="summary-stat-label">Open</span></div>' +
    "</div>" +
    progressBar(pct) +
    "</div>";

  /* ── No Tickets Edge Case ────────────────────────────────────────────── */
  if (msTickets.length === 0) {
    html += '<div class="card"><p class="no-data">No tickets found</p></div>';
    container.innerHTML = html;
    return;
  }

  /* ── Phase-Grouped Ticket Tables ─────────────────────────────────────── */
  if (msPhases.length > 0) {
    msPhases.forEach(function (phase) {
      var phaseTickets = sortTicketsById(
        msTickets.filter(function (t) { return t.phase === phase.phase; })
      );
      if (phaseTickets.length === 0) return;

      var phaseStatus = computePhaseStatus(phase);
      var phasePct = phase.total > 0 ? Math.round((phase.done / phase.total) * 100) : 0;
      var isAllDone = phase.done === phase.total && phase.total > 0;

      html +=
        "<details" + (isAllDone ? "" : " open") + ' class="phase-group">' +
        "<summary>" +
        '<span class="phase-group-name">' + escapeHtml(phase.phase) + "</span>" +
        '<span class="phase-group-stats">' +
        phase.done + "/" + phase.total +
        (phase.gate_passed ? ' <span class="badge badge-done">GATE PASSED</span>' : "") +
        "</span>" +
        '<span class="phase-group-bar">' + progressBar(phasePct) + "</span>" +
        "</summary>" +
        '<div class="phase-group-body">' +
        ticketTableHeader() +
        buildTicketRows(phaseTickets, msId) +
        "</tbody></table></div></details>";
    });

    // Tickets without a matching phase (orphans)
    var phasedNames = msPhases.map(function (p) { return p.phase; });
    var orphans = sortTicketsById(
      msTickets.filter(function (t) {
        return !t.phase || phasedNames.indexOf(t.phase) === -1;
      })
    );
    if (orphans.length > 0) {
      html +=
        '<details open class="phase-group">' +
        "<summary>" +
        '<span class="phase-group-name">Unassigned Phase</span>' +
        '<span class="phase-group-stats">' + orphans.length + " tickets</span>" +
        "</summary>" +
        '<div class="phase-group-body">' +
        ticketTableHeader() +
        buildTicketRows(orphans, msId) +
        "</tbody></table></div></details>";
    }
  } else {
    // No phase data — render a single flat table
    var sorted = sortTicketsById(msTickets);
    html +=
      '<div class="card">' +
      ticketTableHeader() +
      buildTicketRows(sorted, msId) +
      "</tbody></table></div>";
  }

  // Dependency graph diagram — collapsible section
  html +=
    '<div class="card" style="margin-bottom:1.25rem">' +
    '<div class="diagram-toggle" id="diagram-toggle-' + escapeHtml(msId) + '">' +
    '<span class="diagram-toggle-icon">+</span> Show Dependency Graph' +
    "</div>" +
    '<div class="diagram-collapsible collapsed" id="diagram-container-' + escapeHtml(msId) + '">' +
    '<div class="diagram-content" id="diagram-content-' + escapeHtml(msId) + '">' +
    '<p class="no-data">Loading diagram...</p>' +
    "</div></div></div>";

  container.innerHTML = html;

  /* ── Bind dependency link click handlers ──────────────────────────────── */
  container.querySelectorAll(".dep-link").forEach(function (link) {
    link.addEventListener("click", function (e) {
      e.preventDefault();
      var depId = this.getAttribute("data-dep-ticket");
      var targetRow = document.getElementById("ticket-row-" + depId);

      // Remove any previous highlight
      container.querySelectorAll(".ticket-row-highlight").forEach(function (el) {
        el.classList.remove("ticket-row-highlight");
      });

      if (targetRow) {
        // Ticket is in the current milestone view — scroll and highlight
        // Expand parent <details> if collapsed
        var parentDetails = targetRow.closest("details");
        if (parentDetails && !parentDetails.open) {
          parentDetails.open = true;
        }
        targetRow.scrollIntoView({ behavior: "smooth", block: "center" });
        targetRow.classList.add("ticket-row-highlight");
        setTimeout(function () {
          targetRow.classList.remove("ticket-row-highlight");
        }, 2000);
      } else {
        // Ticket is in a different milestone — navigate there
        var depMs = findTicketMilestone(depId);
        if (depMs) {
          navigateTo("milestones", depMs);
          renderMilestoneDetail(depMs);
          // After re-render, try to scroll to the ticket
          setTimeout(function () {
            var row = document.getElementById("ticket-row-" + depId);
            if (row) {
              var pd = row.closest("details");
              if (pd && !pd.open) pd.open = true;
              row.scrollIntoView({ behavior: "smooth", block: "center" });
              row.classList.add("ticket-row-highlight");
              setTimeout(function () {
                row.classList.remove("ticket-row-highlight");
              }, 2000);
            }
          }, 100);
        }
      }
    });
  });

  // Bind toggle handler for the dependency graph
  var toggle = document.getElementById("diagram-toggle-" + msId);
  var collapsible = document.getElementById("diagram-container-" + msId);
  if (toggle && collapsible) {
    toggle.addEventListener("click", function () {
      var icon = toggle.querySelector(".diagram-toggle-icon");
      var isCollapsed = collapsible.classList.contains("collapsed");
      collapsible.classList.toggle("collapsed");
      icon.textContent = isCollapsed ? "-" : "+";
      toggle.childNodes[1].textContent = isCollapsed
        ? " Hide Dependency Graph"
        : " Show Dependency Graph";
      // Load and render diagram on first open
      if (isCollapsed) {
        loadMilestoneDiagram(msId);
      }
    });
  }
}

/* ── Load Milestone Diagram (inline in detail view) ──────────────────────── */

var diagramRenderCounter = 0;

async function loadMilestoneDiagram(msId) {
  var contentEl = document.getElementById("diagram-content-" + msId);
  if (!contentEl) return;

  // Check cache first
  var mmdContent = DashboardData.diagrams[msId];
  if (!mmdContent) {
    // Fetch the .mmd file
    var mmdUrl = DATA_BASE + "diagrams/" + msId + ".mmd";
    try {
      var resp = await fetch(mmdUrl);
      if (!resp.ok) {
        contentEl.innerHTML =
          '<p class="no-data">No dependency diagram available for this milestone.</p>';
        return;
      }
      mmdContent = await resp.text();
      DashboardData.diagrams[msId] = mmdContent;
    } catch (err) {
      contentEl.innerHTML =
        '<p class="no-data">Failed to load diagram.</p>';
      return;
    }
  }

  // Use a unique ID for the Mermaid container to avoid conflicts on re-render
  diagramRenderCounter++;
  var mermaidId = "mermaid-ms-" + msId + "-" + diagramRenderCounter;
  contentEl.innerHTML =
    '<div class="mermaid-diagram-wrapper">' +
    '<pre class="mermaid" id="' + mermaidId + '">' +
    escapeHtml(mmdContent) +
    "</pre></div>";

  // Render the diagram via Mermaid
  if (typeof mermaid !== "undefined") {
    try {
      await mermaid.run({ nodes: [document.getElementById(mermaidId)] });
    } catch (err) {
      console.warn("Mermaid render failed for " + msId + ":", err);
      contentEl.innerHTML =
        '<p class="no-data">Diagram rendering failed — possible circular dependency or syntax error.</p>';
    }
  }
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
    var nodes = container.querySelectorAll(".mermaid");
    if (nodes.length > 0) {
      mermaid.run({ nodes: Array.from(nodes) });
    }
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
    var nodes = container.querySelectorAll(".mermaid");
    if (nodes.length > 0) {
      mermaid.run({ nodes: Array.from(nodes) });
    }
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
      startOnLoad: false,
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
