import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

type Alignment = 'left' | 'center';

export function PageShell({
	children,
	className,
}: {
	children: ReactNode;
	className?: string;
}) {
	return (
		<div className="relative isolate min-h-screen bg-[#050505] text-gray-100">
			<div className="pointer-events-none absolute inset-0">
				<div className="absolute -top-48 left-1/2 h-[520px] w-[520px] -translate-x-1/2 rounded-full bg-purple-600/20 blur-[140px]" />
				<div className="absolute bottom-0 right-0 h-[420px] w-[420px] rounded-full bg-pink-500/10 blur-[180px]" />
				<div className="absolute inset-y-0 left-1/2 w-px -translate-x-1/2 bg-gradient-to-b from-transparent via-white/10 to-transparent" />
			</div>
			<div
				className={cn(
					'relative z-10 mx-auto flex w-full max-w-6xl flex-col gap-16 px-4 pb-24 pt-32 sm:px-6 lg:px-8',
					className,
				)}
			>
				{children}
			</div>
		</div>
	);
}

export function PageHero({
	align = 'center',
	kicker,
	title,
	subtitle,
	actions,
}: {
	align?: Alignment;
	kicker?: string;
	title: string;
	subtitle: string;
	actions?: ReactNode;
}) {
	return (
		<header
			className={cn(
				'flex flex-col gap-6 rounded-[32px] border border-white/10 bg-white/[0.03] p-8 text-white shadow-[0_30px_120px_rgba(139,92,246,0.15)] backdrop-blur-2xl',
				align === 'center' ? 'items-center text-center' : 'items-start text-left',
			)}
		>
			{Boolean(kicker) && <GradientPill>{kicker}</GradientPill>}
			<h1 className="font-silver-garden text-4xl leading-tight sm:text-5xl lg:text-6xl">
				{title}
			</h1>
			<p className="max-w-3xl text-lg text-gray-200 sm:text-xl">{subtitle}</p>
			{actions}
		</header>
	);
}

export function PageSection({
	id,
	eyebrow,
	title,
	description,
	children,
	align = 'left',
	className,
}: {
	id?: string;
	eyebrow?: string;
	title?: string;
	description?: string;
	children: ReactNode;
	align?: Alignment;
	className?: string;
}) {
	return (
		<section id={id} className={cn('space-y-8', className)}>
			{(eyebrow || title || description) && (
				<div className={cn('space-y-4', align === 'center' ? 'text-center' : 'text-left')}>
					{eyebrow && <GradientPill className={align === 'center' ? 'mx-auto' : undefined}>{eyebrow}</GradientPill>}
					{title && (
						<h2 className="font-silver-garden text-3xl text-white sm:text-4xl">
							{title}
						</h2>
					)}
					{description && <p className="text-lg text-gray-300">{description}</p>}
				</div>
			)}
			{children}
		</section>
	);
}

export function GlassCard({
	children,
	className,
}: {
	children: ReactNode;
	className?: string;
}) {
	return (
		<div
			className={cn(
				'relative rounded-3xl border border-white/10 bg-white/[0.04] p-6 shadow-[0_25px_80px_rgba(8,8,8,0.6)] backdrop-blur-xl',
				'before:absolute before:inset-0 before:-z-10 before:rounded-[inherit] before:bg-gradient-to-br before:from-white/10 before:to-transparent before:opacity-0 before:transition-opacity before:duration-300 hover:before:opacity-100',
				className,
			)}
		>
			{children}
		</div>
	);
}

export function GradientPill({
	children,
	className,
}: {
	children: ReactNode;
	className?: string;
}) {
	return (
		<span
			className={cn(
				'inline-flex items-center rounded-full bg-gradient-to-r from-purple-500/30 to-pink-500/30 px-4 py-1 text-xs font-semibold uppercase tracking-widest text-purple-100',
				className,
			)}
		>
			{children}
		</span>
	);
}

export function StatPill({
	label,
	value,
	subtle,
	className,
}: {
	label: string;
	value: string;
	subtle?: string;
	className?: string;
}) {
	return (
		<div className={cn('rounded-2xl border border-white/10 bg-black/30 p-4 text-center', className)}>
			<p className="text-sm uppercase tracking-[0.2em] text-gray-400">{label}</p>
			<p className="mt-2 font-silver-garden text-3xl text-white">{value}</p>
			{subtle && <p className="text-sm text-gray-400">{subtle}</p>}
		</div>
	);
}
