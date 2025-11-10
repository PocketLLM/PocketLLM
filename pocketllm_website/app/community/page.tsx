import type { Metadata } from 'next';
import Link from 'next/link';
import { MessageCircle, UsersRound } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const communityLinks = [
	{ label: 'GitHub Discussions', href: 'https://github.com/PocketLLM/PocketLLM/discussions' },
	{ label: 'Discord (coming soon)', href: '#' },
	{ label: 'Twitter/X @PocketLLM', href: 'https://twitter.com/PocketLLM' },
	{ label: 'Reddit r/PocketLLM', href: '#' },
];

const topics = ['Getting Started Help', 'Feature Requests', 'Model Comparisons', 'Tips & Tricks', 'Show & Tell'];

export const metadata: Metadata = {
	title: 'Community · PocketLLM',
	description: 'Connect with other PocketLLM users, share tips, and get help.',
};

export default function CommunityPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Community"
				title="PocketLLM community"
				subtitle="Our community forum is coming soon. Join the conversation across GitHub, social, and real-time chats in the meantime."
			/>

			<PageSection title="Join our community">
				<GlassCard className="space-y-4">
					<p className="text-sm text-gray-300">
						We&apos;re rolling out a dedicated forum. Until then, hop into these channels, ask questions, and share what you&apos;re building.
					</p>
					<div className="flex flex-wrap gap-3">
						{communityLinks.map((link) => (
							<Link key={link.label} href={link.href} target={link.href.startsWith('http') ? '_blank' : undefined} rel={link.href.startsWith('http') ? 'noreferrer' : undefined} className="rounded-full border border-white/10 px-4 py-2 text-sm text-purple-200">
								{link.label}
							</Link>
						))}
					</div>
				</GlassCard>
			</PageSection>

			<PageSection title="Popular topics">
				<div className="grid gap-4 sm:grid-cols-2">
					{topics.map((topic) => (
						<GlassCard key={topic} className="flex items-center gap-3">
							<MessageCircle className="size-5 text-purple-300" />
							<p className="text-sm text-white">{topic}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-4 text-center">
					<UsersRound className="mx-auto size-10 text-purple-300" />
					<GradientPill className="mx-auto">Coming soon</GradientPill>
					<p className="text-gray-300">Dedicated forum with topic categories, search, and badges is under active development. Stay tuned!</p>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
