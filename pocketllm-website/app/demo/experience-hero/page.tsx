"use client";

import { useEffect } from "react";
import { Component as ExperienceHero } from "@/components/ui/experience-hero";
import Lenis from "lenis";

export default function DemoOne() {
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);
    return () => lenis.destroy();
  }, []);

  return (
    <div className="dark min-h-screen bg-[#020202] selection:bg-white selection:text-black">
      <main className="relative w-full overflow-x-hidden">
        <ExperienceHero useColorBends={true} />
        <div className="fixed inset-0 pointer-events-none bento-mask opacity-10 z-[100]" />
      </main>
    </div>
  );
}
