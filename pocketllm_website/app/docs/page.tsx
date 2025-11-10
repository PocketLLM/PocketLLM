import type { Metadata } from 'next';
import Link from 'next/link';
import { BookOpen, PlugZap, Settings, Wrench, Workflow } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const docSections = [
	{
		title: 'Getting Started',
		items: ['Installation', 'First-time setup', 'Account creation', 'Basic usage'],
		icon: BookOpen,
	},
	{
		title: 'Provider Setup',
		items: ['OpenAI configuration', 'Google Gemini setup', 'Groq setup', 'Ollama installation'],
		icon: PlugZap,
	},
	{
		title: 'Features',
		items: ['Model switching', 'Chat organization', 'Image generation', 'Prompt enhancement'],
		icon: Settings,
	},
	{
		title: 'Advanced',
		items: ['Self-hosting guide', 'API docs', 'Custom endpoints', 'Troubleshooting'],
		icon: Wrench,
	},
	{
		title: 'Development',
		items: ['Contributing guide', 'Architecture overview', 'Building from source', 'API reference'],
		icon: Workflow,
	},
];

const quickStart = ['Download the app', 'Create an account', 'Add your API keys', 'Start chatting'];

export const metadata: Metadata = {
	title: 'Documentation · PocketLLM',
	description: 'Everything you need to install, configure, and build with PocketLLM.',
};

export default function DocsPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Documentation"
				title="Everything you need to get started"
				subtitle="Guides, API references, and contributor docs for PocketLLM."
			/>

			<PageSection>
				<GlassCard className="space-y-4">
					<GradientPill>Quick start guide</GradientPill>
					<ol className="list-decimal space-y-2 pl-5 text-sm text-gray-200">
						{quickStart.map((step) => (
							<li key={step}>{step}</li>
						))}
					</ol>
					<Link href="/docs" className="text-sm font-semibold text-purple-200">
						Read quick start →
					</Link>
				</GlassCard>
			</PageSection>

			<PageSection title="Doc library">
				<div className="grid gap-6 md:grid-cols-2">
					{docSections.map((section) => (
						<GlassCard key={section.title} className="space-y-3">
							<div className="flex items-center gap-3">
								<section.icon className="size-6 text-purple-300" />
								<h3 className="text-xl font-semibold text-white">{section.title}</h3>
							</div>
							<ul className="space-y-1 text-sm text-gray-300">
								{section.items.map((item) => (
									<li key={item}>{item}</li>
								))}
							</ul>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Useful links">
				<GlassCard className="flex flex-wrap gap-4 text-sm text-purple-200">
					<Link href="https://github.com/PocketLLM/PocketLLM/tree/main/docs" target="_blank" rel="noreferrer">
						Full docs on GitHub
					</Link>
					<Link href="/api-reference">API Reference page</Link>
					<Link href="/community">Community forum / Discord</Link>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
