import type { Metadata } from 'next';
import Link from 'next/link';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';

const providerPolicies = [
	{ name: 'OpenAI', href: 'https://platform.openai.com/docs/billing' },
	{ name: 'Google AI', href: 'https://cloud.google.com/support' },
	{ name: 'Groq', href: 'https://groq.com/' },
];

export const metadata: Metadata = {
	title: 'Refund Policy · PocketLLM',
	description: 'PocketLLM is free. Learn how refunds work with AI providers.',
};

export default function RefundPage() {
	return (
		<PageShell>
			<PageHero kicker="Refund policy" title="PocketLLM is free" subtitle="We never charge you. There&apos;s nothing to refund." />

			<PageSection title="What you pay for">
				<GlassCard className="space-y-3 text-sm text-gray-300">
					<p>You pay AI providers (OpenAI, Google, Groq) directly for API usage. If you need a refund for their services, contact them using the links below.</p>
					<ul className="space-y-2">
						{providerPolicies.map((provider) => (
							<li key={provider.name}>
								<Link href={provider.href} target="_blank" rel="noreferrer" className="text-purple-200">
									{provider.name}
								</Link>
								
							</li>
						))}
					</ul>
				</GlassCard>
			</PageSection>

			<PageSection title="Free options">
				<GlassCard className="space-y-2 text-sm text-gray-300">
					<p>Groq: 14,400 free requests/day</p>
					<p>Google Gemini: Free tier available</p>
					<p>Ollama: 100% free local models</p>
				</GlassCard>
			</PageSection>

			<PageSection title="Need help?">
				<GlassCard className="space-y-2 text-sm text-gray-300">
					<p>Technical problems? Visit /support.</p>
					<p>Account issues? Email support@pocketllm.com.</p>
					<p>Feature requests? Open a GitHub issue.</p>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
