import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowRight, CheckCircle2, Shield } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';
import { CostEstimator } from '@/components/marketing/cost-estimator';

const freeTierFeatures = [
	'All PocketLLM features',
	'Unlimited chats & history',
	'iOS, Android, Desktop, Web',
	'Open source (MIT) & self-hostable',
	'Community support',
	'No subscription ever',
];

const providerCosts = [
	{ provider: 'OpenAI', model: 'GPT-4 Turbo', rates: '$10 / $30 per 1M tokens', freeTier: '—' },
	{ provider: 'OpenAI', model: 'GPT-3.5', rates: '$0.50 / $1.50 per 1M tokens', freeTier: '—' },
	{ provider: 'OpenAI', model: 'DALL·E 3', rates: '$0.04 – $0.12 per image', freeTier: '—' },
	{ provider: 'Google', model: 'Gemini Pro', rates: '$0.50 / $1.50 per 1M tokens', freeTier: '✓ Free tier' },
	{ provider: 'Groq', model: 'Mixtral', rates: '$0.24 / $0.24 per 1M tokens', freeTier: '✓ 14,400 req/day' },
	{ provider: 'Groq', model: 'Llama 3', rates: '$0.05 / $0.08 per 1M tokens', freeTier: '✓ 14,400 req/day' },
	{ provider: 'Ollama', model: 'All local models', rates: 'FREE', freeTier: '✓ Unlimited local' },
];

const comparisons = [
	{ name: 'ChatGPT Plus', price: '$20/mo', detail: 'GPT-4 access only, single provider' },
	{ name: 'Claude Pro', price: '$20/mo', detail: 'Claude family only, capped usage' },
	{ name: 'PocketLLM', price: '$0 app + pay-as-you-go', detail: 'Pick any model, control spend' },
];

export const metadata: Metadata = {
	title: 'PocketLLM Pricing',
	description: 'PocketLLM is 100% free. Bring your own API keys and pay providers directly with transparent, usage-based pricing.',
};

export default function PricingPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Pricing"
				title="Simple, transparent pricing"
				subtitle="PocketLLM is permanently free. You only pay the AI providers you already trust, with zero markups or hidden fees."
				actions={
					<div className="flex flex-wrap items-center gap-4">
						<Link
							href="/download"
							className="inline-flex items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-purple-500/30"
						>
							Download Free
							<ArrowRight className="ml-2 size-4" />
						</Link>
						<Link
							href="/support"
							className="inline-flex items-center justify-center rounded-full border border-white/20 px-6 py-3 text-sm font-semibold text-white/80 hover:border-white/50"
						>
							Talk to Support
						</Link>
					</div>
				}
			/>

			<PageSection>
				<div className="grid gap-6 lg:grid-cols-[1.7fr_1fr]">
					<GlassCard className="space-y-6">
						<div className="space-y-2">
							<GradientPill>Free Tier</GradientPill>
							<h3 className="text-3xl font-semibold text-white">$0 / month · forever</h3>
							<p className="text-gray-300">Everything PocketLLM offers today and tomorrow — no credit card, no trial, no catches.</p>
						</div>
						<ul className="grid gap-3 sm:grid-cols-2">
							{freeTierFeatures.map((feature) => (
								<li key={feature} className="flex items-start gap-2 text-sm text-gray-200">
									<CheckCircle2 className="mt-0.5 size-4 text-purple-400" />
									{feature}
								</li>
							))}
						</ul>
					</GlassCard>
					<GlassCard className="space-y-4">
						<div className="flex items-center gap-3 text-purple-200">
							<Shield className="size-6" />
							<div>
								<h4 className="text-xl font-semibold text-white">You bring your own API keys</h4>
								<p className="text-sm text-gray-400">PocketLLM never proxies or stores provider billing. You connect directly to OpenAI, Google, Groq, or local Ollama.</p>
							</div>
						</div>
						<p className="text-sm text-gray-400">
							No markup. No middleman. You decide which models to enable, set your own rate limits, and can rotate keys anytime inside Settings.
						</p>
						<Link
							href="/docs"
							className="inline-flex items-center gap-2 text-sm font-semibold text-purple-300 hover:text-purple-100"
						>
							Read the setup guide
							<ArrowRight className="size-4" />
						</Link>
					</GlassCard>
				</div>
			</PageSection>

			<PageSection title="Provider cost transparency" description="Every provider posts public price sheets. PocketLLM simply helps you keep track.">
				<GlassCard className="overflow-x-auto">
					<table className="w-full text-left text-sm text-gray-200">
						<thead className="text-xs uppercase tracking-widest text-gray-400">
							<tr className="border-b border-white/10">
								<th className="py-3 pr-4">Provider</th>
								<th className="py-3 pr-4">Model</th>
								<th className="py-3 pr-4">Input / Output</th>
								<th className="py-3 pr-4">Free tier</th>
							</tr>
						</thead>
						<tbody>
							{providerCosts.map((row) => (
								<tr key={`${row.provider}-${row.model}`} className="border-b border-white/5 last:border-0">
									<td className="py-4 pr-4 font-semibold text-white">{row.provider}</td>
									<td className="py-4 pr-4">{row.model}</td>
									<td className="py-4 pr-4 text-gray-300">{row.rates}</td>
									<td className="py-4 pr-4 text-purple-200">{row.freeTier}</td>
								</tr>
							))}
						</tbody>
					</table>
				</GlassCard>
			</PageSection>

			<PageSection>
				<CostEstimator />
			</PageSection>

			<PageSection title="Compare to subscriptions" description="PocketLLM stays free, while provider pay-as-you-go keeps costs predictable." align="center">
				<div className="grid gap-6 md:grid-cols-3">
					{comparisons.map((item) => (
						<GlassCard key={item.name} className="space-y-4 text-center">
							<p className="text-sm uppercase tracking-[0.3em] text-gray-400">{item.name}</p>
							<p className="text-3xl font-silver-garden text-white">{item.price}</p>
							<p className="text-sm text-gray-300">{item.detail}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-6 text-center">
					<h3 className="text-3xl font-silver-garden text-white">Get started for $0</h3>
					<p className="text-gray-300">
						Download PocketLLM, add your provider keys later, and start chatting instantly. Configuration can wait until you&apos;re ready.
					</p>
					<div className="flex flex-wrap items-center justify-center gap-4">
						<Link
							href="/download"
							className="inline-flex items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white"
						>
							Get PocketLLM
						</Link>
						<Link href="/contact" className="text-sm font-semibold text-purple-200">
							Contact sales (open source)
						</Link>
					</div>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
