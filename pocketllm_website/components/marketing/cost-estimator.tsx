'use client';

import { useMemo, useState } from 'react';
import { GlassCard, GradientPill } from '@/components/marketing/page-shell';

const MODEL_OPTIONS = [
	{ id: 'gpt4', label: 'OpenAI · GPT-4 Turbo', inputRate: 10, outputRate: 30 },
	{ id: 'gpt35', label: 'OpenAI · GPT-3.5', inputRate: 0.5, outputRate: 1.5 },
	{ id: 'gemini', label: 'Google · Gemini Pro', inputRate: 0.5, outputRate: 1.5 },
	{ id: 'mixtral', label: 'Groq · Mixtral', inputRate: 0.24, outputRate: 0.24 },
	{ id: 'llama3', label: 'Groq · Llama 3', inputRate: 0.05, outputRate: 0.08 },
];

const TOKENS_PER_MESSAGE = 2500; // budget ~100 msgs/day on GPT-3.5 ≈ $15/month
const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export function CostEstimator() {
	const [messagesPerDay, setMessagesPerDay] = useState(100);
	const [model, setModel] = useState(MODEL_OPTIONS[1].id);

	const estimate = useMemo(() => {
		const selected = MODEL_OPTIONS.find((m) => m.id === model) ?? MODEL_OPTIONS[0];
		const monthlyMessages = messagesPerDay * 30;
		const monthlyInputTokens = (TOKENS_PER_MESSAGE / 2) * monthlyMessages;
		const monthlyOutputTokens = monthlyInputTokens;
		const inputCost = (monthlyInputTokens / 1_000_000) * selected.inputRate;
		const outputCost = (monthlyOutputTokens / 1_000_000) * selected.outputRate;
		const total = inputCost + outputCost;
		return {
			selected,
			total,
			monthlyMessages,
			inputCost,
			outputCost,
		};
	}, [messagesPerDay, model]);

	return (
		<GlassCard className="space-y-6">
			<div className="space-y-2">
				<GradientPill>Cost Estimator</GradientPill>
				<h3 className="text-2xl font-semibold text-white">Estimate your monthly provider bill</h3>
				<p className="text-sm text-gray-400">
					Move the slider and pick your go-to model. PocketLLM stays free — these totals come
					straight from the provider price sheets.
				</p>
			</div>

			<div className="space-y-4">
				<label className="flex flex-col gap-2 text-sm font-medium text-gray-300" htmlFor="messages">
					Messages per day
					<input
						id="messages"
						type="range"
						min={10}
						max={1000}
						value={messagesPerDay}
						onChange={(event) => setMessagesPerDay(Number(event.target.value))}
						className="accent-purple-500"
					/>
					<div className="flex justify-between text-xs text-gray-400">
						<span>10</span>
						<span>{messagesPerDay} msgs/day</span>
						<span>1000</span>
					</div>
				</label>

				<label className="flex flex-col gap-2 text-sm font-medium text-gray-300" htmlFor="model">
					Primary model
					<select
						id="model"
						value={model}
						onChange={(event) => setModel(event.target.value)}
						className="rounded-2xl border border-white/10 bg-black/40 p-3 text-white focus:border-purple-500 focus:outline-none"
					>
						{MODEL_OPTIONS.map((option) => (
							<option key={option.id} value={option.id} className="bg-[#050505] text-white">
								{option.label}
							</option>
						))}
					</select>
				</label>
			</div>

			<div className="grid gap-4 rounded-2xl border border-white/10 bg-black/40 p-4 text-sm text-gray-300 sm:grid-cols-3">
				<div>
					<p className="text-xs uppercase tracking-[0.3em] text-gray-500">Estimated monthly</p>
					<p className="text-3xl font-silver-garden text-white">{currency.format(Math.ceil(estimate.total))}</p>
				</div>
				<div>
					<p className="text-xs uppercase tracking-[0.3em] text-gray-500">Input tokens</p>
					<p className="text-lg text-white">{currency.format(Math.ceil(estimate.inputCost))}</p>
				</div>
				<div>
					<p className="text-xs uppercase tracking-[0.3em] text-gray-500">Output tokens</p>
					<p className="text-lg text-white">{currency.format(Math.ceil(estimate.outputCost))}</p>
				</div>
			</div>
			<p className="text-xs text-gray-500">
				Assumes ~2.5k tokens per message split evenly between input/output. Adjust the slider to match
				your workload — 100 msgs/day on GPT-3.5 is roughly $15 per month.
			</p>
		</GlassCard>
	);
}
