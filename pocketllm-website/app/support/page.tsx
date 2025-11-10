import type { Metadata } from 'next';
import Link from 'next/link';
import { Book, Bug, HelpCircle, Users } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

const quickLinks = [
	{ title: 'Documentation', description: 'Read our comprehensive guides', href: '/docs', icon: Book },
	{ title: 'FAQ', description: 'Common questions answered', href: '#faq', icon: HelpCircle },
	{ title: 'GitHub Issues', description: 'Report bugs or request features', href: 'https://github.com/PocketLLM/PocketLLM/issues', icon: Bug },
	{ title: 'Community', description: 'Ask the PocketLLM community', href: '/community', icon: Users },
];

const faqSections = [
	{
		title: 'General',
		items: [
			{ question: 'Is PocketLLM really free?', answer: 'Yes! PocketLLM is 100% free and open source. You only pay for API usage directly to providers like OpenAI.' },
			{ question: 'What platforms are supported?', answer: 'iOS, Android, macOS, Windows, Linux, and the Web.' },
			{ question: 'Do I need an API key?', answer: 'Yes. Add keys from OpenAI, Google, or Groq, or run Ollama locally with no key.' },
		],
	},
	{
		title: 'Setup',
		items: [
			{ question: 'How do I get an OpenAI API key?', answer: 'Visit platform.openai.com/api-keys and create a new key. Paste it into PocketLLM settings.' },
			{ question: 'Can I use PocketLLM offline?', answer: 'Yes. Install Ollama and run supported models entirely on-device.' },
			{ question: 'How do I switch models?', answer: 'Use the model dropdown at the top of the chat interface or assign per-conversation defaults.' },
		],
	},
	{
		title: 'Privacy & troubleshooting',
		items: [
			{ question: 'Is my data secure?', answer: 'API keys are encrypted with Fernet. Supabase storage has row-level security and conversations are private.' },
			{ question: 'Can PocketLLM see my conversations?', answer: 'No. Your conversations are encrypted and only accessible to you.' },
			{ question: 'Model not responding?', answer: 'Ensure your API key is valid, has credits, and check your network connection.' },
			{ question: 'App crashing?', answer: 'Update to the latest release and open a GitHub issue with steps to reproduce.' },
		],
	},
];

export const metadata: Metadata = {
	title: 'Support · PocketLLM',
	description: 'Find answers, browse FAQs, or contact PocketLLM support.',
};

export default function SupportPage() {
	return (
		<PageShell>
			<PageHero kicker="Support" title="Get help fast" subtitle="Self-serve docs, FAQs, and direct contact options." />

			<PageSection title="Quick links">
				<div className="grid gap-6 sm:grid-cols-2">
					{quickLinks.map((link) => (
						<GlassCard key={link.title} className="space-y-2">
							<div className="flex items-center gap-3">
								<link.icon className="size-6 text-purple-300" />
								<div>
									<h3 className="text-lg font-semibold text-white">{link.title}</h3>
									<p className="text-sm text-gray-400">{link.description}</p>
								</div>
							</div>
							<Link href={link.href} className="text-sm font-semibold text-purple-200">
								Open →
							</Link>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection id="faq" title="FAQ" description="Answers to the questions we hear every day.">
				<div className="space-y-6">
					{faqSections.map((section) => (
						<GlassCard key={section.title} className="space-y-4">
							<h3 className="text-xl font-semibold text-white">{section.title}</h3>
							<Accordion type="single" collapsible>
								{section.items.map((item) => (
									<AccordionItem key={item.question} value={item.question}>
										<AccordionTrigger className="text-left text-sm text-white">
											{item.question}
										</AccordionTrigger>
										<AccordionContent className="text-sm text-gray-300">
											{item.answer}
										</AccordionContent>
									</AccordionItem>
								))}
							</Accordion>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Still need help?">
				<GlassCard className="space-y-2 text-sm text-gray-300">
					<p>Email support@pocketllm.com — responses within 24-48h.</p>
					<p>For urgent issues mention severity in the subject line. Security issues? Email security@pocketllm.com.</p>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
