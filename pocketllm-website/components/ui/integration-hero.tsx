"use client";

import { Button } from "@/components/ui/button";
import React from "react";

const ICONS_ROW1 = [
  "/asset/brand_icons/openai.svg",
  "/asset/brand_icons/Claude_AI_logo.svg",
  "/asset/brand_icons/Google_Gemini_logo_2025.svg",
  "/asset/brand_icons/deepseek-color.svg",
  "/asset/brand_icons/grok.svg",
  "/asset/brand_icons/groq.svg",
  "/asset/brand_icons/ollama.png",
  "/asset/brand_icons/meta-color.svg",
];

const ICONS_ROW2 = [
  "/asset/brand_icons/mistral-color.svg",
  "/asset/brand_icons/perplexity-color.svg",
  "/asset/brand_icons/openrouter.svg",
  "/asset/brand_icons/huggingface-color.svg",
  "/asset/brand_icons/langchain-color.svg",
  "/asset/brand_icons/copilot-color.svg",
  "/asset/brand_icons/crewai-color.svg",
  "/asset/brand_icons/langgraph-color.svg",
];

// Utility to repeat icons enough times
const repeatedIcons = (icons: string[], repeat = 4) => Array.from({ length: repeat }).flatMap(() => icons);

export default function IntegrationHero() {
  return (
    <section className="relative py-24 overflow-hidden bg-black">
      {/* Light grid background */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.02)_1px,transparent_1px)] [background-size:24px_24px] pointer-events-none" />

      {/* Content */}
      <div className="relative max-w-7xl mx-auto px-6 text-center">
        <span className="inline-block px-3 py-1 mb-4 text-xs font-bold rounded-full border border-purple-500/20 bg-purple-500/5 text-purple-400 font-mono uppercase tracking-widest">
          ⚡ Providers & Core Tools
        </span>
        <h2 className="text-4xl lg:text-6xl font-black tracking-tight text-white uppercase italic-none">
          Unified AI <span className="text-outline">Ecosystem</span>
        </h2>
        <p className="mt-4 text-sm text-white/50 max-w-lg mx-auto font-mono uppercase tracking-wider leading-relaxed">
          Connect your API keys or run models locally. 10+ elite AI backends and platforms supported natively.
        </p>

        {/* Carousel */}
        <div className="mt-16 overflow-hidden relative pb-4">
          {/* Row 1 */}
          <div className="flex gap-8 whitespace-nowrap animate-scroll-left w-max">
            {repeatedIcons(ICONS_ROW1, 6).map((src, i) => (
              <div key={i} className="h-16 w-16 flex-shrink-0 rounded-2xl bg-white/5 border border-white/10 shadow-lg flex items-center justify-center hover:scale-110 hover:border-purple-500/40 hover:bg-purple-500/10 transition-all duration-500">
                <img src={src} alt="icon" className="h-9 w-9 object-contain filter brightness-105" />
              </div>
            ))}
          </div>

          {/* Row 2 */}
          <div className="flex gap-8 whitespace-nowrap mt-8 animate-scroll-right w-max">
            {repeatedIcons(ICONS_ROW2, 6).map((src, i) => (
              <div key={i} className="h-16 w-16 flex-shrink-0 rounded-2xl bg-white/5 border border-white/10 shadow-lg flex items-center justify-center hover:scale-110 hover:border-purple-500/40 hover:bg-purple-500/10 transition-all duration-500">
                <img src={src} alt="icon" className="h-9 w-9 object-contain filter brightness-105" />
              </div>
            ))}
          </div>

          {/* Fade overlays */}
          <div className="absolute left-0 top-0 h-full w-32 bg-gradient-to-r from-black to-transparent pointer-events-none z-10" />
          <div className="absolute right-0 top-0 h-full w-32 bg-gradient-to-l from-black to-transparent pointer-events-none z-10" />
        </div>
      </div>

      <style jsx>{`
        @keyframes scroll-left {
          0% { transform: translateX(0); }
          100% { transform: translateX(-33.33%); }
        }
        @keyframes scroll-right {
          0% { transform: translateX(-33.33%); }
          100% { transform: translateX(0); }
        }
        .animate-scroll-left {
          animation: scroll-left 40s linear infinite;
        }
        .animate-scroll-right {
          animation: scroll-right 40s linear infinite;
        }
      `}</style>
    </section>
  );
}
