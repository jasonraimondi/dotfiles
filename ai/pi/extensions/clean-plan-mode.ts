/**
 * Clean Plan Mode (project-local)
 *
 * Strict, simple planning mode for pi:
 * - Blocks all write-capable tools while enabled
 * - Restricts active tools to read-only set
 * - Injects planning-only instructions before each turn
 * - Adds /plan, /plan-on, /plan-off commands (+ Ctrl+Alt+P)
 * - Supports --plan startup flag
 */

const PLAN_TOOLS = ["read", "grep", "find", "ls"];
const DEFAULT_TOOLS = ["read", "bash", "edit", "write"];
const STATE_KEY = "clean-plan-mode";

function coerceArray(value) {
	return Array.isArray(value) ? value.filter((v) => typeof v === "string") : null;
}

export default function cleanPlanMode(pi) {
	let enabled = false;
	let previousTools = null;

	pi.registerFlag("plan", {
		description: "Start in clean plan mode (strict read-only planning)",
		type: "boolean",
		default: false,
	});

	function persistState() {
		pi.appendEntry(STATE_KEY, {
			enabled,
			previousTools,
		});
	}

	function setStatus(ctx) {
		if (!ctx.hasUI) return;
		if (enabled) {
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "⏸ plan (strict)"));
		} else {
			ctx.ui.setStatus("plan-mode", undefined);
		}
	}

	function enablePlanMode(ctx, notify = true) {
		if (enabled) return;
		enabled = true;
		previousTools = pi.getActiveTools();
		pi.setActiveTools(PLAN_TOOLS);
		setStatus(ctx);
		persistState();
		if (notify && ctx.hasUI) {
			ctx.ui.notify(`Plan mode enabled. Tools: ${PLAN_TOOLS.join(", ")}`);
		}
	}

	function disablePlanMode(ctx, notify = true) {
		if (!enabled) return;
		enabled = false;
		const restore = coerceArray(previousTools) ?? DEFAULT_TOOLS;
		pi.setActiveTools(restore);
		previousTools = null;
		setStatus(ctx);
		persistState();
		if (notify && ctx.hasUI) {
			ctx.ui.notify("Plan mode disabled. Restored normal tools.");
		}
	}

	pi.registerCommand("plan", {
		description: "Toggle strict plan mode",
		handler: async (_args, ctx) => {
			if (enabled) disablePlanMode(ctx);
			else enablePlanMode(ctx);
		},
	});

	pi.registerCommand("plan-on", {
		description: "Enable strict plan mode",
		handler: async (_args, ctx) => enablePlanMode(ctx),
	});

	pi.registerCommand("plan-off", {
		description: "Disable strict plan mode",
		handler: async (_args, ctx) => disablePlanMode(ctx),
	});

	pi.registerShortcut("ctrl+alt+p", {
		description: "Toggle strict plan mode",
		handler: async (ctx) => {
			if (enabled) disablePlanMode(ctx);
			else enablePlanMode(ctx);
		},
	});

	// Hard block any non-read-only tool while in plan mode.
	pi.on("tool_call", async (event) => {
		if (!enabled) return;
		if (!PLAN_TOOLS.includes(event.toolName)) {
			return {
				block: true,
				reason: `Plan mode: tool "${event.toolName}" is blocked. Allowed tools: ${PLAN_TOOLS.join(", ")}`,
			};
		}
	});

	// Remove stale planning instruction context when plan mode is off.
	pi.on("context", async (event) => {
		if (enabled) return;
		return {
			messages: event.messages.filter((message) => message?.customType !== "clean-plan-mode-context"),
		};
	});

	pi.on("before_agent_start", async () => {
		if (!enabled) return;
		return {
			message: {
				customType: "clean-plan-mode-context",
				display: false,
				content: `You are in STRICT PLAN MODE.

Rules:
- Do NOT modify files.
- Do NOT propose immediate edits.
- Read and analyze only.
- Use only read-only tools.
- Ask clarifying questions if anything is ambiguous.

Output format:
1) Summary of current state
2) Risks / unknowns
3) Plan:
   1. Step one
   2. Step two
   3. Step three
4) Files likely to change (later, after plan approval)
5) Validation/test strategy

End by asking for approval before implementation.`,
			},
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		const lastState = entries
			.filter((entry) => entry.type === "custom" && entry.customType === STATE_KEY)
			.pop();

		if (lastState?.data && typeof lastState.data === "object") {
			enabled = lastState.data.enabled === true;
			previousTools = coerceArray(lastState.data.previousTools);
		}

		if (pi.getFlag("plan") === true) {
			enabled = true;
		}

		if (enabled) {
			pi.setActiveTools(PLAN_TOOLS);
		}

		setStatus(ctx);
	});
}
