import React from 'react';
import { cn } from '@/lib/utils';
import { GridPattern } from '@/components/ui/grid-pattern';

export function GridCard({
	className,
	children,
	...props
}: React.ComponentProps<'div'>) {
	return (
		<div
			className={cn(
				'group bg-background relative isolate z-0 flex h-full flex-col justify-between overflow-hidden rounded-sm border px-5 py-4 transition-colors duration-75',
				className,
			)}
			{...props}
		>
			<div className="absolute inset-0">
				<div className="absolute -inset-[25%] -skew-y-12 [mask-image:linear-gradient(225deg,black,transparent)]">
					<GridPattern
						width={30}
						height={30}
						x={0}
						y={0}
						squares={getRandomPattern(5)}
						className="fill-border/50 stroke-border absolute inset-0 size-full translate-y-2 transition-transform duration-150 ease-out group-hover:translate-y-0"
					/>
				</div>
				<div
					className={cn(
						'absolute -inset-[10%] opacity-0 blur-[50px] transition-opacity duration-150 group-hover:opacity-10',
						'bg-[conic-gradient(#F35066_0deg,#F35066_117deg,#9071F9_180deg,#5182FC_240deg,#F35066_360deg)]',
					)}
				/>
			</div>
			{children}
		</div>
	);
}

function getRandomPattern(length?: number): [x: number, y: number][] {
	length = length ?? 5;
	const patternSet = new Set<string>();
	const pattern: [x: number, y: number][] = [];
	
	while (pattern.length < length) {
		const x = Math.floor(Math.random() * 4) + 7; // random x between 7 and 10
		const y = Math.floor(Math.random() * 6) + 1; // random y between 1 and 6
		const key = `${x}-${y}`;
		
		if (!patternSet.has(key)) {
			patternSet.add(key);
			pattern.push([x, y]);
		}
	}
	
	return pattern;
}

