'use client';

import React from 'react';
import {
	Sparkles,
	Shield,
	Users,
	RotateCcw,
	Handshake,
	Leaf,
	MessageSquare,
	Smartphone,
	MenuIcon,
	XIcon,
	Tag,
	BookOpen,
	LifeBuoy,
	Route,
	BriefcaseBusiness,
	ScrollText,
	PhoneCall,
} from 'lucide-react';
import {
	Sheet,
	SheetClose,
	SheetContent,
	SheetTrigger,
	SheetHeader,
	SheetTitle,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import {
	NavigationMenu,
	NavigationMenuContent,
	NavigationMenuList,
	NavigationMenuItem,
	NavigationMenuTrigger,
	NavigationMenuLink,
	type NavItemType,
	NavGridCard,
	NavSmallItem,
	NavLargeItem,
	NavItemMobile,
} from '@/components/ui/navigation-menu';
import {
	Accordion,
	AccordionContent,
	AccordionItem,
	AccordionTrigger,
} from '@/components/ui/accordion';
import { cn } from '@/lib/utils';
import Link from 'next/link';

export const productLinks: NavItemType[] = [
	{
		title: 'Pricing',
		href: '/pricing',
		description: 'Always-free app, pay providers directly',
		icon: Tag,
	},
	{
		title: 'Download',
		href: '/download',
		description: 'iOS, Android, Desktop, Web',
		icon: Smartphone,
	},
	{
		title: 'Documentation',
		href: '/docs',
		description: 'Guides, quick start, developer docs',
		icon: BookOpen,
	},
	{
		title: 'API Reference',
		href: '/api-reference',
		description: 'Backend endpoints and authentication',
		icon: ScrollText,
	},
	{
		title: 'Support',
		href: '/support',
		description: 'FAQ, troubleshooting, contact',
		icon: LifeBuoy,
	},
];

export const companyLinks: NavItemType[] = [
	{
		title: 'About Us',
		href: '/about',
		description: 'Mission, values, and team',
		icon: Users,
	},
	{
		title: 'Roadmap',
		href: '/roadmap',
		description: 'See what we are building next',
		icon: Route,
	},
	{
		title: 'Blog',
		href: '/blog',
		description: 'Updates & tutorials',
		icon: Leaf,
	},
	{
		title: 'Careers',
		href: '/careers',
		description: 'Help us build PocketLLM',
		icon: BriefcaseBusiness,
	},
	{
		title: 'Privacy Policy',
		href: '/privacy',
		description: 'How we protect your information',
		icon: Shield,
	},
	{
		title: 'Terms of Service',
		href: '/terms',
		description: 'Our legal guidelines',
		icon: ScrollText,
	},
	{
		title: 'Refund Policy',
		href: '/refund',
		description: 'PocketLLM is free — see details',
		icon: RotateCcw,
	},
	{
		title: 'Community',
		href: '/community',
		description: 'Join discussions & share tips',
		icon: MessageSquare,
	},
	{
		title: 'Partnerships',
		href: '/partnerships',
		description: 'Collaborate with us for mutual growth',
		icon: Handshake,
	},
	{
		title: 'Contact',
		href: '/contact',
		description: 'Press, partnerships, and support',
		icon: PhoneCall,
	},
];

export default function Navbar() {
	return (
		<nav className="fixed top-0 left-0 right-0 z-50 w-full px-4 pt-4">
			<div className="bg-background/80 supports-[backdrop-filter]:bg-background/60 backdrop-blur-xl mx-auto h-16 w-full max-w-6xl border border-white/10 px-6 rounded-2xl shadow-lg">
				<div className="flex h-full items-center justify-between">
					<div className="flex items-center gap-3">
						<Sparkles className="size-7 text-purple-500" />
						<p className="font-silver-garden text-xl font-bold text-white">PocketLLM</p>
					</div>
					<DesktopMenu />

				<div className="flex items-center gap-3">
					<Button className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white font-bold rounded-full" asChild>
						<Link href="/pricing">Get Started</Link>
					</Button>
						<MobileNav />
					</div>
				</div>
			</div>
		</nav>
	);
}

function DesktopMenu() {
	return (
		<NavigationMenu className="hidden lg:block">
			<NavigationMenuList>
				<NavigationMenuItem>
					<NavigationMenuTrigger className="text-white">Product</NavigationMenuTrigger>
					<NavigationMenuContent>
						<div className="grid w-full md:w-4xl md:grid-cols-[1fr_.30fr]">
							<ul className="grid grow gap-4 p-4 md:grid-cols-3 md:border-r">
								{productLinks.slice(0, 3).map((link) => (
									<li key={link.href}>
										<NavGridCard link={link} />
									</li>
								))}
							</ul>
							<ul className="space-y-1 p-4">
								{productLinks.slice(3).map((link) => (
									<li key={link.href}>
										<NavSmallItem
											item={link}
											href={link.href}
											className="gap-x-1"
										/>
									</li>
								))}
							</ul>
						</div>
					</NavigationMenuContent>
				</NavigationMenuItem>
				<NavigationMenuItem>
					<NavigationMenuTrigger className="text-white">Company</NavigationMenuTrigger>
					<NavigationMenuContent>
						<div className="grid w-full md:w-4xl md:grid-cols-[1fr_.40fr]">
							<ul className="grid grow grid-cols-2 gap-4 p-4 md:border-r">
								{companyLinks.slice(0, 2).map((link) => (
									<li key={link.href}>
										<NavGridCard link={link} className="min-h-36" />
									</li>
								))}
								<div className="col-span-2 grid grid-cols-3 gap-x-4">
									{companyLinks.slice(2, 5).map((link) => (
										<li key={link.href}>
											<NavLargeItem href={link.href} link={link} />
										</li>
									))}
								</div>
							</ul>
							<ul className="space-y-2 p-4">
								{companyLinks.slice(5, 10).map((link) => (
									<li key={link.href}>
										<NavLargeItem href={link.href} link={link} />
									</li>
								))}
							</ul>
						</div>
					</NavigationMenuContent>
				</NavigationMenuItem>
			<NavigationMenuItem>
				<NavigationMenuLink className="cursor-pointer text-white hover:text-purple-400 transition-colors" href="/pricing">
					Pricing
				</NavigationMenuLink>
			</NavigationMenuItem>
			</NavigationMenuList>
		</NavigationMenu>
	);
}

function MobileNav() {
	const sections = [
		{
			id: 'product',
			name: 'Product',
			list: productLinks,
		},
		{
			id: 'company',
			name: 'Company',
			list: companyLinks,
		},
	];

	return (
		<Sheet>
			<SheetTrigger asChild>
				<Button size="icon" variant="ghost" className="rounded-full lg:hidden text-white hover:bg-white/10">
					<MenuIcon className="size-5" />
					<span className="sr-only">Open menu</span>
				</Button>
			</SheetTrigger>
			<SheetContent
				className="bg-background/95 supports-[backdrop-filter]:bg-background/80 w-full gap-0 backdrop-blur-lg"
				showClose={false}
			>
				{/* Add SheetHeader with SheetTitle for accessibility */}
				<SheetHeader className="sr-only">
					<SheetTitle>Navigation Menu</SheetTitle>
				</SheetHeader>
				<div className="flex h-14 items-center justify-end border-b px-4">
					<SheetClose asChild>
						<Button size="icon" variant="ghost" className="rounded-full">
							<XIcon className="size-5" />
							<span className="sr-only">Close</span>
						</Button>
					</SheetClose>
				</div>
				<div className="container grid gap-y-2 overflow-y-auto px-4 pt-5 pb-12">
					<Accordion type="single" collapsible>
						{sections.map((section) => (
							<AccordionItem key={section.id} value={section.id}>
								<AccordionTrigger className="capitalize hover:no-underline">
									{section.name}
								</AccordionTrigger>
								<AccordionContent className="space-y-1">
									<ul className="grid gap-1">
										{section.list.map((link) => (
											<li key={link.href}>
												<SheetClose asChild>
													<NavItemMobile item={link} href={link.href} />
												</SheetClose>
											</li>
										))}
									</ul>
								</AccordionContent>
							</AccordionItem>
						))}
					</Accordion>
					<div className="mt-4">
						<SheetClose asChild>
							<a href="#pricing" className="text-white hover:text-purple-400 transition-colors block py-2">
								Pricing
							</a>
						</SheetClose>
					</div>
				</div>
			</SheetContent>
		</Sheet>
	);
}
