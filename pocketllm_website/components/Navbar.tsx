'use client';

import React from 'react';
import {
	Sparkles,
	Zap,
	Shield,
	Users,
	Star,
	FileText,
	RotateCcw,
	Handshake,
	Leaf,
	HelpCircle,
	MessageSquare,
	Smartphone,
	MenuIcon,
	XIcon,
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

export const productLinks: NavItemType[] = [
	{
		title: 'AI Chat',
		href: '#chat',
		description: 'Connect with multiple AI models in one place',
		icon: MessageSquare,
	},
	{
		title: 'Model Switching',
		href: '#models',
		description: 'Switch between OpenAI, Gemini, Groq instantly',
		icon: Zap,
	},
	{
		title: 'Mobile App',
		href: '#mobile',
		description: 'Built with Flutter for iOS and Android',
		icon: Smartphone,
	},
	{
		title: 'Features',
		href: '#features',
		icon: Sparkles,
	},
	{
		title: 'Security',
		href: '#security',
		icon: Shield,
	},
];

export const companyLinks: NavItemType[] = [
	{
		title: 'About Us',
		href: '#about',
		description: 'Learn more about PocketLLM',
		icon: Users,
	},
	{
		title: 'User Stories',
		href: '#stories',
		description: 'See how users leverage PocketLLM',
		icon: Star,
	},
	{
		title: 'Terms of Service',
		href: '#terms',
		description: 'Understand how we operate',
		icon: FileText,
	},
	{
		title: 'Privacy Policy',
		href: '#privacy',
		description: 'How we protect your information',
		icon: Shield,
	},
	{
		title: 'Refund Policy',
		href: '#refund',
		description: 'Details about refunds and cancellations',
		icon: RotateCcw,
	},
	{
		title: 'Partnerships',
		href: '#partnerships',
		icon: Handshake,
		description: 'Collaborate with us for mutual growth',
	},
	{
		title: 'Blog',
		href: '#blog',
		icon: Leaf,
		description: 'Insights, tutorials, and company news',
	},
	{
		title: 'Help Center',
		href: '#help',
		icon: HelpCircle,
		description: 'Find answers to your questions',
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
						<Button className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white font-bold rounded-full">
							Get Started
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
					<NavigationMenuLink className="cursor-pointer text-white hover:text-purple-400 transition-colors">
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

