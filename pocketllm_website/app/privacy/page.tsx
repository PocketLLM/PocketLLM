import type { Metadata } from 'next';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const summaryPoints = [
	'We collect only what is necessary (email + encrypted API keys)',
	'Chats stay private with optional Supabase sync',
	'We never sell or rent personal data',
	'You can export or delete your account anytime',
	'Open-source codebase for full transparency',
];

const privacySections = [
	{
		title: '1. Information we collect',
		content: [
			'Account information such as email and password hash to authenticate you securely.',
			'API keys you provide (OpenAI, Google, Groq, etc.) are encrypted with Fernet before storage.',
			'Chat history is encrypted and syncing is optional — local-only mode never leaves your device.',
			'Anonymous usage analytics are opt-in only and stripped of personal data.',
		],
	},
	{
		title: '2. How we use information',
		content: [
			'To deliver the core PocketLLM experience across devices.',
			'To sync chats, settings, and models you explicitly enable.',
			'To improve reliability, security, and product usability.',
			'To prevent fraud and keep your account safe.',
		],
	},
	{
		title: '3. Data storage',
		content: [
			'Supabase (PostgreSQL) stores account data with row-level security policies.',
			'Encryption at rest via Fernet and managed keys.',
			'Regular encrypted backups with strict access controls.',
		],
	},
	{
		title: '4. Data sharing',
		content: [
			'We do not sell personal data, ever.',
			'Third parties are limited to AI providers you configure (OpenAI, Google, Groq, Ollama).',
			'We only disclose information when legally required.',
		],
	},
	{
		title: '5. Your rights',
		content: [
			'Access or export your data anytime from Settings.',
			'Delete your account via DELETE /users/profile in the API or inside the app.',
			'Opt out of analytics and marketing emails.',
		],
	},
	{
		title: '6. Cookies',
		content: [
			'Essential cookies keep you signed in.',
			'No advertising or tracking pixels.',
		],
	},
	{
		title: "7. Children's privacy",
		content: ['PocketLLM is not intended for children under 13. Parental consent is required in applicable regions.'],
	},
	{
		title: '8. Changes to this policy',
		content: ['We will notify you via email and changelog updates. Continued use after an update counts as acceptance.'],
	},
	{
		title: '9. Contact',
		content: ['Questions? Email privacy@pocketllm.com'],
	},
];

export const metadata: Metadata = {
	title: 'Privacy Policy · PocketLLM',
	description: 'PocketLLM is committed to privacy-first AI. Learn how we collect, store, and protect your data.',
};

export default function PrivacyPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Privacy policy"
				title="Privacy you can inspect"
				subtitle="Last updated: February 18, 2025"
				align="left"
			/>

			<PageSection title="At a glance">
				<GlassCard>
					<ul className="space-y-3 text-sm text-gray-300">
						{summaryPoints.map((point) => (
							<li key={point} className="flex items-start gap-3">
								<span className="mt-1 size-2 rounded-full bg-purple-400" />
								{point}
							</li>
						))}
					</ul>
				</GlassCard>
			</PageSection>

			<PageSection title="Full policy">
				<div className="space-y-6">
					{privacySections.map((section) => (
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

			<PageSection>
				<GlassCard className="space-y-4">
					<GradientPill>Compliance</GradientPill>
					<p className="text-sm text-gray-300">
						PocketLLM aligns with GDPR and CCPA requirements, supports data access requests, and offers an open-source audit trail. For privacy questions or data requests, contact privacy@pocketllm.com.
					</p>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
