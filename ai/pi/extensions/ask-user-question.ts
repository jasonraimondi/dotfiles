import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Editor, type EditorTheme, Key, Text, matchesKey, truncateToWidth } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

interface AskUserQuestionOption {
	label: string;
	description?: string;
}

interface AskUserQuestionItem {
	question: string;
	header: string;
	options: AskUserQuestionOption[];
	multiSelect: boolean;
}

interface AskUserQuestionDetails {
	questions: AskUserQuestionItem[];
	answers: Record<string, string>;
	cancelled: boolean;
}

const AskUserQuestionOptionSchema = Type.Object({
	label: Type.String({ description: "Option label shown to the user" }),
	description: Type.Optional(Type.String({ description: "Optional option description" })),
});

const AskUserQuestionQuestionSchema = Type.Object({
	question: Type.String({ description: "The question text" }),
	header: Type.String({ description: "Short section label (e.g. 'Scope', 'UI', 'Data')" }),
	options: Type.Array(AskUserQuestionOptionSchema, {
		description: "Answer options",
		minItems: 1,
	}),
	multiSelect: Type.Boolean({
		description: "Whether multiple options can be selected for this question",
	}),
});

const AskUserQuestionParams = Type.Object({
	questions: Type.Array(AskUserQuestionQuestionSchema, {
		description: "One or more questions to ask the user",
		minItems: 1,
	}),
});

function sanitizeQuestions(questions: AskUserQuestionItem[]): AskUserQuestionItem[] {
	return questions
		.map((question, i) => {
			const text = question.question?.trim();
			const header = question.header?.trim() || `Q${i + 1}`;
			const options = (question.options || [])
				.map((option) => ({
					label: option.label?.trim() || "",
					description: option.description?.trim() || undefined,
				}))
				.filter((option) => option.label.length > 0);

			if (!text || options.length === 0) return null;

			return {
				question: text,
				header,
				options,
				multiSelect: question.multiSelect === true,
			};
		})
		.filter((question): question is AskUserQuestionItem => question !== null);
}

function quote(text: string): string {
	return `"${text.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"")}"`;
}

function answerForQuestion(
	question: AskUserQuestionItem,
	selected: Set<number>,
	customAnswer: string | null,
): string | null {
	const trimmedCustom = customAnswer?.trim() || "";

	if (!question.multiSelect) {
		if (trimmedCustom) return trimmedCustom;
		if (selected.size === 0) return null;
		const [first] = Array.from(selected);
		return question.options[first]?.label || null;
	}

	const selectedLabels = Array.from(selected)
		.sort((a, b) => a - b)
		.map((index) => question.options[index]?.label)
		.filter((label): label is string => Boolean(label));

	if (trimmedCustom) selectedLabels.push(trimmedCustom);
	if (selectedLabels.length === 0) return null;
	return selectedLabels.join(", ");
}

function buildSuccessText(answers: Record<string, string>): string {
	const pairs = Object.entries(answers).map(([question, answer]) => `${quote(question)}=${quote(answer)}`);
	return `User has answered your questions: ${pairs.join(", ")}. You can now continue with the user's answers in mind.`;
}

export default function askUserQuestion(pi: ExtensionAPI) {
	pi.registerTool({
		name: "AskUserQuestion",
		label: "Ask User Question",
		description:
			"Ask one or more structured questions to the user. Supports per-question headers, option descriptions, multi-select, and custom typed answers.",
		parameters: AskUserQuestionParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const questions = sanitizeQuestions(params.questions as AskUserQuestionItem[]);

			if (questions.length === 0) {
				return {
					content: [{ type: "text", text: "Error: No valid questions were provided." }],
					details: {
						questions: [],
						answers: {},
						cancelled: true,
					} as AskUserQuestionDetails,
				};
			}

			if (!ctx.hasUI) {
				return {
					content: [
						{
							type: "text",
							text: "UI is not available in this mode, so AskUserQuestion cannot prompt the user interactively.",
						},
					],
					details: {
						questions,
						answers: {},
						cancelled: true,
					} as AskUserQuestionDetails,
				};
			}

			const result = await ctx.ui.custom<AskUserQuestionDetails>((tui, theme, _kb, done) => {
				let currentQuestionIndex = 0;
				let inputMode = false;
				let cachedLines: string[] | undefined;

				const selectedByQuestion = questions.map(() => new Set<number>());
				const customAnswerByQuestion = questions.map(() => null as string | null);
				const cursorByQuestion = questions.map(() => 0);

				const editorTheme: EditorTheme = {
					borderColor: (s) => theme.fg("accent", s),
					selectList: {
						selectedPrefix: (t) => theme.fg("accent", t),
						selectedText: (t) => theme.fg("accent", t),
						description: (t) => theme.fg("muted", t),
						scrollInfo: (t) => theme.fg("dim", t),
						noMatch: (t) => theme.fg("warning", t),
					},
				};
				const editor = new Editor(tui, editorTheme);

				function customOptionIndex(questionIndex: number): number {
					return questions[questionIndex].options.length;
				}

				function hasAnswer(questionIndex: number): boolean {
					return answerForQuestion(
						questions[questionIndex],
						selectedByQuestion[questionIndex],
						customAnswerByQuestion[questionIndex],
					) !== null;
				}

				function isCompleted(): boolean {
					return questions.every((_question, i) => hasAnswer(i));
				}

				function buildResult(cancelled: boolean): AskUserQuestionDetails {
					const answers: Record<string, string> = {};
					for (let i = 0; i < questions.length; i++) {
						const answer = answerForQuestion(questions[i], selectedByQuestion[i], customAnswerByQuestion[i]);
						if (answer) answers[questions[i].question] = answer;
					}
					return { questions, answers, cancelled };
				}

				function refresh() {
					cachedLines = undefined;
					tui.requestRender();
				}

				function toggleOption(questionIndex: number, optionIndex: number) {
					const question = questions[questionIndex];
					const selected = selectedByQuestion[questionIndex];

					if (!question.multiSelect) {
						selected.clear();
						selected.add(optionIndex);
						customAnswerByQuestion[questionIndex] = null;
						return;
					}

					if (selected.has(optionIndex)) selected.delete(optionIndex);
					else selected.add(optionIndex);
				}

				function beginCustomInput(questionIndex: number) {
					inputMode = true;
					editor.setText(customAnswerByQuestion[questionIndex] || "");
					refresh();
				}

				function advanceOrSubmit() {
					if (currentQuestionIndex < questions.length - 1) {
						currentQuestionIndex += 1;
						refresh();
						return;
					}

					done(buildResult(false));
				}

				editor.onSubmit = (value) => {
					const questionIndex = currentQuestionIndex;
					const trimmed = value.trim();
					customAnswerByQuestion[questionIndex] = trimmed || null;
					if (trimmed && !questions[questionIndex].multiSelect) {
						selectedByQuestion[questionIndex].clear();
					}
					inputMode = false;
					if (questions[questionIndex].multiSelect) {
						refresh();
						return;
					}
					advanceOrSubmit();
				};

				function handleInput(data: string) {
					const question = questions[currentQuestionIndex];
					const maxOption = customOptionIndex(currentQuestionIndex);
					const cursor = cursorByQuestion[currentQuestionIndex];

					if (inputMode) {
						if (matchesKey(data, Key.escape)) {
							inputMode = false;
							refresh();
							return;
						}
						editor.handleInput(data);
						refresh();
						return;
					}

					if (matchesKey(data, Key.escape)) {
						done(buildResult(true));
						return;
					}

					if (questions.length > 1 && (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab")))) {
						currentQuestionIndex = (currentQuestionIndex - 1 + questions.length) % questions.length;
						refresh();
						return;
					}

					if (questions.length > 1 && (matchesKey(data, Key.right) || matchesKey(data, Key.tab))) {
						currentQuestionIndex = (currentQuestionIndex + 1) % questions.length;
						refresh();
						return;
					}

					if (matchesKey(data, Key.up)) {
						cursorByQuestion[currentQuestionIndex] = Math.max(0, cursor - 1);
						refresh();
						return;
					}

					if (matchesKey(data, Key.down)) {
						cursorByQuestion[currentQuestionIndex] = Math.min(maxOption, cursor + 1);
						refresh();
						return;
					}

					if (data.toLowerCase() === "c" || (matchesKey(data, Key.enter) && cursor === maxOption)) {
						beginCustomInput(currentQuestionIndex);
						return;
					}

					if (question.multiSelect && matchesKey(data, Key.space) && cursor < maxOption) {
						toggleOption(currentQuestionIndex, cursor);
						refresh();
						return;
					}

					if (matchesKey(data, Key.enter)) {
						if (!question.multiSelect) {
							if (cursor < maxOption) {
								toggleOption(currentQuestionIndex, cursor);
								advanceOrSubmit();
							}
							return;
						}

						if (cursor < maxOption && !hasAnswer(currentQuestionIndex)) {
							toggleOption(currentQuestionIndex, cursor);
							refresh();
							return;
						}

						if (hasAnswer(currentQuestionIndex)) {
							advanceOrSubmit();
						} else {
							refresh();
						}
					}
				}

				function render(width: number): string[] {
					if (cachedLines) return cachedLines;

					const lines: string[] = [];
					const add = (text: string) => lines.push(truncateToWidth(text, width));
					const question = questions[currentQuestionIndex];
					const cursor = cursorByQuestion[currentQuestionIndex];
					const currentSelected = selectedByQuestion[currentQuestionIndex];
					const currentCustom = customAnswerByQuestion[currentQuestionIndex];
					const isMulti = question.multiSelect;
					const customIndex = customOptionIndex(currentQuestionIndex);

					add(theme.fg("accent", "─".repeat(width)));
					add(
						theme.fg(
							"dim",
							` ${currentQuestionIndex + 1}/${questions.length} · ${question.header} · ${isMulti ? "multi-select" : "single-select"}`,
						),
					);

					if (questions.length > 1) {
						const tabs = questions
							.map((item, i) => {
								const status = hasAnswer(i) ? "■" : "□";
								const text = ` ${status} ${item.header} `;
								if (i === currentQuestionIndex) return theme.bg("selectedBg", theme.fg("text", text));
								return hasAnswer(i) ? theme.fg("success", text) : theme.fg("muted", text);
							})
							.join(" ");
						add(` ${tabs}`);
					}

					lines.push("");
					add(theme.fg("text", ` ${question.question}`));
					lines.push("");

					for (let i = 0; i < question.options.length; i++) {
						const option = question.options[i];
						const focused = i === cursor;
						const selected = currentSelected.has(i);
						const prefix = focused ? theme.fg("accent", "> ") : "  ";
						const marker = isMulti
							? selected
								? theme.fg("success", "[x] ")
								: theme.fg("dim", "[ ] ")
							: selected
								? theme.fg("success", "✓ ")
								: "";
						const color = focused ? "accent" : "text";
						add(`${prefix}${marker}${theme.fg(color, `${i + 1}. ${option.label}`)}`);
						if (option.description) {
							add(`     ${theme.fg("muted", option.description)}`);
						}
					}

					const customFocused = cursor === customIndex;
					const customPrefix = customFocused ? theme.fg("accent", "> ") : "  ";
					const customMarker = currentCustom ? theme.fg("success", "✎ ") : "";
					add(`${customPrefix}${customMarker}${theme.fg(customFocused ? "accent" : "text", `${customIndex + 1}. Type custom answer`)}`);
					if (currentCustom) {
						add(`     ${theme.fg("muted", currentCustom)}`);
					}

					if (inputMode) {
						lines.push("");
						add(theme.fg("muted", " Custom answer:"));
						for (const line of editor.render(Math.max(20, width - 2))) {
							add(` ${line}`);
						}
					}

					lines.push("");
					if (inputMode) {
						add(theme.fg("dim", " Enter submit • Esc cancel input"));
					} else if (isMulti) {
						const ready = hasAnswer(currentQuestionIndex) ? theme.fg("success", "ready") : theme.fg("warning", "select at least one");
						add(theme.fg("dim", ` ↑↓ move • Space toggle • Enter next (${ready}) • C custom • ←/→ nav • Esc cancel`));
					} else {
						add(theme.fg("dim", " ↑↓ move • Enter choose • C custom • ←/→ nav • Esc cancel"));
					}

					if (isCompleted()) {
						add(theme.fg("success", " All questions answered."));
					}

					add(theme.fg("accent", "─".repeat(width)));
					cachedLines = lines;
					return lines;
				}

				return {
					render,
					invalidate: () => {
						cachedLines = undefined;
					},
					handleInput,
				};
			});

			if (result.cancelled) {
				const answeredCount = Object.keys(result.answers).length;
				if (answeredCount > 0) {
					return {
						content: [
							{
								type: "text",
								text: `User partially answered your questions before cancelling: ${Object.entries(result.answers)
									.map(([question, answer]) => `${quote(question)}=${quote(answer)}`)
									.join(", ")}.`,
							},
						],
						details: result,
					};
				}

				return {
					content: [{ type: "text", text: "User cancelled answering your questions." }],
					details: result,
				};
			}

			return {
				content: [{ type: "text", text: buildSuccessText(result.answers) }],
				details: result,
			};
		},

		renderCall(args, theme) {
			const questions = Array.isArray(args.questions)
				? (args.questions as Array<{ header?: string; question?: string; multiSelect?: boolean }>)
				: [];
			const total = questions.length;
			const labels = questions.map((question, i) => question.header || `Q${i + 1}`).join(", ");
			let text = theme.fg("toolTitle", theme.bold("AskUserQuestion "));
			text += theme.fg("muted", `${total} question${total === 1 ? "" : "s"}`);
			if (labels) text += theme.fg("dim", ` (${truncateToWidth(labels, 50)})`);
			return new Text(text, 0, 0);
		},

		renderResult(result, _options, theme) {
			const details = result.details as AskUserQuestionDetails | undefined;
			if (!details) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}

			if (details.cancelled && Object.keys(details.answers).length === 0) {
				return new Text(theme.fg("warning", "Cancelled"), 0, 0);
			}

			const lines = Object.entries(details.answers).map(([question, answer]) => {
				return `${theme.fg("success", "✓ ")}${theme.fg("accent", truncateToWidth(question, 60))}: ${answer}`;
			});

			if (details.cancelled) {
				lines.unshift(theme.fg("warning", "Cancelled after partial answers"));
			}

			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
