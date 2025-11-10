import type { Metadata } from 'next';
import Link from 'next/link';
import { CloudCog, GraduationCap, HandshakeIcon } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard } from '@/components/marketing/page-shell';

const partnershipTypes = [
	{
		title: 'Technology partners',
		description: 'AI model providers, infrastructure vendors, integration partners.',
		benefits: ['Reach the PocketLLM user base', 'Co-marketing opportunities', 'Technical collaboration'],
		icon: CloudCog,
	},
	{
		title: 'Community partners',
		description: 'Educational institutions, non-profits, developer communities.',
		benefits: ['Free access for students', 'Custom deployments', 'Support for classrooms and hackathons'],
		icon: GraduationCap,
	},
	{
		title: 'Sponsorship',
		description: 'Fund open-source development and get brand exposure.',
		benefits: ['Logo on website & GitHub', 'Priority support', 'Influence roadmap priorities'],
		icon: HandshakeIcon,
	},
];

const sponsorshipTiers = [
	{ tier: 'Bronze', price: '$500/mo' },
	{ tier: 'Silver', price: '$1000/mo' },
	{ tier: 'Gold', price: '$2500/mo' },
];

export const metadata: Metadata = {
	title: 'Partnerships · PocketLLM',
	description: 'Collaborate with PocketLLM to bring privacy-first AI to more people.',
};

export default function PartnershipsPage() {
	return (
		<PageShell>
			<PageHero kicker="Partnerships" title="Partner with us" subtitle="Collaborate to bring AI to more people." />

			<PageSection title="Partnership types">
				<div className="grid gap-6 md:grid-cols-2">
					{partnershipTypes.map((type) => (
						<GlassCard key={type.title} className="space-y-3">
							<div className="flex items-center gap-3">
								<type.icon className="size-6 text-purple-300" />
								<h3 className="text-xl font-semibold text-white">{type.title}</h3>
							</div>
							<p className="text-sm text-gray-300">{type.description}</p>
							<ul className="space-y-1 text-sm text-gray-400">
								{type.benefits.map((benefit) => (
									<li key={benefit}>• {benefit}</li>
								))}
							</ul>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Sponsorship tiers">
				<div className="grid gap-4 sm:grid-cols-3">
					{sponsorshipTiers.map((tier) => (
						<GlassCard key={tier.tier} className="space-y-2 text-center">
							<p className="text-sm uppercase tracking-[0.4em] text-gray-400">{tier.tier}</p>
							<p className="text-2xl font-silver-garden text-white">{tier.price}</p>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Current partners">
				<GlassCard className="text-center text-sm text-gray-400">Looking for our first partners!</GlassCard>
			</PageSection>

			<PageSection title="Interested?" align="center">
				<GlassCard className="space-y-4 text-center">
					<p className="text-gray-300">
						Email partners@pocketllm.com with your company, partnership type, and proposed collaboration.
					</p>
					<Link href="mailto:partners@pocketllm.com" className="text-sm font-semibold text-purple-200">
						partners@pocketllm.com
					</Link>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
