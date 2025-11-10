import type { Metadata } from 'next';
import Link from 'next/link';
import { Code2, MonitorSmartphone, Settings2, ShieldCheck, Users } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill, StatPill } from '@/components/marketing/page-shell';

const values = [
	{
		title: 'Privacy First',
		icon: ShieldCheck,
		bullets: ['Your data belongs to you', 'End-to-end encryption', 'Local-only mode available', 'No tracking or ads'],
	},
	{
		title: 'Open Source',
		icon: Code2,
		bullets: ['MIT License', 'Community-driven roadmap', 'Transparent development', 'Auditable codebase'],
	},
	{
		title: 'Multi-Platform',
		icon: MonitorSmartphone,
		bullets: ['iOS, Android, Desktop, Web', 'Cross-device sync', 'Native performance', 'Consistent UX'],
	},
	{
		title: 'User Control',
		icon: Settings2,
		bullets: ['Bring your own API keys', 'Choose providers', 'Control costs', 'Own your conversations'],
	},
];

const techStack = [
	{ label: 'Frontend', value: 'Flutter 3.19.6 · Riverpod · Material 3' },
	{ label: 'Backend', value: 'FastAPI · NestJS' },
	{ label: 'Database', value: 'Supabase (PostgreSQL)' },
	{ label: 'Security', value: 'Fernet encryption · JWT' },
	{ label: 'Hosting', value: 'Vercel' },
];

export const metadata: Metadata = {
	title: 'About PocketLLM',
	description: 'Learn about PocketLLM’s mission, values, and community building a privacy-first AI assistant for everyone.',
};

export default function AboutPage() {
	return (
		<PageShell>
			<PageHero
				kicker="About us"
				title="Building the future of AI interaction"
				subtitle="PocketLLM is an open-source, privacy-first AI assistant that puts you in control. We believe everyone should be able to run any model, on any device, without giving up their data."
				align="left"
				actions={
					<div className="flex flex-wrap gap-4">
						<Link href="https://github.com/PocketLLM/PocketLLM" target="_blank" rel="noreferrer" className="rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white">
							View on GitHub
						</Link>
						<Link href="/careers" className="rounded-full border border-white/20 px-6 py-3 text-sm font-semibold text-white/80">
							Contribute
						</Link>
					</div>
				}
			/>

			<PageSection>
				<div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
					<GlassCard className="space-y-4">
						<GradientPill>Our Mission</GradientPill>
						<p className="text-lg text-gray-200">
							To democratize access to LLMs by creating a free, open-source platform that respects user privacy, supports multiple AI providers, and even works offline with local models.
						</p>
					</GlassCard>
					<div className="grid gap-4 sm:grid-cols-2">
						<StatPill label="Lead" value="Prashant Ch." subtle="@Mr-Dark-debug" />
						<StatPill label="Contributors" value="3+" subtle="Community builders" />
						<StatPill label="GitHub Stars" value="17+" subtle="Growing fast" />
						<StatPill label="Platforms" value="6" subtle="iOS · Android · Web · Desktop" />
					</div>
				</div>
			</PageSection>

			<PageSection title="Our values" description="Guiding principles that inform the product, the roadmap, and every community decision.">
				<div className="grid gap-6 md:grid-cols-2">
					{values.map((value) => (
						<GlassCard key={value.title} className="space-y-4">
							<div className="flex items-center gap-3">
								<value.icon className="size-6 text-purple-300" />
								<h3 className="text-xl font-semibold text-white">{value.title}</h3>
							</div>
							<ul className="space-y-2 text-sm text-gray-300">
								{value.bullets.map((bullet) => (
									<li key={bullet} className="flex items-center gap-2">
										<span className="size-1 rounded-full bg-purple-400" />
										{bullet}
									</li>
								))}
							</ul>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Community-first team">
				<GlassCard className="space-y-4">
					<p className="text-gray-300">
						PocketLLM is built by community contributors across time zones. Core maintainer Prashant Choudhary (@Mr-Dark-debug) leads architecture, with new pull requests landing weekly. View everyone&apos;s impact on
						{' '}
						<Link href="https://github.com/PocketLLM/PocketLLM/graphs/contributors" target="_blank" rel="noreferrer" className="text-purple-300 underline">
							GitHub contributors →
						</Link>
						.
					</p>
					<div className="flex flex-wrap gap-4 text-sm text-gray-400">
						<span className="rounded-full border border-white/10 px-4 py-2">Open-source governance</span>
						<span className="rounded-full border border-white/10 px-4 py-2">Weekly community calls</span>
						<span className="rounded-full border border-white/10 px-4 py-2">Transparent roadmap</span>
					</div>
				</GlassCard>
			</PageSection>

			<PageSection title="Tech stack">
				<div className="grid gap-4 sm:grid-cols-2">
					{techStack.map((item) => (
						<GlassCard key={item.label} className="space-y-2">
							<p className="text-xs uppercase tracking-[0.3em] text-gray-500">{item.label}</p>
							<p className="text-lg text-white">{item.value}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-4 text-center">
					<p className="text-sm uppercase tracking-[0.4em] text-gray-400">Ready to build?</p>
					<h3 className="text-3xl font-silver-garden text-white">Join the mission</h3>
					<p className="text-gray-300">
						Jump into the repo, pick an issue, or reach out with your own ideas. Documentation, code, design, and community leadership are all welcome.
					</p>
					<div className="flex flex-wrap items-center justify-center gap-4">
						<Link href="/docs" className="rounded-full bg-white/10 px-6 py-3 text-sm font-semibold text-white">
							Read the docs
						</Link>
						<Link href="/contact" className="text-sm font-semibold text-purple-200">
							Say hello →
						</Link>
					</div>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
