import type { Metadata } from 'next';
import Link from 'next/link';
import { Code2, MessageCircle, Palette, PenTool } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';

const contributions = [
	{
		title: 'Code contributions',
		description: 'Fix bugs, add features, improve performance, and harden security.',
		icon: Code2,
	},
	{
		title: 'Documentation',
		description: 'Write guides, improve docs, and create tutorials for new users.',
		icon: PenTool,
	},
	{
		title: 'Design',
		description: 'Shape UI/UX, craft icons, and produce marketing visuals.',
		icon: Palette,
	},
	{
		title: 'Community',
		description: 'Help users, moderate discussions, and create educational content.',
		icon: MessageCircle,
	},
];

const reasons = ['Build your portfolio', 'Ship with Flutter + FastAPI', 'Join a fast-growing open-source community', 'Make a privacy-first impact', 'Get recognized on the contributors page'];

export const metadata: Metadata = {
	title: 'Careers · PocketLLM',
	description: 'PocketLLM is an open-source project. Learn how to contribute and help build the future of AI interaction.',
};

export default function CareersPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Careers"
				title="Help us build the future of AI interaction"
				subtitle="PocketLLM is open source and community-driven. There are no traditional job openings — instead, we collaborate in the open."
			/>

			<PageSection title="We&apos;re open source!">
				<GlassCard className="space-y-3 text-sm text-gray-300">
					<p>PocketLLM thrives on community contributors. Whether you&apos;re into Flutter, backend APIs, docs, or storytelling, there&apos;s a place for you.</p>
					<p>
						Start with our{' '}
						<Link href="https://github.com/PocketLLM/PocketLLM/blob/main/CONTRIBUTING.md" target="_blank" rel="noreferrer" className="text-purple-200 underline">
							CONTRIBUTING.md
						</Link>{' '}
						and say hi on GitHub Discussions.
					</p>
				</GlassCard>
			</PageSection>

			<PageSection title="How to contribute">
				<div className="grid gap-6 md:grid-cols-2">
					{contributions.map((item) => (
						<GlassCard key={item.title} className="space-y-2">
							<div className="flex items-center gap-3">
								<item.icon className="size-6 text-purple-300" />
								<h3 className="text-lg font-semibold text-white">{item.title}</h3>
							</div>
							<p className="text-sm text-gray-300">{item.description}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Why contribute?">
				<GlassCard className="space-y-2 text-sm text-gray-300">
					{reasons.map((reason) => (
						<p key={reason}>• {reason}</p>
					))}
				</GlassCard>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-4 text-center">
					<p className="text-sm uppercase tracking-[0.4em] text-gray-400">Jump in</p>
					<h3 className="text-3xl font-silver-garden text-white">View contributing guide</h3>
					<Link href="https://github.com/PocketLLM/PocketLLM/blob/main/CONTRIBUTING.md" target="_blank" rel="noreferrer" className="inline-flex items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white">
						Start contributing
					</Link>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
