import type { Metadata } from 'next';
import { Hammer, Sparkles } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const roadmap = [
	{
		label: 'Q3 2024',
		status: 'completed',
		items: [
			'Multi-provider support (OpenAI, Google, Groq, Ollama)',
			'Cross-platform apps (iOS, Android, Desktop)',
			'Model switching with context preservation',
			'Streaming responses',
			'API key encryption',
			'Open source release (MIT)',
		],
	},
	{
		label: 'Q4 2024',
		status: 'completed',
		items: [
			'Image generation (DALL·E 2/3)',
			'FastAPI backend with Supabase',
			'Cross-device sync',
			'Prompt enhancement',
			'Material 3 redesign',
			'Web app launch',
		],
	},
	{
		label: 'Q1 2025',
		status: 'in-progress',
		items: [
			'Voice input & speech-to-text',
			'Image upload & vision models',
			'Conversation export (PDF, Markdown)',
			'Plugin system architecture',
			'Dark/Light theme toggle',
		],
	},
	{
		label: 'Q2 2025',
		status: 'planned',
		items: [
			'Shared conversations',
			'Team workspaces',
			'Custom model endpoints',
			'Conversation branching',
			'Mobile widgets',
		],
	},
	{
		label: 'Q3 2025',
		status: 'planned',
		items: [
			'Video generation support',
			'Multi-modal conversations',
			'API marketplace',
			'Desktop tray agent',
			'Keyboard shortcuts customization',
		],
	},
	{
		label: 'Future',
		status: 'future',
		items: [
			'Browser extension',
			'VS Code extension',
			'Slack/Discord integration',
			'Self-hosted backend option',
			'Enterprise features',
		],
	},
];

export const metadata: Metadata = {
	title: 'Roadmap · PocketLLM',
	description: 'See what the PocketLLM team has shipped, is building, and is planning next.',
};

export default function RoadmapPage() {
	return (
		<PageShell>
			<PageHero kicker="Roadmap" title="Product roadmap" subtitle="See what we&apos;re building next." />

			<PageSection title="Timeline">
				<div className="space-y-6">
					{roadmap.map((section) => (
						<div key={section.label} className="flex gap-4">
							<div className="flex flex-col items-center">
								<div className="rounded-full border border-white/20 p-2">
									{section.status === 'completed' ? (
										<span className="text-green-300">✓</span>
									) : section.status === 'in-progress' ? (
										<Hammer className="size-4 text-yellow-300" />
									) : (
										<Sparkles className="size-4 text-purple-300" />
									)}
								</div>
								<div className="h-full w-px bg-white/10" />
							</div>
							<GlassCard className="flex-1 space-y-3">
								<div className="flex items-center gap-3">
									<h3 className="text-xl font-semibold text-white">{section.label}</h3>
									<GradientPill>{section.status.replace('-', ' ')}</GradientPill>
								</div>
								<ul className="space-y-2 text-sm text-gray-300">
									{section.items.map((item) => (
										<li key={item}>• {item}</li>
									))}
								</ul>
							</GlassCard>
						</div>
					))}
				</div>
			</PageSection>

			<PageSection title="Community input" align="center">
				<GlassCard className="space-y-3 text-center">
					<p className="text-sm text-gray-300">Have a feature request?</p>
					<a href="https://github.com/PocketLLM/PocketLLM/issues" target="_blank" rel="noreferrer" className="text-sm font-semibold text-purple-200">
						Submit on GitHub Issues →
					</a>
				</GlassCard>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-3 text-center">
					<p className="text-sm text-gray-300">Want to help build these features?</p>
					<a href="/careers" className="text-sm font-semibold text-purple-200">
						View contributing guide →
					</a>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
