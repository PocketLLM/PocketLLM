import type { Metadata } from 'next';
import Link from 'next/link';
import { PageShell, PageHero, PageSection, GlassCard, GradientPill } from '@/components/marketing/page-shell';

const endpointGroups = [
	{
		title: 'Auth endpoints',
		endpoints: [
			{ method: 'POST', path: '/auth/signup', description: 'Create account' },
			{ method: 'POST', path: '/auth/signin', description: 'Get access token' },
			{ method: 'POST', path: '/auth/refresh', description: 'Refresh token' },
		],
	},
	{
		title: 'User endpoints',
		endpoints: [
			{ method: 'GET', path: '/users/profile', description: 'Get user profile' },
			{ method: 'PUT', path: '/users/profile', description: 'Update profile' },
			{ method: 'DELETE', path: '/users/profile', description: 'Delete account' },
		],
	},
	{
		title: 'Chat endpoints',
		endpoints: [
			{ method: 'GET', path: '/chats', description: 'List chats' },
			{ method: 'POST', path: '/chats', description: 'Create chat' },
			{ method: 'GET', path: '/chats/{id}', description: 'Get chat' },
			{ method: 'PUT', path: '/chats/{id}', description: 'Update chat' },
			{ method: 'DELETE', path: '/chats/{id}', description: 'Delete chat' },
			{ method: 'POST', path: '/chats/{id}/messages', description: 'Send message' },
			{ method: 'GET', path: '/chats/{id}/messages', description: 'Get messages' },
		],
	},
	{
		title: 'Model endpoints',
		endpoints: [
			{ method: 'GET', path: '/models', description: 'List all models' },
			{ method: 'GET', path: '/models/saved', description: 'User saved models' },
			{ method: 'POST', path: '/models/import', description: 'Import models' },
			{ method: 'DELETE', path: '/models/{id}', description: 'Remove model' },
		],
	},
	{
		title: 'Provider endpoints',
		endpoints: [
			{ method: 'GET', path: '/providers', description: 'List providers' },
			{ method: 'POST', path: '/providers/activate', description: 'Add provider' },
			{ method: 'PATCH', path: '/providers/{id}', description: 'Update provider' },
			{ method: 'DELETE', path: '/providers/{id}', description: 'Remove provider' },
		],
	},
	{
		title: 'Jobs endpoints (image gen)',
		endpoints: [
			{ method: 'GET', path: '/jobs', description: 'List jobs' },
			{ method: 'POST', path: '/jobs/image-generation', description: 'Create job' },
			{ method: 'GET', path: '/jobs/{id}', description: 'Get job status' },
		],
	},
];

export const metadata: Metadata = {
	title: 'API Reference · PocketLLM',
	description: 'REST API documentation for the PocketLLM backend.',
};

export default function ApiReferencePage() {
	return (
		<PageShell>
			<PageHero kicker="API Reference" title="PocketLLM REST API" subtitle="Base URL: https://pocket-llm-api.vercel.app/v1" />

			<PageSection title="Authentication">
				<GlassCard className="space-y-2 text-sm text-gray-300">
					<p>All endpoints require a JWT.</p>
					<code className="block rounded-2xl border border-white/10 bg-black/40 px-4 py-2 text-purple-200">Authorization: Bearer &lt;token&gt;</code>
				</GlassCard>
			</PageSection>

			<PageSection title="Endpoints overview">
				<div className="space-y-6">
					{endpointGroups.map((group) => (
						<GlassCard key={group.title} className="space-y-4">
							<h3 className="text-xl font-semibold text-white">{group.title}</h3>
							<div className="space-y-3 text-sm text-gray-300">
								{group.endpoints.map((endpoint) => (
									<div key={`${endpoint.method}-${endpoint.path}`} className="flex flex-wrap items-center gap-3 rounded-2xl border border-white/10 bg-black/30 px-4 py-3">
										<span className="rounded-full bg-purple-500/20 px-3 py-1 text-xs font-semibold text-purple-100">{endpoint.method}</span>
										<code className="text-white">{endpoint.path}</code>
										<span className="text-gray-400">{endpoint.description}</span>
									</div>
								))}
							</div>
						</GlassCard>
					))}
				</div>
			</PageSection>

			<PageSection title="Resources">
				<GlassCard className="space-y-2 text-sm text-purple-200">
					<Link href="https://pocket-llm-api.vercel.app/docs" target="_blank" rel="noreferrer">
						Swagger UI
					</Link>
					<Link href="https://github.com/PocketLLM/PocketLLM/tree/main/docs" target="_blank" rel="noreferrer">
						Full API docs on GitHub
					</Link>
					<p>Postman collection: available upon request</p>
				</GlassCard>
			</PageSection>

			<PageSection align="center">
				<GlassCard className="space-y-3 text-center">
					<GradientPill className="mx-auto">SDKs</GradientPill>
					<p className="text-gray-300">Official SDKs coming soon. Community wrappers exist for Python and JavaScript — share yours on GitHub!</p>
				</GlassCard>
			</PageSection>
		</PageShell>
	);
}
