import type { Metadata } from 'next';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';

const contacts = [
	{ title: 'General inquiries', email: 'hello@pocketllm.com', response: '2-3 business days' },
	{ title: 'Support', email: 'support@pocketllm.com', response: '24-48 hours · also visit /support' },
	{ title: 'Security issues', email: 'security@pocketllm.com', response: 'Critical issues responded within 24h' },
	{ title: 'Partnerships', email: 'partners@pocketllm.com', response: 'Business partnerships, co-marketing' },
	{ title: 'Press & media', email: 'press@pocketllm.com', response: 'Press kit available on request' },
];

export const metadata: Metadata = {
	title: 'Contact · PocketLLM',
	description: 'Reach the PocketLLM team for general inquiries, support, security, partnerships, or press.',
};

export default function ContactPage() {
	return (
		<PageShell>
			<PageHero kicker="Contact" title="We&apos;d love to hear from you" subtitle="Pick the inbox that fits or send us a message below." />

			<PageSection title="Contact options">
				<div className="grid gap-6 md:grid-cols-2">
					{contacts.map((contact) => (
						<GlassCard key={contact.title} className="space-y-2">
							<h3 className="text-lg font-semibold text-white">{contact.title}</h3>
							<p className="text-sm text-purple-200">{contact.email}</p>
							<p className="text-xs uppercase tracking-[0.3em] text-gray-500">{contact.response}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Send a message">
				<GlassCard className="space-y-4">
					<form className="grid gap-4">
						<div className="grid gap-2">
							<label className="text-sm text-gray-400" htmlFor="name">
								Name
							</label>
							<input id="name" name="name" placeholder="Ada Lovelace" className="rounded-2xl border border-white/10 bg-black/30 px-4 py-3 text-white" />
						</div>
						<div className="grid gap-2">
							<label className="text-sm text-gray-400" htmlFor="email">
								Email
							</label>
							<input id="email" name="email" type="email" placeholder="you@example.com" className="rounded-2xl border border-white/10 bg-black/30 px-4 py-3 text-white" />
						</div>
						<div className="grid gap-2">
							<label className="text-sm text-gray-400" htmlFor="type">
								Type
							</label>
							<select id="type" name="type" className="rounded-2xl border border-white/10 bg-black/30 px-4 py-3 text-white">
								<option>General</option>
								<option>Support</option>
								<option>Partnership</option>
								<option>Press</option>
							</select>
						</div>
						<div className="grid gap-2">
							<label className="text-sm text-gray-400" htmlFor="subject">
								Subject
							</label>
							<input id="subject" name="subject" placeholder="How can we collaborate?" className="rounded-2xl border border-white/10 bg-black/30 px-4 py-3 text-white" />
						</div>
						<div className="grid gap-2">
							<label className="text-sm text-gray-400" htmlFor="message">
								Message
							</label>
							<textarea id="message" name="message" rows={4} placeholder="Tell us more..." className="rounded-2xl border border-white/10 bg-black/30 px-4 py-3 text-white" />
						</div>
						<button type="submit" className="rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white">
							Send message
						</button>
					</form>
				</GlassCard>
			</PageSection>

			<PageSection title="Social">
				<GlassCard className="flex flex-wrap gap-3 text-sm text-purple-200">
					<a href="https://twitter.com/PocketLLM" target="_blank" rel="noreferrer">
						Twitter/X
					</a>
					<a href="https://github.com/PocketLLM/PocketLLM" target="_blank" rel="noreferrer">
						GitHub
					</a>
					<a href="#">LinkedIn</a>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
