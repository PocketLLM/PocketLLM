import type { Metadata } from 'next';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';

const summary = [
	'PocketLLM is free and open source under the MIT License.',
	'You own your data and API keys — bring your own provider billing.',
	'The app is provided “as is” with no warranties or guarantees of uptime.',
	'Use responsibly, follow provider terms, and comply with applicable laws.',
];

const termsSections = [
	{
		title: '1. Acceptance of terms',
		content: [
			'By using PocketLLM you agree to these Terms of Service. You must be 13+ or have parental consent.',
		],
	},
	{
		title: '2. Description of service',
		content: [
			'PocketLLM is a multi-platform AI chat client connecting to OpenAI, Google, Groq, and local Ollama models.',
			'The software is free, open source, and community-maintained.',
		],
	},
	{
		title: '3. User accounts',
		content: [
			'Provide accurate information during signup and keep credentials secure.',
			'You are responsible for activity that occurs under your account.',
		],
	},
	{
		title: '4. User responsibilities',
		content: [
			'Bring and manage your own API keys; PocketLLM never bills you.',
			'Pay providers directly for usage and respect their acceptable-use policies.',
			'Do not abuse, spam, or attempt to disrupt the service or other users.',
		],
	},
	{
		title: '5. API keys & third-party services',
		content: [
			'PocketLLM helps you store keys securely but does not control billing or rate limits.',
			'You remain responsible for charges from OpenAI, Google, Groq, and other providers.',
		],
	},
	{
		title: '6. Intellectual property',
		content: [
			'PocketLLM source code is MIT Licensed.',
			'You own your chats and uploaded content. PocketLLM retains branding rights over logos and trademarks.',
		],
	},
	{
		title: '7. Disclaimer of warranties',
		content: [
			'The software is provided “as is” without warranties of any kind, express or implied.',
		],
	},
	{
		title: '8. Limitation of liability',
		content: [
			'PocketLLM is not liable for damages, data loss, or provider outages. Use at your own risk.',
		],
	},
	{
		title: '9. Termination',
		content: [
			'You can delete your account at any time. We may suspend access for violations of these terms.',
		],
	},
	{
		title: '10. Governing law',
		content: ['These terms are governed by the laws of your local jurisdiction unless otherwise required.'],
	},
	{
		title: '11. Changes',
		content: ['We may update these terms and will notify users when material changes occur.'],
	},
	{
		title: '12. Contact',
		content: ['Email legal@pocketllm.com with questions about these terms.'],
	},
];

export const metadata: Metadata = {
	title: 'Terms of Service · PocketLLM',
	description: 'Understand the legal terms that apply when you use PocketLLM.',
};

export default function TermsPage() {
	return (
		<PageShell>
			<PageHero kicker="Terms of service" title="Use PocketLLM responsibly" subtitle="Last updated: February 18, 2025" align="left" />

			<PageSection title="Summary">
				<GlassCard>
					<ul className="space-y-3 text-sm text-gray-300">
						{summary.map((item) => (
							<li key={item} className="flex items-start gap-3">
								<span className="mt-1 size-2 rounded-full bg-pink-400" />
								{item}
							</li>
						))}
					</ul>
				</GlassCard>
			</PageSection>

			<PageSection title="Full terms">
				<div className="space-y-6">
					{termsSections.map((section) => (
						<GlassCard key={section.title} className="space-y-3">
							<h3 className="text-xl font-semibold text-white">{section.title}</h3>
							<ul className="space-y-2 text-sm text-gray-300">
								{section.content.map((item) => (
									<li key={item}>{item}</li>
								))}
							</ul>
						</GlassCard>
					))}
				</div>
			</PageSection>
		</PageShell>
	);
}
