import type { Metadata } from 'next';
import { Calendar, Tag } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const posts = [
	{ title: 'Announcing PocketLLM 1.0', date: 'March 2025', summary: 'First stable release with multi-provider support.', tag: 'Announcement' },
	{ title: 'How to Save 80% on AI Costs', date: 'February 2025', summary: 'Smart model switching strategies across providers.', tag: 'Tutorial' },
	{ title: 'Privacy-First AI: Why It Matters', date: 'January 2025', summary: 'Our approach to encrypted conversations and BYOK.', tag: 'Philosophy' },
];

const categories = ['Announcements', 'Tutorials', 'Tips & Tricks', 'Behind the Scenes'];

export const metadata: Metadata = {
	title: 'Blog · PocketLLM',
	description: 'Updates, tutorials, and insights from the PocketLLM team.',
};

export default function BlogPage() {
	return (
		<PageShell>
			<PageHero kicker="Blog" title="PocketLLM Blog" subtitle="Updates, tutorials, and insights." />

			<PageSection>
				<GlassCard className="space-y-4 text-center">
					<GradientPill className="mx-auto">Coming soon</GradientPill>
					<p className="text-gray-300">We&apos;re polishing the new blog experience. In the meantime, here&apos;s what&apos;s on the editorial calendar.</p>
				</GlassCard>
			</PageSection>

			<PageSection title="Upcoming posts">
				<div className="space-y-6">
					{posts.map((post) => (
						<GlassCard key={post.title} className="space-y-2">
							<div className="flex items-center gap-3 text-xs uppercase tracking-[0.3em] text-gray-400">
								<Calendar className="size-4" />
								{post.date}
							</div>
							<div className="flex flex-wrap items-center gap-3">
								<h3 className="text-2xl font-silver-garden text-white">{post.title}</h3>
								<span className="inline-flex items-center gap-1 rounded-full border border-white/10 px-3 py-1 text-xs text-purple-200">
									<Tag className="size-3" />
									{post.tag}
								</span>
							</div>
							<p className="text-sm text-gray-300">{post.summary}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Categories">
				<GlassCard className="flex flex-wrap gap-3 text-sm text-purple-200">
					{categories.map((category) => (
						<span key={category} className="rounded-full border border-white/10 px-4 py-2">
							{category}
						</span>
					))}
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
