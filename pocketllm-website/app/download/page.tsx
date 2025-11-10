import type { Metadata } from 'next';
import Link from 'next/link';
import { Smartphone, Apple, Download, Globe, Laptop, MonitorSmartphone } from 'lucide-react';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const platforms = [
	{
		name: 'iOS & iPadOS',
		icon: Apple,
		requirements: 'iOS 12.0+',
		size: '~20 MB',
		cta: 'Coming soon',
	},
	{
		name: 'Android',
		icon: Smartphone,
		requirements: 'Android 7.0+ (API 24)',
		size: '~20 MB',
		cta: 'Coming soon',
	},
	{
		name: 'macOS',
		icon: Laptop,
		requirements: 'macOS 10.14+',
		size: '~50 MB',
		cta: 'Download for Mac',
	},
	{
		name: 'Windows',
		icon: MonitorSmartphone,
		requirements: 'Windows 10+',
		size: '~45 MB',
		cta: 'Download for Windows',
	},
	{
		name: 'Linux',
		icon: Download,
		requirements: 'Ubuntu 20.04+, Debian 11+',
		size: '.deb · .AppImage · .tar.gz',
		cta: 'Download for Linux',
	},
];

const installHelp = [
	{ label: 'Setup guides', href: '/docs' },
	{ label: 'System requirements', href: '/docs' },
	{ label: 'FAQ', href: '/support#faq' },
];

export const metadata: Metadata = {
	title: 'Download PocketLLM',
	description: 'Get PocketLLM on iOS, Android, macOS, Windows, Linux, or launch the web app instantly.',
};

export default function DownloadPage() {
	return (
		<PageShell>
			<PageHero
				kicker="Download"
				title="Run PocketLLM anywhere"
				subtitle="Install native apps for every platform or launch instantly in the browser. All versions share the same secure sync and model support."
			/>

			<PageSection title="Native apps" description="Choose your platform. Desktop builds include Intel + Apple Silicon where available.">
				<div className="grid gap-6 md:grid-cols-2">
					{platforms.map((platform) => (
						<GlassCard key={platform.name} className="space-y-4">
							<div className="flex items-center gap-3">
								<platform.icon className="size-6 text-purple-300" />
								<div>
									<h3 className="text-xl font-semibold text-white">{platform.name}</h3>
									<p className="text-sm text-gray-400">{platform.requirements}</p>
								</div>
							</div>
							<p className="text-sm text-gray-300">{platform.size}</p>
							<button
								type="button"
								className="w-full rounded-2xl border border-white/10 px-4 py-3 text-sm font-semibold text-white/80"
								disabled
							>
								{platform.cta}
							</button>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Use it in your browser" align="center">
				<GlassCard className="space-y-4 text-center">
					<Globe className="mx-auto size-10 text-purple-300" />
					<p className="text-sm uppercase tracking-[0.4em] text-gray-400">No install needed</p>
					<h3 className="text-3xl font-silver-garden text-white">Launch the web app</h3>
					<p className="text-gray-300">Fire up PocketLLM directly in the browser for quick demos or testing.</p>
					<Link href="https://pocket-llm-website.vercel.app/#demo" target="_blank" rel="noreferrer" className="inline-flex items-center justify-center rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-6 py-3 text-sm font-semibold text-white">
						Launch web app
					</Link>
				</GlassCard>
			</PageSection>

			<PageSection title="Installation help">
				<GlassCard className="flex flex-wrap gap-4">
					{installHelp.map((item) => (
						<Link key={item.label} href={item.href} className="rounded-full border border-white/10 px-4 py-2 text-sm text-purple-200">
							{item.label}
						</Link>
					))}
				</GlassCard>
			</PageSection>

			<PageSection>
				<GlassCard className="space-y-2">
					<GradientPill>GitHub releases</GradientPill>
					<p className="text-sm text-gray-300">
						Looking for beta builds or nightly artifacts? Grab the latest assets on GitHub Releases.
					</p>
					<Link href="https://github.com/PocketLLM/PocketLLM/releases" target="_blank" rel="noreferrer" className="text-sm font-semibold text-purple-200">
						github.com/PocketLLM/PocketLLM/releases →
					</Link>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
