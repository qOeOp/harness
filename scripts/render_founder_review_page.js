#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");
const { spawnSync } = require("child_process");

const harnessRoot = path.resolve(__dirname, "..");
const repoRoot = harnessRoot;
const scriptsRoot = "./scripts";
const taskRoot = path.join(repoRoot, ".harness/tasks");
const manifestPath = path.join(repoRoot, ".harness/manifest.toml");

function scriptCommand(name) {
  return `${scriptsRoot}/${name}`;
}

function pad(value) {
  return String(value).padStart(2, "0");
}

function localDateValue(date = new Date()) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function localTimestampValue(date = new Date()) {
  return `${localDateValue(date)} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

const today = localDateValue();

function usage() {
  console.error(
    `usage: ${scriptCommand("render_founder_review_page.sh")} [--work-item <WI-xxxx> | --scope company|founder|department <slug>] [--output <path>]`
  );
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: repoRoot,
    encoding: "utf8",
    ...options,
  });

  return {
    ok: result.status === 0,
    status: result.status,
    stdout: (result.stdout || "").trim(),
    stderr: (result.stderr || "").trim(),
  };
}

function mustReadFile(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function canonicalWorkItemPath(workItemId) {
  return path.join(taskRoot, workItemId, "task.md");
}

function resolveWorkItemPath(workItemId) {
  const canonicalPath = canonicalWorkItemPath(workItemId);
  return fs.existsSync(canonicalPath) ? canonicalPath : "";
}

function listWorkItemPaths() {
  const paths = [];

  if (fs.existsSync(taskRoot)) {
    for (const entry of fs.readdirSync(taskRoot)) {
      const workItemPath = path.join(taskRoot, entry, "task.md");
      if (!fs.existsSync(workItemPath)) {
        continue;
      }
      paths.push(workItemPath);
    }
  }

  return paths.sort();
}

function readManifestValue(key) {
  if (!fs.existsSync(manifestPath)) {
    return "";
  }

  const escapedKey = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(`^${escapedKey}\\s*=\\s*(.+)$`, "m");
  const match = mustReadFile(manifestPath).match(pattern);
  if (!match) {
    return "";
  }

  return match[1].trim().replace(/^"/, "").replace(/"$/, "");
}

function runtimeValidationMode() {
  const runtimeMode = readManifestValue("runtime_mode");
  const governanceEnabled = readManifestValue("advanced_governance_enabled");
  if (runtimeMode === "advanced-governance" || governanceEnabled === "true") {
    return "governance";
  }
  return "core";
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function toFileHref(absPath) {
  return pathToFileURL(absPath).href;
}

function fieldValue(markdown, label) {
  const pattern = new RegExp(`^- ${label.replace(/[.*+?^${}()|[\\]\\\\]/g, "\\$&")}: (.*)$`, "m");
  const match = markdown.match(pattern);
  return match ? match[1].trim() : "none";
}

function bulletSection(markdown, heading) {
  const pattern = new RegExp(`^## ${heading}\\n\\n([\\s\\S]*?)(?:\\n## |$)`, "m");
  const match = markdown.match(pattern);
  if (!match) {
    return [];
  }

  return match[1]
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("- "))
    .map((line) => line.slice(2).trim());
}

function sectionFieldValue(markdown, heading, label) {
  const lines = bulletSection(markdown, heading);
  const prefix = `${label}: `;
  const match = lines.find((line) => line.startsWith(prefix));
  return match ? match.slice(prefix.length).trim() : "none";
}

function prettyValue(value) {
  return value && value !== "none" ? value : "none";
}

function linkedAttachmentsValue(markdown) {
  return fieldValue(markdown, "Linked attachments");
}

function parseLinkedAttachments(raw) {
  if (!raw || raw === "none") {
    return [];
  }

  return raw
    .split(";")
    .map((entry) => entry.trim())
    .filter(Boolean)
    .map((entry) => {
      const [artifactPath, artifactType = "unknown", artifactStatus = "unknown"] = entry.split("|");
      const absPath = path.resolve(repoRoot, artifactPath);
      return {
        artifactPath,
        artifactType,
        artifactStatus,
        absPath,
        exists: fs.existsSync(absPath),
      };
    });
}

function existingArtifactWorkItemLinks(filePath) {
  if (!fs.existsSync(filePath)) {
    return [];
  }

  const content = fs.readFileSync(filePath, "utf8");
  const match =
    content.match(/^<!-- Linked work items: (.*) -->$/m) ||
    content.match(/^<!-- Linked work item: (.*) -->$/m) ||
    content.match(/^- Linked work items: (.*)$/m) ||
    content.match(/^- Linked work item: (.*)$/m);

  if (!match || !match[1]) {
    return [];
  }

  return match[1]
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

function linkedWorkItemsForArtifact(outputPath) {
  const artifactPath = path.relative(repoRoot, outputPath);
  const linkedIds = new Set();

  for (const workItemPath of listWorkItemPaths()) {
    const itemMarkdown = mustReadFile(workItemPath);
    const workItemId = fieldValue(itemMarkdown, "ID");
    const attachments = parseLinkedAttachments(linkedAttachmentsValue(itemMarkdown));
    if (attachments.some((artifact) => artifact.artifactPath === artifactPath)) {
      linkedIds.add(workItemId);
    }
  }

  return Array.from(linkedIds).sort();
}

function parseChecks() {
  const validationMode = runtimeValidationMode();
  const checks = [
    ["Workspace Baseline", scriptCommand("validate_workspace.sh"), ["--mode", validationMode, "--quiet"]],
    ["State Audit", scriptCommand("audit_state_system.sh"), ["--mode", validationMode, "--quiet"]],
    ["Freshness Gate", scriptCommand("validate_freshness_gate.sh"), []],
  ];

  return checks.map(([label, command, args]) => {
    const result = run(command, args);
    return {
      label,
      command: `${command} ${args.join(" ")}`.trim(),
      ok: result.ok,
      detail: result.stdout || result.stderr || (result.ok ? "ok" : "failed without output"),
    };
  });
}

function sectionList(items) {
  if (!items.length) {
    return "<p class=\"muted\">none</p>";
  }

  return `<ul>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join("")}</ul>`;
}

function renderDefinitionGrid(pairs) {
  return `<dl class="meta-grid">${pairs
    .map(
      ([label, value]) =>
        `<div class="meta-row"><dt>${escapeHtml(label)}</dt><dd>${escapeHtml(prettyValue(value))}</dd></div>`
    )
    .join("")}</dl>`;
}

function auditStatus(checks) {
  return checks.every((check) => check.ok);
}

function gateRows(context) {
  const hasArtifacts = context.artifacts.length > 0;
  const reviewable = context.decisionNeeded !== "none" && context.doneCriteria !== "none";

  return [
    {
      label: "Runnable",
      ok: true,
      detail: "This page is generated from live repo state and opens as a standalone local HTML artifact.",
    },
    {
      label: "Usable",
      ok: hasArtifacts,
      detail: hasArtifacts
        ? "Supporting artifacts are linked directly from the page."
        : "No linked artifacts are available yet, so Founder would still need raw repo context.",
    },
    {
      label: "Bounded",
      ok: context.readyCriteria !== "none" && context.whyItMatters !== "none",
      detail:
        "The slice is intentionally limited to repo-local harness review. It does not claim product runtime or Telegram execution.",
    },
    {
      label: "Reviewable",
      ok: reviewable && auditStatus(context.checks),
      detail:
        "Decision prompt, acceptance criteria, and current audits are all visible without opening scattered markdown files.",
    },
  ];
}

function resolveSelection() {
  let workItemId = "";
  let scope = "founder";
  let department = "";
  let outputPath = "";

  const args = process.argv.slice(2);
  while (args.length > 0) {
    const token = args.shift();
    switch (token) {
      case "--work-item":
        workItemId = args.shift() || "";
        break;
      case "--scope":
        scope = args.shift() || "";
        if (!scope) {
          usage();
        }
        if (scope === "department") {
          department = args.shift() || "";
          if (!department) {
            usage();
          }
        }
        break;
      case "--output":
        outputPath = args.shift() || "";
        if (!outputPath) {
          usage();
        }
        break;
      case "--help":
      case "-h":
        usage();
        break;
      default:
        usage();
    }
  }

  if (workItemId) {
    const workItemPath = resolveWorkItemPath(workItemId);
    if (!fs.existsSync(workItemPath)) {
      throw new Error(`missing work item: ${workItemId}`);
    }
    return {
      workItemId,
      workItemPath,
      routeHint: scope === "department" ? `department:${department}` : scope,
      outputPath,
      selectionResult: "explicit",
      selectionReason: "work item provided explicitly",
      scope,
      department,
    };
  }

  const openArgs = ["--json", scope];
  if (scope === "department") {
    openArgs.push(department);
  }

  const result = run(scriptCommand("open_work_item.sh"), openArgs);
  if (![0, 2].includes(result.status)) {
    throw new Error(result.stderr || "failed to open work item");
  }

  const payload = JSON.parse(result.stdout);
  const selected = payload.selected_work_item || payload.next_blocked_candidate;
  if (!selected || !selected.id || !selected.path) {
    throw new Error(`no work item available for scope ${scope}`);
  }

    return {
      workItemId: selected.id,
      workItemPath: path.resolve(repoRoot, selected.path),
      routeHint: payload.route || payload.board || scope,
      outputPath,
      selectionResult: payload.result || "unknown",
    selectionReason:
      payload.selector_reason ||
      (payload.next_blocked_candidate && payload.next_blocked_candidate.blocked_because) ||
      payload.recommended_action ||
      "none",
    scope,
    department,
  };
}

function renderPage(context) {
  const recoveryHtml = context.recovery
    ? renderDefinitionGrid([
        ["Task updated at", context.recovery.updatedAt],
        ["Current focus", context.recovery.currentFocus],
        ["Next command", context.recovery.nextCommand],
        ["Recovery notes", context.recovery.recoveryNotes],
      ])
    : '<p class="muted">No recovery snapshot is stored in this task record.</p>';

  const attachmentHtml = context.attachments.length
    ? `<div class="artifact-list">${context.attachments
        .map((attachment) => {
          const stateClass = attachment.exists ? "ok" : "warn";
          const href = attachment.exists ? toFileHref(attachment.absPath) : "";
          const body = `
            <div class="artifact-type">${escapeHtml(attachment.artifactType)}</div>
            <div class="artifact-path">${escapeHtml(attachment.artifactPath)}</div>
            <div class="artifact-meta">${escapeHtml(attachment.artifactStatus)}${attachment.exists ? "" : " | missing file"}</div>
          `;
          return attachment.exists
            ? `<a class="artifact-card ${stateClass}" href="${escapeHtml(href)}">${body}</a>`
            : `<div class="artifact-card ${stateClass}">${body}</div>`;
        })
        .join("")}</div>`
    : '<p class="muted">No linked attachments.</p>';

  const checksHtml = `<div class="check-list">${context.checks
    .map(
      (check) => `
        <div class="check-card ${check.ok ? "ok" : "warn"}">
          <div class="check-top">
            <strong>${escapeHtml(check.label)}</strong>
            <span>${check.ok ? "pass" : "fail"}</span>
          </div>
          <code>${escapeHtml(check.command)}</code>
          <p>${escapeHtml(check.detail)}</p>
        </div>`
    )
    .join("")}</div>`;

  const gateHtml = `<div class="gate-list">${gateRows(context)
    .map(
      (gate) => `
        <div class="gate-card ${gate.ok ? "ok" : "warn"}">
          <div class="gate-top">
            <strong>${escapeHtml(gate.label)}</strong>
            <span>${gate.ok ? "pass" : "gap"}</span>
          </div>
          <p>${escapeHtml(gate.detail)}</p>
        </div>`
    )
    .join("")}</div>`;

  const linkedWorkItemsComment = context.linkedWorkItems.length
    ? `<!-- Linked work items: ${escapeHtml(context.linkedWorkItems.join(","))} -->\n`
    : "";

  return `<!DOCTYPE html>
${linkedWorkItemsComment}<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="icon" href="data:," />
  <title>${escapeHtml(context.title)} | Founder Review</title>
  <style>
    :root {
      --bg: #f4efe6;
      --ink: #19222b;
      --muted: #58636d;
      --card: rgba(255, 255, 255, 0.78);
      --line: rgba(25, 34, 43, 0.12);
      --accent: #af3a2b;
      --accent-soft: rgba(175, 58, 43, 0.14);
      --ok: #1f7a52;
      --ok-soft: rgba(31, 122, 82, 0.12);
      --warn: #9b6120;
      --warn-soft: rgba(155, 97, 32, 0.12);
      --shadow: 0 24px 70px rgba(40, 32, 24, 0.14);
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top left, rgba(175, 58, 43, 0.18), transparent 30%),
        radial-gradient(circle at top right, rgba(31, 122, 82, 0.14), transparent 32%),
        linear-gradient(180deg, #f8f4ee 0%, var(--bg) 45%, #efe7da 100%);
    }

    .shell {
      width: min(1180px, calc(100% - 32px));
      margin: 32px auto 48px;
    }

    .hero,
    .panel {
      border: 1px solid var(--line);
      background: var(--card);
      backdrop-filter: blur(14px);
      border-radius: 28px;
      box-shadow: var(--shadow);
    }

    .hero {
      padding: 28px;
      position: relative;
      overflow: hidden;
    }

    .hero::after {
      content: "";
      position: absolute;
      inset: auto -120px -120px auto;
      width: 280px;
      height: 280px;
      border-radius: 50%;
      background: linear-gradient(135deg, rgba(175, 58, 43, 0.16), rgba(25, 34, 43, 0.02));
    }

    .eyebrow {
      text-transform: uppercase;
      letter-spacing: 0.16em;
      font-size: 12px;
      color: var(--muted);
      margin-bottom: 14px;
    }

    h1 {
      margin: 0;
      max-width: 820px;
      font-size: clamp(34px, 6vw, 58px);
      line-height: 0.98;
    }

    .hero-copy {
      max-width: 760px;
      margin-top: 18px;
      font-size: 18px;
      line-height: 1.55;
    }

    .chips {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 22px;
    }

    .chip {
      border-radius: 999px;
      padding: 10px 14px;
      font-size: 13px;
      background: rgba(25, 34, 43, 0.08);
    }

    .grid {
      display: grid;
      gap: 18px;
      grid-template-columns: repeat(12, minmax(0, 1fr));
      margin-top: 18px;
    }

    .span-7 {
      grid-column: span 7;
    }

    .span-5 {
      grid-column: span 5;
    }

    .span-6 {
      grid-column: span 6;
    }

    .span-12 {
      grid-column: span 12;
    }

    .panel {
      padding: 24px;
    }

    h2 {
      margin: 0 0 16px;
      font-size: 24px;
    }

    p,
    li {
      font-size: 16px;
      line-height: 1.55;
    }

    ul {
      margin: 0;
      padding-left: 20px;
    }

    .muted {
      color: var(--muted);
    }

    .meta-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px 18px;
      margin: 0;
    }

    .meta-row {
      padding: 14px 16px;
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.6);
      border: 1px solid rgba(25, 34, 43, 0.08);
    }

    dt {
      font-size: 12px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--muted);
      margin-bottom: 6px;
    }

    dd {
      margin: 0;
      font-size: 16px;
    }

    .artifact-list,
    .check-list,
    .gate-list {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 14px;
    }

    .artifact-card,
    .check-card,
    .gate-card {
      display: block;
      padding: 16px;
      border-radius: 20px;
      border: 1px solid rgba(25, 34, 43, 0.08);
      color: inherit;
      text-decoration: none;
      background: rgba(255, 255, 255, 0.7);
    }

    .artifact-card.ok,
    .check-card.ok,
    .gate-card.ok {
      background: var(--ok-soft);
      border-color: rgba(31, 122, 82, 0.18);
    }

    .artifact-card.warn,
    .check-card.warn,
    .gate-card.warn {
      background: var(--warn-soft);
      border-color: rgba(155, 97, 32, 0.18);
    }

    .artifact-type,
    .check-top,
    .gate-top {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 8px;
    }

    .artifact-path,
    code {
      font-family: "SFMono-Regular", "Menlo", "Consolas", monospace;
      font-size: 13px;
      line-height: 1.5;
      word-break: break-word;
    }

    code {
      display: block;
      padding: 10px 12px;
      border-radius: 14px;
      background: rgba(25, 34, 43, 0.08);
      margin-bottom: 10px;
    }

    .footer-note {
      margin-top: 18px;
      font-size: 14px;
      color: var(--muted);
    }

    @media (max-width: 900px) {
      .span-7,
      .span-6,
      .span-5 {
        grid-column: span 12;
      }

      .meta-grid {
        grid-template-columns: 1fr;
      }

      .shell {
        width: min(100% - 20px, 100%);
        margin-top: 20px;
      }
    }
  </style>
</head>
<body>
  <div class="shell">
    <section class="hero">
      <div class="eyebrow">Founder Review Slice</div>
      <h1>${escapeHtml(context.title)}</h1>
      <p class="hero-copy">${escapeHtml(context.whyItMatters)}</p>
      <div class="chips">
        <div class="chip">Work item ${escapeHtml(context.workItemId)}</div>
        <div class="chip">Status ${escapeHtml(context.status)}</div>
        <div class="chip">Owner ${escapeHtml(context.owner)}</div>
        <div class="chip">Scope ${escapeHtml(context.scopeLabel)}</div>
        <div class="chip">Generated ${escapeHtml(context.generatedAt)}</div>
      </div>
    </section>

    <div class="grid">
      <section class="panel span-7">
        <h2>Decision Surface</h2>
        ${renderDefinitionGrid([
          ["Decision needed", context.decisionNeeded],
          ["Objective", context.objective],
          ["Ready criteria", context.readyCriteria],
          ["Done criteria", context.doneCriteria],
          ["Current blocker", context.currentBlocker],
          ["Next handoff", context.nextHandoff],
        ])}
      </section>

      <section class="panel span-5">
        <h2>State Spine</h2>
        ${renderDefinitionGrid([
          ["Task source path", context.taskPath],
          ["Recovery surface", context.recoveryPath],
          ["Selector route", context.routeHint],
          ["Selection result", context.selectionResult],
          ["Selection reason", context.selectionReason],
          ["State version", context.stateVersion],
          ["Last operation ID", context.lastOperationId],
          ["Last transition event", context.lastTransitionEvent],
        ])}
      </section>

      <section class="panel span-6">
        <h2>Summary</h2>
        ${sectionList(context.summary)}
      </section>

      <section class="panel span-6">
        <h2>Recovery Snapshot</h2>
        ${recoveryHtml}
      </section>

      <section class="panel span-12">
        <h2>Supporting Attachments</h2>
        ${attachmentHtml}
      </section>

      <section class="panel span-6">
        <h2>Demo Gate</h2>
        ${gateHtml}
      </section>

      <section class="panel span-6">
        <h2>Verification Checks</h2>
        ${checksHtml}
      </section>

      <section class="panel span-6">
        <h2>Known Boundaries</h2>
        <ul>
          <li>This slice validates repo-local harness review, not product runtime.</li>
          <li>It renders one work item into a standalone review surface; it does not replace state-of-truth files.</li>
          <li>All supporting assets remain local-first and append-only inside the repository.</li>
        </ul>
      </section>

      <section class="panel span-6">
        <h2>How To Verify</h2>
        <ul>
          <li>Open this file directly in a browser. No server is required.</li>
          <li>Run <code>${escapeHtml(scriptCommand("open_work_item.sh"))} --json founder</code> to confirm the founder route.</li>
          <li>Run <code>${escapeHtml(scriptCommand("render_founder_review_page.sh"))} --scope founder</code> to regenerate from live state.</li>
          <li>Run the checks above to confirm the repo still passes its control gates.</li>
        </ul>
      </section>
    </div>

    <p class="footer-note">Generated from repo state at ${escapeHtml(context.generatedAt)}. This page is a review artifact, not the source of truth.</p>
  </div>
</body>
</html>`;
}

function main() {
  const selection = resolveSelection();
  const markdown = mustReadFile(selection.workItemPath);
  const workItemId = fieldValue(markdown, "ID");
  const workItemAbsPath = selection.workItemPath;
  const linkedAttachments = parseLinkedAttachments(linkedAttachmentsValue(markdown));
  const checks = parseChecks();

  const outputPath =
    selection.outputPath ||
    path.join(repoRoot, ".harness/workspace/status/demos", `${today}-${workItemId}-founder-review.html`);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  const existingLinks = existingArtifactWorkItemLinks(outputPath);
  const linkedWorkItems = Array.from(
    new Set([workItemId, ...existingLinks, ...linkedWorkItemsForArtifact(outputPath)])
  ).sort();

  const context = {
    workItemId,
    title: fieldValue(markdown, "Title"),
    status: fieldValue(markdown, "Status"),
    owner: fieldValue(markdown, "Owner"),
    objective: fieldValue(markdown, "Objective"),
    whyItMatters: fieldValue(markdown, "Why it matters"),
    decisionNeeded: fieldValue(markdown, "Decision needed"),
    readyCriteria: fieldValue(markdown, "Ready criteria"),
    doneCriteria: fieldValue(markdown, "Done criteria"),
    currentBlocker: fieldValue(markdown, "Current blocker"),
    nextHandoff: fieldValue(markdown, "Next handoff"),
    stateVersion: fieldValue(markdown, "State version"),
    lastOperationId: fieldValue(markdown, "Last operation ID"),
    lastTransitionEvent: fieldValue(markdown, "Last transition event"),
    summary: bulletSection(markdown, "Summary"),
    attachments: linkedAttachments,
    checks,
    generatedAt: localTimestampValue(),
    linkedWorkItems,
    taskPath: path.relative(repoRoot, workItemAbsPath),
    recoveryPath: `${path.relative(repoRoot, workItemAbsPath)}#Recovery`,
    routeHint: selection.routeHint,
    selectionResult: selection.selectionResult,
    selectionReason: selection.selectionReason,
    scopeLabel:
      selection.scope === "department" ? `department:${selection.department}` : selection.scope,
    recovery: markdown
      ? {
          updatedAt: fieldValue(markdown, "Updated at"),
          currentFocus: sectionFieldValue(markdown, "Recovery", "Current focus"),
          nextCommand: sectionFieldValue(markdown, "Recovery", "Next command"),
          recoveryNotes: sectionFieldValue(markdown, "Recovery", "Recovery notes"),
        }
      : null,
  };

  fs.writeFileSync(outputPath, renderPage(context));
  process.stdout.write(`${path.relative(repoRoot, outputPath)}\n`);
}

main();
