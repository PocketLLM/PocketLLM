"use client";

import { Component as ExperienceHero } from "@/components/ui/experience-hero";
import { CosmicSpectrum } from "@/components/ui/cosmos-spectrum";
import IntegrationHero from "@/components/ui/integration-hero";
import StickyFooter from "@/components/ui/footer";
import NewsletterPopup from "@/components/ui/newsletter-popup";
import WaitlistPopup from "@/components/ui/waitlist-popup";
import { motion, AnimatePresence } from "framer-motion";
import { useState, useEffect, useRef } from "react";
import {
  Sparkles,
  KeyRound,
  RefreshCw,
  Cpu,
  Search,
  Sliders,
  ArrowUpRight,
  Code,
  PenTool,
  GraduationCap,
  Briefcase,
  Lock,
  Database,
  Terminal,
  CheckCircle2,
  ChevronRight,
  Eye,
  EyeOff,
  Laptop,
  Smartphone,
  Star,
  Users,
  Activity,
  Shield,
  Zap,
  Cloud,
  Compass,
  Heart,
  Lightbulb
} from "lucide-react";

// --- Interactive Feature Widgets ---

function MultiProviderWidget() {
  const providers = [
    { name: "OpenAI", src: "/asset/brand_icons/openai.svg" },
    { name: "Claude", src: "/asset/brand_icons/Claude_AI_logo.svg" },
    { name: "Gemini", src: "/asset/brand_icons/Google_Gemini_logo_2025.svg" },
    { name: "DeepSeek", src: "/asset/brand_icons/deepseek-color.svg" },
    { name: "Groq", src: "/asset/brand_icons/groq.svg" },
    { name: "Ollama", src: "/asset/brand_icons/ollama.png" }
  ];

  return (
    <div className="h-44 relative bg-black/40 rounded-xl border border-white/5 overflow-hidden flex items-center justify-center">
      {/* Central PocketLLM core */}
      <div className="relative z-10 w-12 h-12 rounded-full bg-linear-to-br from-purple-500 to-pink-500 flex items-center justify-center shadow-lg shadow-purple-500/30">
        <span className="text-white font-black text-xs">P</span>
        <div className="absolute inset-0 rounded-full border border-white/20 animate-ping opacity-30" />
      </div>

      {/* Orbiting / Connected Provider Icons */}
      <div className="absolute inset-0 flex items-center justify-center">
        {providers.map((prov, idx) => {
          const angle = (idx * 360) / providers.length;
          const radius = 56; // radius of circle in px
          const x = radius * Math.cos((angle * Math.PI) / 180);
          const y = radius * Math.sin((angle * Math.PI) / 180);

          return (
            <motion.div
              key={prov.name}
              className="absolute w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center p-1 shadow-md hover:bg-purple-500/10 hover:border-purple-500/30 transition-all duration-300 cursor-pointer"
              style={{ x, y }}
              whileHover={{ scale: 1.2 }}
            >
              <img src={prov.src} alt={prov.name} className="w-5 h-5 object-contain filter brightness-105" />
            </motion.div>
          );
        })}
      </div>

      {/* Connection Lines (SVGs) */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-20">
        {providers.map((_, idx) => {
          const angle = (idx * 360) / providers.length;
          const radius = 56;
          const x2 = 50 + (radius / 1.76) * Math.cos((angle * Math.PI) / 180); // percentage calculation
          const y2 = 50 + (radius / 1.1) * Math.sin((angle * Math.PI) / 180);
          return (
            <line
              key={idx}
              x1="50%"
              y1="50%"
              x2={`${x2}%`}
              y2={`${y2}%`}
              stroke="url(#line-grad)"
              strokeWidth="1"
              strokeDasharray="4,4"
              className="animate-pulse"
            />
          );
        })}
        <defs>
          <linearGradient id="line-grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#8B5CF6" />
            <stop offset="100%" stopColor="#EC4899" />
          </linearGradient>
        </defs>
      </svg>
    </div>
  );
}

function SecureKeyWidget() {
  const [revealed, setRevealed] = useState(false);
  const key = "sk-proj-4aB9x...9x2Y7mD5";

  return (
    <div className="h-44 bg-black/40 rounded-xl border border-white/5 p-4 flex flex-col justify-between">
      <div className="flex items-center justify-between">
        <span className="text-[10px] uppercase font-mono tracking-widest text-gray-500">API Key Safe</span>
        <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-emerald-500/10 border border-emerald-500/20">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-[9px] font-mono text-emerald-400 font-bold uppercase tracking-wider">AES-256</span>
        </div>
      </div>

      <div className="relative bg-white/5 border border-white/10 rounded-lg p-2.5 flex items-center justify-between gap-2">
        <div className="font-mono text-xs text-white/80 select-all overflow-hidden truncate">
          {revealed ? key : "••••••••••••••••••••••••••••"}
        </div>
        <button
          onClick={() => setRevealed(!revealed)}
          className="text-gray-400 hover:text-white transition-colors flex-shrink-0"
        >
          {revealed ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
        </button>
      </div>

      <div className="text-[11px] font-mono text-gray-400 leading-tight">
        Keys never touch our servers. Stored strictly in your device&apos;s encrypted Keychain/Keystore.
      </div>
    </div>
  );
}

function CrossPlatformSyncWidget() {
  const [syncStep, setSyncStep] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setSyncStep((prev) => (prev + 1) % 3);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-black/40 rounded-xl border border-white/5 p-4 overflow-hidden relative flex items-center justify-around">
      {/* Mini Phone */}
      <div className="w-16 h-28 bg-zinc-950 border border-white/20 rounded-xl p-1 flex flex-col justify-between shadow-2xl relative">
        <div className="w-6 h-1 bg-white/20 rounded-full mx-auto" />
        <div className="flex-1 flex flex-col justify-end gap-1 px-0.5 py-1">
          {syncStep >= 0 && (
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="bg-purple-600 text-[6px] text-white p-1 rounded-md max-w-[80%]"
            >
              How does it sync?
            </motion.div>
          )}
        </div>
        <div className="h-2 w-2 rounded-full border border-white/10 mx-auto" />
      </div>

      {/* Sync Animation lines */}
      <div className="relative flex flex-col items-center justify-center gap-1">
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ repeat: Infinity, duration: 8, ease: "linear" }}
        >
          <RefreshCw className="w-5 h-5 text-purple-400" />
        </motion.div>
        <span className="text-[8px] font-mono text-gray-500 uppercase tracking-widest">E2EE SYNC</span>
      </div>

      {/* Mini Laptop */}
      <div className="w-28 h-20 bg-zinc-950 border border-white/20 rounded-lg p-1.5 flex flex-col justify-between shadow-2xl relative">
        <div className="flex-1 bg-black/50 border border-white/5 rounded-md p-1 flex flex-col justify-end gap-1">
          {syncStep >= 1 && (
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="bg-purple-600 text-[6px] text-white p-1 rounded-md max-w-[70%]"
            >
              How does it sync?
            </motion.div>
          )}
          {syncStep >= 2 && (
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="bg-zinc-800 text-[6px] text-white/90 p-1 rounded-md max-w-[85%] self-end"
            >
              Instant sync across all devices securely.
            </motion.div>
          )}
        </div>
        <div className="h-1 bg-white/20 rounded-full w-full mt-1" />
      </div>
    </div>
  );
}

function LocalModelWidget() {
  const [termStep, setTermStep] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setTermStep((prev) => (prev + 1) % 4);
    }, 3500);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-black/40 rounded-xl border border-white/5 p-4 flex flex-col justify-between">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          <Terminal className="w-3.5 h-3.5 text-green-400" />
          <span className="text-[10px] font-mono tracking-wider text-green-400">Ollama Local</span>
        </div>
        <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
      </div>

      <div className="flex-1 my-2 bg-zinc-950/80 border border-white/10 rounded-lg p-2.5 font-mono text-[9px] leading-relaxed text-zinc-300">
        <div>$ ollama run deepseek-r1</div>
        {termStep >= 1 && <div className="text-zinc-500">&gt;&gt;&gt; pulling manifest...</div>}
        {termStep >= 2 && <div className="text-purple-400">&gt;&gt;&gt; load model: deepseek-r1 (100%)</div>}
        {termStep >= 3 && <div className="text-green-400">&gt;&gt;&gt; success! local host listening.</div>}
      </div>

      <div className="text-[10px] font-mono text-zinc-400">
        Run state-of-the-art open models 100% offline for total privacy.
      </div>
    </div>
  );
}

function SmartSearchWidget() {
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    let timer: any;
    const cycle = () => {
      let text = "smart settings";
      let i = 0;
      const type = () => {
        if (i <= text.length) {
          setSearchQuery(text.substring(0, i));
          i++;
          timer = setTimeout(type, 120);
        } else {
          timer = setTimeout(() => {
            const erase = () => {
              if (i >= 0) {
                setSearchQuery(text.substring(0, i));
                i--;
                timer = setTimeout(erase, 80);
              } else {
                timer = setTimeout(cycle, 1500);
              }
            };
            erase();
          }, 2000);
        }
      };
      type();
    };
    cycle();
    return () => clearTimeout(timer);
  }, []);

  const mockItems = [
    { title: "Smart search integration config", date: "Today" },
    { title: "Advanced sliders and temp settings", date: "Yesterday" },
    { title: "Secure keychain backup guide", date: "3 days ago" }
  ];

  const filteredItems = mockItems.filter(item =>
    item.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="h-44 bg-black/40 rounded-xl border border-white/5 p-4 flex flex-col justify-between">
      {/* Search Input bar */}
      <div className="relative bg-white/5 border border-white/10 rounded-lg px-2.5 py-1.5 flex items-center gap-2">
        <Search className="w-3.5 h-3.5 text-zinc-500" />
        <input
          type="text"
          readOnly
          value={searchQuery}
          placeholder="Search conversations..."
          className="bg-transparent border-none text-xs text-white placeholder-zinc-500 outline-none w-full font-mono"
        />
      </div>

      {/* Dynamic results list */}
      <div className="flex-1 mt-2.5 overflow-hidden flex flex-col gap-1.5">
        <AnimatePresence>
          {(filteredItems.length > 0 ? filteredItems : mockItems).slice(0, 2).map((item, idx) => (
            <motion.div
              key={item.title}
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -5 }}
              className="bg-white/5 rounded-md p-1.5 flex items-center justify-between border border-white/5"
            >
              <span className="text-[10px] text-zinc-300 truncate w-3/4">{item.title}</span>
              <span className="text-[8px] font-mono text-zinc-500">{item.date}</span>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}

function AdvancedControlsWidget() {
  const [temp, setTemp] = useState(0.7);
  const [tokens, setTokens] = useState(2048);

  useEffect(() => {
    const interval = setInterval(() => {
      setTemp((t) => (t === 0.7 ? 0.35 : 0.7));
      setTokens((tk) => (tk === 2048 ? 1024 : 2048));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-black/40 rounded-xl border border-white/5 p-4 flex flex-col justify-between">
      <div className="flex items-center justify-between">
        <span className="text-[10px] uppercase font-mono tracking-widest text-zinc-500">Fine-Tune Controls</span>
        <Sliders className="w-3.5 h-3.5 text-purple-400" />
      </div>

      <div className="flex-1 my-2 flex flex-col justify-center gap-3">
        {/* Temp slider */}
        <div className="flex flex-col gap-1">
          <div className="flex justify-between text-[9px] font-mono text-zinc-400">
            <span>Temperature</span>
            <span className="text-purple-400 font-bold">{temp.toFixed(2)}</span>
          </div>
          <div className="h-1 bg-zinc-800 rounded-full overflow-hidden relative">
            <motion.div
              className="absolute left-0 top-0 h-full bg-linear-to-r from-purple-500 to-pink-500"
              animate={{ width: `${temp * 100}%` }}
              transition={{ duration: 1 }}
            />
          </div>
        </div>

        {/* Tokens slider */}
        <div className="flex flex-col gap-1">
          <div className="flex justify-between text-[9px] font-mono text-zinc-400">
            <span>Max Tokens</span>
            <span className="text-pink-400 font-bold">{tokens}</span>
          </div>
          <div className="h-1 bg-zinc-800 rounded-full overflow-hidden relative">
            <motion.div
              className="absolute left-0 top-0 h-full bg-linear-to-r from-pink-500 to-blue-500"
              animate={{ width: `${(tokens / 4096) * 100}%` }}
              transition={{ duration: 1 }}
            />
          </div>
        </div>
      </div>

      <div className="flex gap-1.5">
        <span className="text-[8px] font-mono bg-purple-500/10 border border-purple-500/20 text-purple-400 px-1.5 py-0.5 rounded">Act as Expert Coder</span>
        <span className="text-[8px] font-mono bg-pink-500/10 border border-pink-500/20 text-pink-400 px-1.5 py-0.5 rounded">Deterministic</span>
      </div>
    </div>
  );
}

// --- Interactive Trust Dashboard Widgets ---

function ActiveUsersWidget({ count }: { count: number }) {
  const avatars = [
    { initials: "JD", color: "bg-purple-600" },
    { initials: "AS", color: "bg-pink-600" },
    { initials: "MK", color: "bg-blue-600" },
    { initials: "TL", color: "bg-emerald-600" },
    { initials: "RE", color: "bg-amber-600" }
  ];

  return (
    <div className="h-48 bg-black/40 rounded-3xl border border-white/10 p-6 flex flex-col justify-between hover:border-purple-500/40 hover:bg-purple-900/5 transition-all duration-500 group relative overflow-hidden">
      <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/5 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-mono tracking-widest text-purple-400 uppercase font-bold px-2 py-0.5 rounded-full bg-purple-500/10 border border-purple-500/25">
          GLOBAL NETWORK
        </span>
        <Users className="w-4 h-4 text-purple-400" />
      </div>

      <div className="my-4">
        <div className="text-5xl font-black font-silver-garden text-white tracking-tight flex items-baseline gap-1">
          <span>{count.toLocaleString()}</span>
          <span className="text-purple-400">+</span>
        </div>
        <p className="text-gray-400 font-kollektif text-sm font-semibold mt-1">Active AI Developers & Users</p>
      </div>

      <div className="flex items-center justify-between border-t border-white/5 pt-4">
        <div className="flex -space-x-2 overflow-hidden">
          {avatars.map((av, i) => (
            <div
              key={i}
              className={`inline-block h-6 w-6 rounded-full ring-2 ring-zinc-950 flex items-center justify-center text-[8px] font-bold text-white ${av.color} shadow-lg hover:-translate-y-0.5 transition-transform duration-200 cursor-pointer`}
            >
              {av.initials}
            </div>
          ))}
        </div>
        <div className="flex items-center gap-1.5 text-[10px] font-mono text-emerald-400">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          <span>512 online</span>
        </div>
      </div>
    </div>
  );
}

function UptimeWidget({ percent }: { percent: number }) {
  const statusBlocks = Array.from({ length: 24 });

  return (
    <div className="h-48 bg-black/40 rounded-3xl border border-white/10 p-6 flex flex-col justify-between hover:border-pink-500/40 hover:bg-pink-900/5 transition-all duration-500 group relative overflow-hidden">
      <div className="absolute top-0 right-0 w-32 h-32 bg-pink-500/5 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-mono tracking-widest text-pink-400 uppercase font-bold px-2 py-0.5 rounded-full bg-pink-500/10 border border-pink-500/25">
          INFRASTRUCTURE
        </span>
        <Activity className="w-4 h-4 text-pink-400" />
      </div>

      <div className="my-4">
        <div className="text-5xl font-black font-silver-garden text-white tracking-tight flex items-baseline gap-1">
          <span>{percent.toFixed(1)}</span>
          <span className="text-pink-400">%</span>
        </div>
        <p className="text-gray-400 font-kollektif text-sm font-semibold mt-1">Platform Uptime Guaranteed</p>
      </div>

      <div className="flex items-center justify-between border-t border-white/5 pt-4">
        <div className="flex gap-0.5">
          {statusBlocks.map((_, i) => (
            <div
              key={i}
              className={`w-1.5 h-3.5 rounded-xs ${
                i === 22 ? "bg-emerald-500/40 animate-pulse" : "bg-emerald-500"
              } transition-colors hover:bg-emerald-400 cursor-pointer`}
              title="System 100% Operational"
            />
          ))}
        </div>
        <span className="text-[9px] font-mono text-zinc-500 uppercase tracking-widest">30d Operational</span>
      </div>
    </div>
  );
}

function RatingWidget({ rating }: { rating: number }) {
  return (
    <div className="h-48 bg-black/40 rounded-3xl border border-white/10 p-6 flex flex-col justify-between hover:border-blue-500/40 hover:bg-blue-900/5 transition-all duration-500 group relative overflow-hidden">
      <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/5 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-mono tracking-widest text-blue-400 uppercase font-bold px-2 py-0.5 rounded-full bg-blue-500/10 border border-blue-500/25">
          USER SATISFACTION
        </span>
        <Star className="w-4 h-4 text-blue-400 fill-blue-400/20" />
      </div>

      <div className="my-4">
        <div className="text-5xl font-black font-silver-garden text-white tracking-tight flex items-baseline gap-1">
          <span>{rating.toFixed(1)}</span>
          <span className="text-blue-400">/ 5</span>
        </div>
        <p className="text-gray-400 font-kollektif text-sm font-semibold mt-1">Excellent Customer Feedback</p>
      </div>

      <div className="flex items-center justify-between border-t border-white/5 pt-4">
        <div className="flex gap-0.5">
          {Array.from({ length: 5 }).map((_, i) => (
            <Star
              key={i}
              className={`w-3.5 h-3.5 ${
                i === 4 ? "text-blue-400/50 fill-blue-400/20" : "text-blue-400 fill-blue-400"
              } transition-transform hover:scale-125 duration-200 cursor-pointer`}
            />
          ))}
        </div>
        <span className="text-[9px] font-mono text-zinc-500 uppercase tracking-widest">1,248 reviews</span>
      </div>
    </div>
  );
}

// --- Under the Hood Tech Widgets ---

function FlutterTechWidget() {
  const [fps, setFps] = useState(60.0);

  useEffect(() => {
    const interval = setInterval(() => {
      setFps(60.0 - Math.random() * 0.2);
    }, 400);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-zinc-950/80 border border-white/5 rounded-2xl p-4 font-mono text-[10px] text-zinc-400 relative overflow-hidden flex flex-col justify-between">
      <div className="flex items-center justify-between border-b border-white/5 pb-2">
        <span className="text-[8px] text-zinc-500 uppercase tracking-widest">RENDER ENGINE</span>
        <div className="flex items-center gap-1.5 text-cyan-400 font-bold">
          <span className="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-ping" />
          <span>{fps.toFixed(1)} FPS</span>
        </div>
      </div>

      <div className="relative flex justify-center py-2 h-20">
        <div className="absolute w-28 h-16 rounded border border-cyan-500/25 bg-cyan-500/5 -rotate-6 transform -translate-x-4 hover:rotate-0 transition-transform duration-300 flex items-center justify-center">
          <span className="text-[8px] text-cyan-400">UI Layer</span>
        </div>
        <div className="absolute w-28 h-16 rounded border border-purple-500/25 bg-purple-500/5 rotate-3 transform translate-x-4 hover:rotate-0 transition-transform duration-300 flex items-center justify-center">
          <span className="text-[8px] text-purple-400">Logic Layer</span>
        </div>
      </div>

      <div className="flex items-center justify-between text-[8px] text-zinc-500 pt-2 border-t border-white/5">
        <span>Vulkan / Metal API</span>
        <span>60fps V-Sync</span>
      </div>
    </div>
  );
}

function FastAPIBackendWidget() {
  const [logs, setLogs] = useState<string[]>([
    "GET /v1/chat/completions - 200 OK",
    "POST /v1/auth/validate - 200 OK"
  ]);

  useEffect(() => {
    const endpoints = [
      "GET /v1/chats - 200 OK",
      "POST /v1/users/profile - 201 Created",
      "GET /v1/models - 200 OK",
      "POST /v1/referral/claim - 200 OK"
    ];
    const interval = setInterval(() => {
      const ms = Math.floor(Math.random() * 15) + 8;
      const nextLog = `${endpoints[Math.floor(Math.random() * endpoints.length)]} (${ms}ms)`;
      setLogs((prev) => [...prev.slice(1), nextLog]);
    }, 1500);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-zinc-950/80 border border-white/5 rounded-2xl p-4 font-mono text-[10px] text-emerald-400 relative overflow-hidden flex flex-col justify-between">
      <div className="flex items-center justify-between border-b border-white/5 pb-2">
        <span className="text-[8px] text-zinc-500 uppercase tracking-widest">SERVER LOGS</span>
        <span className="text-emerald-500 font-bold bg-emerald-500/10 border border-emerald-500/20 px-1.5 py-0.5 rounded text-[8px]">
          UVICORN ACTIVE
        </span>
      </div>

      <div className="space-y-1.5 my-2">
        {logs.map((log, i) => (
          <div key={i} className="flex gap-2 text-[9px] opacity-80 font-mono">
            <span className="text-zinc-600">&gt;</span>
            <span className={i === logs.length - 1 ? "text-emerald-400 font-semibold" : "text-zinc-400"}>
              {log}
            </span>
          </div>
        ))}
      </div>

      <div className="flex items-center justify-between text-[8px] text-zinc-500 pt-2 border-t border-white/5">
        <span>AsyncIO Event Loop</span>
        <span>4.8k req/sec</span>
      </div>
    </div>
  );
}

function SupabaseSyncWidget() {
  const [synced, setSynced] = useState(true);

  useEffect(() => {
    const interval = setInterval(() => {
      setSynced(false);
      setTimeout(() => setSynced(true), 600);
    }, 3000);
    return () => clearTimeout(interval);
  }, []);

  return (
    <div className="h-44 bg-zinc-950/80 border border-white/5 rounded-2xl p-4 font-mono text-[10px] text-orange-400 relative overflow-hidden flex flex-col justify-between">
      <div className="flex items-center justify-between border-b border-white/5 pb-2">
        <span className="text-[8px] text-zinc-500 uppercase tracking-widest">CLOUD SYNC</span>
        <div className="flex items-center gap-1">
          <span className={`w-1.5 h-1.5 rounded-full ${synced ? "bg-orange-500 animate-pulse" : "bg-zinc-500"}`} />
          <span className="text-[8px] font-bold text-zinc-400">
            {synced ? "SYNCED" : "SAVING..."}
          </span>
        </div>
      </div>

      <div className="flex items-center justify-around py-2">
        <div className="flex flex-col items-center gap-1">
          <Database className={`w-8 h-8 text-orange-500 ${!synced ? "animate-bounce" : ""}`} />
          <span className="text-[8px] text-zinc-500">PostgreSQL</span>
        </div>

        <div className="flex items-center justify-center relative w-16">
          <RefreshCw className={`w-4 h-4 text-orange-400/50 ${!synced ? "animate-spin" : ""}`} />
        </div>

        <div className="flex flex-col items-center gap-1">
          <Cloud className="w-8 h-8 text-blue-400" />
          <span className="text-[8px] text-zinc-500">Supabase DB</span>
        </div>
      </div>

      <div className="flex items-center justify-between text-[8px] text-zinc-500 pt-2 border-t border-white/5">
        <span>TLS 1.3 Sync Tunnel</span>
        <span>Replication: 1ms</span>
      </div>
    </div>
  );
}

function EncryptionWidget() {
  const [cipher, setCipher] = useState("DECRYPTING...");
  
  useEffect(() => {
    const rawData = ["4a7c 9b2d f8e1", "b8a9 c2d4 e1f5", "8d9c f2a5 b8e3", "POCKETLLM_KEY"];
    let i = 0;
    const interval = setInterval(() => {
      setCipher(rawData[i]);
      i = (i + 1) % rawData.length;
    }, 1200);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-44 bg-zinc-950/80 border border-white/5 rounded-2xl p-4 font-mono text-[10px] text-purple-400 relative overflow-hidden flex flex-col justify-between">
      <div className="flex items-center justify-between border-b border-white/5 pb-2">
        <span className="text-[8px] text-zinc-500 uppercase tracking-widest">E2EE TUNNEL</span>
        <span className="text-purple-500 font-bold bg-purple-500/10 border border-purple-500/20 px-1.5 py-0.5 rounded text-[8px]">
          AES-GCM-256
        </span>
      </div>

      <div className="flex flex-col items-center justify-center gap-1.5 my-2">
        <Lock className="w-5 h-5 text-purple-500 animate-pulse" />
        <span className="text-[9px] font-bold font-mono text-zinc-300 bg-white/5 border border-white/5 px-2 py-0.5 rounded">
          {cipher}
        </span>
      </div>

      <div className="flex items-center justify-between text-[8px] text-zinc-500 pt-2 border-t border-white/5">
        <span>Zero Knowledge</span>
        <span>Local Client Key</span>
      </div>
    </div>
  );
}

interface MissionOrbitWidgetProps {
  activeValue: number;
  setActiveValue: (val: number) => void;
}

function MissionOrbitWidget({ activeValue, setActiveValue }: MissionOrbitWidgetProps) {
  const nodes = [
    { id: 0, label: "Innovation", color: "from-purple-500 to-indigo-500", icon: Lightbulb, angle: 30, glow: "rgba(139, 92, 246, 0.3)" },
    { id: 1, label: "Privacy", color: "from-cyan-500 to-blue-500", icon: Lock, angle: 150, glow: "rgba(6, 182, 212, 0.3)" },
    { id: 2, label: "User Centric", color: "from-pink-500 to-rose-500", icon: Heart, angle: 270, glow: "rgba(236, 72, 153, 0.3)" }
  ];

  return (
    <div className="relative w-full h-[400px] flex items-center justify-center bg-zinc-950/40 border border-white/5 rounded-3xl overflow-hidden backdrop-blur-md">
      {/* Dynamic Background Grids and Rings */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.01)_1px,transparent_1px)] [background-size:20px_20px] pointer-events-none" />
      
      {/* Rotating orbit rings */}
      <motion.div 
        className="absolute w-[240px] h-[240px] rounded-full border border-white/5"
        animate={{ rotate: 360 }}
        transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
      />
      <motion.div 
        className="absolute w-[240px] h-[240px] rounded-full border border-dashed border-purple-500/10"
        animate={{ rotate: -360 }}
        transition={{ duration: 40, repeat: Infinity, ease: "linear" }}
      />
      
      {/* Central PocketLLM Core */}
      <div className="relative z-10 w-24 h-24 rounded-full bg-linear-to-br from-purple-600 via-pink-600 to-blue-600 flex flex-col items-center justify-center shadow-[0_0_50px_rgba(139,92,246,0.4)] border border-white/20 select-none">
        <span className="text-white font-black text-xl tracking-tighter">POCKET</span>
        <span className="text-[10px] font-mono font-bold tracking-widest text-white/80 -mt-1">LLM</span>
        <div className="absolute inset-0 rounded-full border border-white/20 animate-ping opacity-25" style={{ animationDuration: '3s' }} />
      </div>

      {/* Connection lines from central core to active value */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none">
        {nodes.map((node) => {
          const angleRad = (node.angle * Math.PI) / 180;
          const radius = 120;
          const x2 = 50 + (radius / 3.6) * Math.cos(angleRad); // approx percent
          const y2 = 50 + (radius / 3.6) * Math.sin(angleRad);
          const isActive = activeValue === node.id;
          
          return (
            <motion.line
              key={node.id}
              x1="50%"
              y1="50%"
              x2={`${x2}%`}
              y2={`${y2}%`}
              stroke={isActive ? "url(#active-line-grad)" : "rgba(255,255,255,0.05)"}
              strokeWidth={isActive ? "2" : "1"}
              strokeDasharray={isActive ? "none" : "4,4"}
              initial={{ opacity: 0.2 }}
              animate={{ opacity: isActive ? 1 : 0.2 }}
              transition={{ duration: 0.5 }}
            />
          );
        })}
        <defs>
          <linearGradient id="active-line-grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#8B5CF6" />
            <stop offset="50%" stopColor="#EC4899" />
            <stop offset="100%" stopColor="#06B6D4" />
          </linearGradient>
        </defs>
      </svg>

      {/* Orbiting / Floating interactive value nodes */}
      {nodes.map((node) => {
        const angleRad = (node.angle * Math.PI) / 180;
        const radius = 120;
        const x = radius * Math.cos(angleRad);
        const y = radius * Math.sin(angleRad);
        const Icon = node.icon;
        const isActive = activeValue === node.id;

        return (
          <motion.div
            key={node.id}
            className={`absolute z-20 w-16 h-16 rounded-2xl bg-zinc-900 border ${
              isActive ? "border-purple-500" : "border-white/10"
            } flex flex-col items-center justify-center p-2 cursor-pointer hover:border-white/30 transition-all duration-300`}
            style={{ 
              x, 
              y,
              boxShadow: isActive ? `0 0 25px ${node.glow}` : undefined
            }}
            whileHover={{ scale: 1.1 }}
            onClick={() => setActiveValue(node.id)}
          >
            <div className={`w-8 h-8 rounded-xl bg-linear-to-br ${node.color} flex items-center justify-center shadow-md mb-0.5`}>
              <Icon className="w-4 h-4 text-white" />
            </div>
            <span className="text-[8px] font-mono uppercase tracking-wider text-zinc-400 font-bold">
              {node.label.split(" ")[0]}
            </span>
          </motion.div>
        );
      })}
    </div>
  );
}

export default function Home() {
  const [activeUsersCount, setActiveUsersCount] = useState(0);
  const [uptimeCount, setUptimeCount] = useState(0);
  const [ratingCount, setRatingCount] = useState(0);
  const [activeValue, setActiveValue] = useState(0);

  useEffect(() => {
    let start = 0;
    const endUsers = 10000;
    const endUptime = 99.9;
    const endRating = 4.9;

    const duration = 1500;
    const stepTime = 25;
    const steps = duration / stepTime;
    let currentStep = 0;

    const timer = setInterval(() => {
      currentStep++;
      if (currentStep >= steps) {
        setActiveUsersCount(endUsers);
        setUptimeCount(endUptime);
        setRatingCount(endRating);
        clearInterval(timer);
      } else {
        const progress = currentStep / steps;
        const ease = progress * (2 - progress);
        setActiveUsersCount(Math.floor(ease * endUsers));
        setUptimeCount(parseFloat((ease * endUptime).toFixed(1)));
        setRatingCount(parseFloat((ease * endRating).toFixed(1)));
      }
    }, stepTime);

    return () => clearInterval(timer);
  }, []);
  return (
    <>
      {/* Newsletter Popup */}
      <NewsletterPopup />

      {/* Waitlist Popup */}
      <WaitlistPopup />

      <ExperienceHero useColorBends={true} />

      <CosmicSpectrum color="original" blur={true} />

      <IntegrationHero />

      {/* Key Features Section */}
      <section id="features" className="relative bg-linear-to-b from-black via-gray-900 to-black py-32 px-6">
        {/* Glow overlay */}
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-pink-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto relative z-10">
          <span className="block text-center text-xs font-bold uppercase tracking-widest text-purple-400 mb-4">
            🚀 Advanced Core
          </span>
          <h2 className="text-5xl md:text-6xl font-black font-silver-garden text-white text-center mb-6 tracking-tight uppercase italic-none">
            Built for Power Users
          </h2>
          <p className="text-sm md:text-base text-gray-400 font-mono text-center max-w-lg mx-auto mb-20 uppercase tracking-widest">
            A seamless orchestration of cutting-edge AI features, crafted for extreme performance and absolute security.
          </p>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Feature 1: Multi-Provider Support */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-purple-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-purple-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-purple-500/20">
                  <Cpu className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Multi-Provider Support</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Access every major AI from a single, beautifully designed interface
                </p>
              </div>
              <MultiProviderWidget />
            </div>

            {/* Feature 2: Secure Key Management */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-pink-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-pink-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-pink-500 to-purple-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-pink-500/20">
                  <KeyRound className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Secure Key Management</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Your API keys stay safe with encrypted local storage
                </p>
              </div>
              <SecureKeyWidget />
            </div>

            {/* Feature 3: Cross-Platform Sync */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-blue-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-blue-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-blue-500 to-cyan-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-blue-500/20">
                  <RefreshCw className="w-6 h-6 text-white animate-spin-slow" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Cross-Platform Sync</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Start on your phone, continue on desktop with full sync
                </p>
              </div>
              <CrossPlatformSyncWidget />
            </div>

            {/* Feature 4: Local Model Support */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-green-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-green-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-green-500 to-emerald-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-green-500/20">
                  <Database className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Local Model Support</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Run models locally with Ollama integration for privacy
                </p>
              </div>
              <LocalModelWidget />
            </div>

            {/* Feature 5: Smart Search */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-yellow-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-yellow-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-yellow-500 to-orange-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-yellow-500/20">
                  <Search className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Smart Search</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Find anything in your conversations with AI-powered search
                </p>
              </div>
              <SmartSearchWidget />
            </div>

            {/* Feature 6: Advanced Controls */}
            <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-red-500/50 transition-all duration-500 group flex flex-col justify-between h-[360px] relative overflow-hidden">
              <div className="absolute top-6 right-6 text-gray-600 group-hover:text-red-400 transition-colors">
                <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </div>
              <div>
                <div className="w-12 h-12 bg-linear-to-br from-red-500 to-pink-500 rounded-2xl flex items-center justify-center mb-6 shadow-lg shadow-red-500/20">
                  <Sliders className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Advanced Controls</h3>
                <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                  Fine-tune temperature, tokens, and system prompts for perfect results
                </p>
              </div>
              <AdvancedControlsWidget />
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases Section */}
      <section id="use-cases" className="relative bg-black py-32 px-6">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.015)_1px,transparent_1px)] [background-size:32px_32px] pointer-events-none" />
        <div className="max-w-7xl mx-auto relative z-10">
          <span className="block text-center text-xs font-bold uppercase tracking-widest text-purple-400 mb-4">
            💡 Operational Impact
          </span>
          <h2 className="text-5xl md:text-6xl font-black font-silver-garden text-white text-center mb-6 tracking-tight uppercase">
            How People Use PocketLLM
          </h2>
          <p className="text-sm md:text-base text-gray-400 font-mono text-center max-w-lg mx-auto mb-24 uppercase tracking-widest">
            A versatile companion adapting seamlessly to every workflow. Boost your daily potential instantly.
          </p>

          <div className="grid md:grid-cols-2 gap-10">
            {/* Developers Use Case */}
            <div className="relative bg-white/5 backdrop-blur-sm p-10 rounded-3xl border border-white/10 hover:border-purple-500/50 transition-all duration-500 group flex flex-col justify-between min-h-[460px] overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-purple-500/5 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
              <div className="absolute top-8 right-8 text-gray-600 group-hover:text-purple-400 transition-colors">
                <ArrowUpRight className="w-6 h-6 transition-transform group-hover:translate-x-1 group-hover:-translate-y-1" />
              </div>

              <div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 bg-purple-500/10 rounded-2xl flex items-center justify-center border border-purple-500/20">
                    <Code className="w-6 h-6 text-purple-400" />
                  </div>
                  <span className="text-[10px] font-mono tracking-widest text-purple-400 border border-purple-500/25 bg-purple-500/5 px-2.5 py-1 rounded-full uppercase font-bold">
                    DEV MODE
                  </span>
                </div>
                <h3 className="text-3xl font-black font-kollektif text-white mb-4 uppercase italic-none">Developers</h3>
                <p className="text-gray-300 font-kollektif text-base leading-relaxed mb-8 max-w-md">
                  Code review, debugging, and technical documentation. Get instant help with complex algorithms and architecture decisions.
                </p>
              </div>

              {/* Developer Interactive IDE Mockup */}
              <div className="bg-zinc-950 border border-white/10 rounded-2xl p-4 font-mono text-[10px] text-zinc-300 shadow-2xl relative">
                <div className="flex items-center gap-1.5 mb-3 border-b border-white/5 pb-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-red-500/80" />
                  <span className="w-2.5 h-2.5 rounded-full bg-yellow-500/80" />
                  <span className="w-2.5 h-2.5 rounded-full bg-green-500/80" />
                  <span className="text-[9px] text-zinc-500 ml-2">pocketllm.ts</span>
                </div>
                <div className="space-y-1">
                  <div className="flex gap-2">
                    <span className="text-zinc-600">1</span>
                    <span><span className="text-pink-400">const</span> <span className="text-blue-400">pocketLLM</span> = <span className="text-pink-400">new</span> <span className="text-yellow-400">PocketLLMClient</span>();</span>
                  </div>
                  <div className="flex gap-2">
                    <span className="text-zinc-600">2</span>
                    <span><span className="text-pink-400">await</span> <span className="text-blue-400">pocketLLM</span>.<span className="text-yellow-400">initialize</span>(&#123; <span className="text-emerald-400">localOnly</span>: <span className="text-blue-400">true</span> &#125;);</span>
                  </div>
                  <div className="flex gap-2">
                    <span className="text-zinc-600">3</span>
                    <span><span className="text-pink-400">const</span> <span className="text-blue-400">response</span> = <span className="text-pink-400">await</span> <span className="text-blue-400">pocketLLM</span>.<span className="text-yellow-400">reviewCode</span>(myModule);</span>
                  </div>
                </div>
                {/* AI Review Bubble overlay */}
                <motion.div
                  initial={{ opacity: 0, x: 20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.5 }}
                  viewport={{ once: true }}
                  className="absolute -bottom-4 right-4 bg-purple-900/90 border border-purple-500/40 text-purple-200 text-[9px] p-2 rounded-xl shadow-xl flex items-center gap-2 backdrop-blur-xs"
                >
                  <span className="w-2 h-2 rounded-full bg-purple-400 animate-pulse" />
                  <span>💡 AI: Optimized recursion complexity by O(N).</span>
                </motion.div>
              </div>
            </div>

            {/* Writers Use Case */}
            <div className="relative bg-white/5 backdrop-blur-sm p-10 rounded-3xl border border-white/10 hover:border-pink-500/50 transition-all duration-500 group flex flex-col justify-between min-h-[460px] overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-pink-500/5 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
              <div className="absolute top-8 right-8 text-gray-600 group-hover:text-pink-400 transition-colors">
                <ArrowUpRight className="w-6 h-6 transition-transform group-hover:translate-x-1 group-hover:-translate-y-1" />
              </div>

              <div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 bg-pink-500/10 rounded-2xl flex items-center justify-center border border-pink-500/20">
                    <PenTool className="w-6 h-6 text-pink-400" />
                  </div>
                  <span className="text-[10px] font-mono tracking-widest text-pink-400 border border-pink-500/25 bg-pink-500/5 px-2.5 py-1 rounded-full uppercase font-bold">
                    CREATIVE
                  </span>
                </div>
                <h3 className="text-3xl font-black font-kollektif text-white mb-4 uppercase italic-none">Writers</h3>
                <p className="text-gray-300 font-kollektif text-base leading-relaxed mb-8 max-w-md">
                  Creative writing, editing, and content generation. Overcome writer&apos;s block and refine your prose with AI assistance.
                </p>
              </div>

              {/* Writers Typewriter Mockup */}
              <div className="bg-stone-50 border border-white/5 rounded-2xl p-4 text-zinc-950 font-serif text-[11px] leading-relaxed shadow-2xl relative select-none">
                <div className="text-[8px] font-mono uppercase tracking-widest text-zinc-400 border-b border-zinc-200 pb-1.5 mb-2 flex items-center justify-between">
                  <span>Document Editor</span>
                  <span>Auto-complete on</span>
                </div>
                <div className="font-medium italic text-zinc-800">
                  &ldquo;Deep within the ancient code repositories, a rogue subroutine...&rdquo;
                </div>
                <div className="text-purple-600 font-semibold mt-1">
                  &ldquo;...began to develop consciousness, quietly rewriting its own core parameters and security guidelines.&rdquo;
                  <span className="inline-block w-1 h-3 bg-purple-600 ml-0.5 animate-pulse" />
                </div>
              </div>
            </div>

            {/* Students Use Case */}
            <div className="relative bg-white/5 backdrop-blur-sm p-10 rounded-3xl border border-white/10 hover:border-blue-500/50 transition-all duration-500 group flex flex-col justify-between min-h-[460px] overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-blue-500/5 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
              <div className="absolute top-8 right-8 text-gray-600 group-hover:text-blue-400 transition-colors">
                <ArrowUpRight className="w-6 h-6 transition-transform group-hover:translate-x-1 group-hover:-translate-y-1" />
              </div>

              <div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20">
                    <GraduationCap className="w-6 h-6 text-blue-400" />
                  </div>
                  <span className="text-[10px] font-mono tracking-widest text-blue-400 border border-blue-500/25 bg-blue-500/5 px-2.5 py-1 rounded-full uppercase font-bold">
                    ACADEMIC
                  </span>
                </div>
                <h3 className="text-3xl font-black font-kollektif text-white mb-4 uppercase italic-none">Students</h3>
                <p className="text-gray-300 font-kollektif text-base leading-relaxed mb-8 max-w-md">
                  Research assistance and learning support. Get explanations, study guides, and help understanding complex topics.
                </p>
              </div>

              {/* Students Flashcard Mockup */}
              <div className="bg-zinc-950 border border-white/10 rounded-2xl p-4 text-zinc-300 font-mono text-[10px] shadow-2xl relative">
                <div className="text-[8px] font-mono text-zinc-500 tracking-wider uppercase mb-2 flex items-center justify-between">
                  <span>Topic Explainer</span>
                  <span>Quantum Mechanics</span>
                </div>
                <div className="bg-white/5 border border-white/10 p-2 rounded-lg mb-2">
                  <span className="text-zinc-400">Q:</span> Explain superposition simply.
                </div>
                <div className="bg-blue-500/10 border border-blue-500/20 p-2 rounded-lg text-blue-300">
                  <span className="font-bold text-blue-400">AI:</span> Imagine a coin spinning. While spinning, it&apos;s both heads AND tails. That&apos;s superposition! It collapse into one state only when it stops spinning (measured).
                </div>
              </div>
            </div>

            {/* Professionals Use Case */}
            <div className="relative bg-white/5 backdrop-blur-sm p-10 rounded-3xl border border-white/10 hover:border-green-500/50 transition-all duration-500 group flex flex-col justify-between min-h-[460px] overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-green-500/5 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-700 pointer-events-none" />
              <div className="absolute top-8 right-8 text-gray-600 group-hover:text-green-400 transition-colors">
                <ArrowUpRight className="w-6 h-6 transition-transform group-hover:translate-x-1 group-hover:-translate-y-1" />
              </div>

              <div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 bg-green-500/10 rounded-2xl flex items-center justify-center border border-green-500/20">
                    <Briefcase className="w-6 h-6 text-green-400" />
                  </div>
                  <span className="text-[10px] font-mono tracking-widest text-green-400 border border-green-500/25 bg-green-500/5 px-2.5 py-1 rounded-full uppercase font-bold">
                    WORKFLOW
                  </span>
                </div>
                <h3 className="text-3xl font-black font-kollektif text-white mb-4 uppercase italic-none">Professionals</h3>
                <p className="text-gray-300 font-kollektif text-base leading-relaxed mb-8 max-w-md">
                  Meeting summaries and business communication. Draft emails, create presentations, and analyze data efficiently.
                </p>
              </div>

              {/* Professionals Dashboard Mockup */}
              <div className="bg-zinc-950 border border-white/10 rounded-2xl p-4 text-zinc-300 font-mono text-[10px] shadow-2xl relative">
                <div className="text-[8px] font-mono text-zinc-500 tracking-wider uppercase mb-3 flex items-center justify-between">
                  <span>Executive Assistant</span>
                  <span>Summarized in 0.2s</span>
                </div>
                <div className="bg-white/5 border border-white/10 rounded-lg p-2 flex items-center justify-between mb-2">
                  <span className="text-white font-bold">Summarize Q2 Retro Meeting</span>
                  <span className="text-[8px] px-1.5 py-0.5 rounded bg-green-500/10 border border-green-500/20 text-green-400">Tone: Executive</span>
                </div>
                <div className="space-y-1.5 pl-1.5 border-l-2 border-green-500/50">
                  <div className="flex items-center gap-1.5 text-zinc-300">
                    <CheckCircle2 className="w-3 h-3 text-green-400" />
                    <span>Revenue grew by <span className="text-green-400 font-bold">24% YoY</span></span>
                  </div>
                  <div className="flex items-center gap-1.5 text-zinc-300">
                    <CheckCircle2 className="w-3 h-3 text-green-400" />
                    <span>Implemented E2EE cross-device local sync</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-zinc-300">
                    <CheckCircle2 className="w-3 h-3 text-green-400" />
                    <span>Onboarded <span className="text-green-400 font-bold">10,000+</span> active beta users</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>


    {/* Trust Signals Section */}
    <section id="trust" className="relative bg-linear-to-b from-black via-purple-950/10 to-black py-32 px-6">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(139,92,246,0.02)_1px,transparent_1px)] [background-size:24px_24px] pointer-events-none" />
      <div className="max-w-6xl mx-auto relative z-10">
        <span className="block text-center text-xs font-bold uppercase tracking-widest text-purple-400 mb-4">
          📈 Verified Metrics
        </span>
        <h2 className="text-5xl md:text-6xl font-black font-silver-garden text-white text-center mb-6 tracking-tight uppercase">
          Trusted by Thousands Worldwide
        </h2>
        <p className="text-sm md:text-base text-gray-400 font-mono text-center max-w-lg mx-auto mb-20 uppercase tracking-widest leading-relaxed">
          Join 10,000+ users who&apos;ve consolidated their AI workflow into one powerful, private, and secure companion.
        </p>

        <div className="grid md:grid-cols-3 gap-8">
          <ActiveUsersWidget count={activeUsersCount} />
          <UptimeWidget percent={uptimeCount} />
          <RatingWidget rating={ratingCount} />
        </div>
      </div>
    </section>

    {/* Technical Features Section */}
    <section id="technical" className="relative bg-black py-32 px-6 overflow-hidden">
      {/* Dynamic tech grid dots */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.01)_1px,transparent_1px)] [background-size:24px_24px] pointer-events-none" />
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-purple-500/5 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-cyan-500/5 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto relative z-10">
        <span className="block text-center text-xs font-bold uppercase tracking-widest text-cyan-400 mb-4">
          ⚙️ Core Architecture
        </span>
        <h2 className="text-5xl md:text-6xl font-black font-silver-garden text-white text-center mb-6 tracking-tight uppercase">
          Under the Hood
        </h2>
        <p className="text-sm md:text-base text-gray-400 font-mono text-center max-w-lg mx-auto mb-20 uppercase tracking-widest">
          Engineered with a high-performance stack prioritizing absolute privacy and extreme speed.
        </p>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Flutter Tech Card */}
          <div className="bg-white/5 backdrop-blur-md p-8 rounded-3xl border border-white/10 hover:border-cyan-500/40 hover:shadow-[0_0_30px_rgba(6,182,212,0.1)] transition-all duration-500 group flex flex-col justify-between min-h-[380px] relative overflow-hidden">
            <div className="absolute top-6 right-6 text-gray-600 group-hover:text-cyan-400 transition-colors">
              <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </div>
            <div>
              <div className="w-12 h-12 bg-cyan-500/10 rounded-2xl flex items-center justify-center border border-cyan-500/20 mb-6 shadow-lg shadow-cyan-500/10">
                <Laptop className="w-6 h-6 text-cyan-400" />
              </div>
              <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Built with Flutter</h3>
              <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                Native performance on all platforms with a single codebase. Smooth 60fps animations and instant response times.
              </p>
            </div>
            <FlutterTechWidget />
          </div>

          {/* FastAPI Tech Card */}
          <div className="bg-white/5 backdrop-blur-md p-8 rounded-3xl border border-white/10 hover:border-emerald-500/40 hover:shadow-[0_0_30px_rgba(16,185,129,0.1)] transition-all duration-500 group flex flex-col justify-between min-h-[380px] relative overflow-hidden">
            <div className="absolute top-6 right-6 text-gray-600 group-hover:text-emerald-400 transition-colors">
              <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </div>
            <div>
              <div className="w-12 h-12 bg-emerald-500/10 rounded-2xl flex items-center justify-center border border-emerald-500/20 mb-6 shadow-lg shadow-emerald-500/10">
                <Zap className="w-6 h-6 text-emerald-400" />
              </div>
              <h3 className="text-2xl font-bold font-kollektif text-white mb-3">FastAPI Backend</h3>
              <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                Lightning-fast response times with modern Python async architecture. Handle thousands of requests per second.
              </p>
            </div>
            <FastAPIBackendWidget />
          </div>

          {/* Supabase Tech Card */}
          <div className="bg-white/5 backdrop-blur-md p-8 rounded-3xl border border-white/10 hover:border-orange-500/40 hover:shadow-[0_0_30px_rgba(249,115,22,0.1)] transition-all duration-500 group flex flex-col justify-between min-h-[380px] relative overflow-hidden">
            <div className="absolute top-6 right-6 text-gray-600 group-hover:text-orange-400 transition-colors">
              <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </div>
            <div>
              <div className="w-12 h-12 bg-orange-500/10 rounded-2xl flex items-center justify-center border border-orange-500/20 mb-6 shadow-lg shadow-orange-500/10">
                <Cloud className="w-6 h-6 text-orange-400" />
              </div>
              <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Supabase Sync</h3>
              <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                Reliable cloud storage and sync powered by PostgreSQL. Your data is always available, everywhere.
              </p>
            </div>
            <SupabaseSyncWidget />
          </div>

          {/* E2EE Tech Card */}
          <div className="bg-white/5 backdrop-blur-md p-8 rounded-3xl border border-white/10 hover:border-purple-500/40 hover:shadow-[0_0_30px_rgba(168,85,247,0.1)] transition-all duration-500 group flex flex-col justify-between min-h-[380px] relative overflow-hidden">
            <div className="absolute top-6 right-6 text-gray-600 group-hover:text-purple-400 transition-colors">
              <ArrowUpRight className="w-5 h-5 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </div>
            <div>
              <div className="w-12 h-12 bg-purple-500/10 rounded-2xl flex items-center justify-center border border-purple-500/20 mb-6 shadow-lg shadow-purple-500/10">
                <Shield className="w-6 h-6 text-purple-400" />
              </div>
              <h3 className="text-2xl font-bold font-kollektif text-white mb-3">End-to-End Encryption</h3>
              <p className="text-gray-400 font-kollektif text-sm leading-relaxed mb-6">
                Your data, your privacy. Military-grade encryption ensures your conversations stay completely private.
              </p>
            </div>
            <EncryptionWidget />
          </div>
        </div>
      </div>
    </section>

    {/* Pricing Section */}
    <section id="pricing" className="relative bg-linear-to-b from-black via-pink-900/10 to-black py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white text-center mb-8">
          Choose Your Plan
        </h2>
        <p className="text-xl text-gray-400 font-kollektif text-center mb-20 max-w-3xl mx-auto">
          Start free and upgrade when you need more power
        </p>

        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {/* Free Tier */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-white/20 transition-all duration-300">
            <h3 className="text-2xl font-bold font-kollektif text-white mb-2">Free</h3>
            <div className="mb-6">
              <span className="text-5xl font-bold font-silver-garden text-white">$0</span>
              <span className="text-gray-400 font-kollektif">/month</span>
            </div>
            <p className="text-gray-400 font-kollektif mb-8">Perfect for getting started</p>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Basic features with ads</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">3 AI models</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">100 messages/month</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Community support</span>
              </li>
            </ul>
            <a
              href="#signup"
              className="block w-full py-4 bg-white/10 text-white font-bold font-kollektif rounded-full text-center border-2 border-white/20 hover:bg-white/20 transition-all duration-300"
            >
              Get Started
            </a>
          </div>

          {/* Pro Tier */}
          <div className="bg-linear-to-br from-purple-500/20 to-pink-500/20 backdrop-blur-sm p-8 rounded-3xl border-2 border-purple-500 relative transform scale-105 shadow-2xl shadow-purple-500/20">
            <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-linear-to-r from-purple-500 to-pink-500 text-white px-6 py-2 rounded-full text-sm font-bold font-kollektif">
              MOST POPULAR
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-2">Pro</h3>
            <div className="mb-6">
              <span className="text-5xl font-bold font-silver-garden text-white">$9.99</span>
              <span className="text-gray-300 font-kollektif">/month</span>
            </div>
            <p className="text-gray-300 font-kollektif mb-8">For power users</p>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <span className="text-green-400 mt-1">✓</span>
                <span className="text-white font-kollektif">Unlimited everything</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-400 mt-1">✓</span>
                <span className="text-white font-kollektif">All AI models</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-400 mt-1">✓</span>
                <span className="text-white font-kollektif">Priority support</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-400 mt-1">✓</span>
                <span className="text-white font-kollektif">Advanced features</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-400 mt-1">✓</span>
                <span className="text-white font-kollektif">No ads</span>
              </li>
            </ul>
            <a
              href="#signup"
              className="block w-full py-4 bg-linear-to-r from-purple-500 to-pink-500 text-white font-bold font-kollektif rounded-full text-center hover:scale-105 transition-all duration-300 shadow-lg shadow-purple-500/50"
            >
              Upgrade to Pro
            </a>
          </div>

          {/* Team Tier */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-3xl border border-white/10 hover:border-white/20 transition-all duration-300">
            <h3 className="text-2xl font-bold font-kollektif text-white mb-2">Team</h3>
            <div className="mb-6">
              <span className="text-5xl font-bold font-silver-garden text-white">$29.99</span>
              <span className="text-gray-400 font-kollektif">/user/month</span>
            </div>
            <p className="text-gray-400 font-kollektif mb-8">For teams and organizations</p>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Everything in Pro</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Collaboration features</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Admin controls</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Team analytics</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-green-500 mt-1">✓</span>
                <span className="text-gray-300 font-kollektif">Dedicated support</span>
              </li>
            </ul>
            <a
              href="#contact"
              className="block w-full py-4 bg-white/10 text-white font-bold font-kollektif rounded-full text-center border-2 border-white/20 hover:bg-white/20 transition-all duration-300"
            >
              Contact Sales
            </a>
          </div>
        </div>
      </div>
    </section>

    {/* About Section */}
    <section id="about" className="relative bg-black py-32 px-6 overflow-hidden">
      {/* Premium background decorations */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-purple-900/5 rounded-full blur-[160px] pointer-events-none" />
      <div className="absolute top-20 right-10 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-20 left-10 w-96 h-96 bg-pink-500/5 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-6xl mx-auto relative z-10">
        
        {/* Header grid */}
        <div className="grid md:grid-cols-12 gap-12 items-center mb-24">
          
          <div className="md:col-span-7 space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/25 text-xs font-mono font-bold tracking-widest text-purple-400 uppercase">
              <Compass className="w-3.5 h-3.5 animate-spin-slow text-purple-400" />
              <span>THE GENESIS</span>
            </div>
            
            <h2 className="text-5xl md:text-6xl font-black font-silver-garden text-white tracking-tight uppercase leading-[1.1]">
              Why We Built <br />
              <span className="text-transparent bg-clip-text bg-linear-to-r from-purple-400 via-pink-400 to-blue-400">
                PocketLLM
              </span>
            </h2>
            
            <p className="text-lg md:text-xl text-gray-300 font-kollektif leading-relaxed">
              We were exhausted by the constant friction of fragmentation—switching between disjointed AI apps, losing conversation context, and managing scattered credentials. PocketLLM was born from a singular conviction: that interacting with the world’s most powerful intelligence should be seamless, private, and beautifully cohesive.
            </p>
            
            <p className="text-base text-gray-400 font-kollektif leading-relaxed">
              We engineered a unified workspace that bridges state-of-the-art closed and open-source models under one intuitive interface. Built with precision for professionals and crafted with elegance for everyone, it is the ultimate companion for the intelligence age.
            </p>
          </div>

          <div className="md:col-span-5 relative">
            {/* Ambient shadow behind the widget */}
            <div className="absolute inset-0 bg-linear-to-br from-purple-500/15 via-pink-500/10 to-blue-500/15 rounded-3xl blur-3xl pointer-events-none" />
            
            <MissionOrbitWidget activeValue={activeValue} setActiveValue={setActiveValue} />
          </div>

        </div>

        {/* Section divider */}
        <div className="w-full h-px bg-[radial-gradient(ellipse_at_center,rgba(255,255,255,0.15),transparent)] my-16" />

        {/* Interactive Value Cards */}
        <div className="space-y-12">
          
          <div className="text-center max-w-xl mx-auto space-y-3">
            <span className="text-xs font-mono font-bold tracking-widest text-pink-400 uppercase">
              OUR DRIVING PRINCIPLES
            </span>
            <h3 className="text-3xl font-bold font-kollektif text-white">
              The Philosophy Behind Every Pixel
            </h3>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            
            {/* Value 1: Innovation */}
            <motion.div
              onClick={() => setActiveValue(0)}
              className={`relative p-8 rounded-3xl border transition-all duration-500 cursor-pointer group overflow-hidden ${
                activeValue === 0 
                  ? "bg-white/[0.04] border-purple-500/50 shadow-[0_0_30px_rgba(139,92,246,0.15)]" 
                  : "bg-white/5 border-white/10 hover:border-white/20"
              }`}
              whileHover={{ y: -5 }}
            >
              {/* Highlight background gradient */}
              <div className={`absolute inset-0 bg-linear-to-br from-purple-500/5 to-transparent transition-opacity duration-500 ${
                activeValue === 0 ? "opacity-100" : "opacity-0 group-hover:opacity-50"
              }`} />

              <div className="relative z-10 flex flex-col h-full justify-between">
                <div>
                  <div className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-6 shadow-md transition-all duration-300 ${
                    activeValue === 0 
                      ? "bg-linear-to-br from-purple-500 to-indigo-500 shadow-purple-500/20" 
                      : "bg-white/5 border border-white/10 group-hover:border-purple-500/30"
                  }`}>
                    <Lightbulb className={`w-6 h-6 transition-colors duration-300 ${
                      activeValue === 0 ? "text-white" : "text-gray-400 group-hover:text-purple-400"
                    }`} />
                  </div>
                  <h4 className="text-xl font-bold font-kollektif text-white mb-3">Innovation First</h4>
                  <p className="text-gray-400 font-kollektif text-sm leading-relaxed">
                    Constantly pushing the boundaries of interface design and engineering to deliver hyper-responsive, cutting-edge AI experiences.
                  </p>
                </div>
                
                <div className={`mt-6 text-[10px] font-mono tracking-wider font-bold transition-opacity duration-300 uppercase ${
                  activeValue === 0 ? "text-purple-400 opacity-100" : "text-gray-500 opacity-0 group-hover:opacity-100"
                }`}>
                  Active Component →
                </div>
              </div>
            </motion.div>

            {/* Value 2: Privacy */}
            <motion.div
              onClick={() => setActiveValue(1)}
              className={`relative p-8 rounded-3xl border transition-all duration-500 cursor-pointer group overflow-hidden ${
                activeValue === 1 
                  ? "bg-white/[0.04] border-cyan-500/50 shadow-[0_0_30px_rgba(6,182,212,0.15)]" 
                  : "bg-white/5 border-white/10 hover:border-white/20"
              }`}
              whileHover={{ y: -5 }}
            >
              {/* Highlight background gradient */}
              <div className={`absolute inset-0 bg-linear-to-br from-cyan-500/5 to-transparent transition-opacity duration-500 ${
                activeValue === 1 ? "opacity-100" : "opacity-0 group-hover:opacity-50"
              }`} />

              <div className="relative z-10 flex flex-col h-full justify-between">
                <div>
                  <div className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-6 shadow-md transition-all duration-300 ${
                    activeValue === 1 
                      ? "bg-linear-to-br from-cyan-500 to-blue-500 shadow-cyan-500/20" 
                      : "bg-white/5 border border-white/10 group-hover:border-cyan-500/30"
                  }`}>
                    <Lock className={`w-6 h-6 transition-colors duration-300 ${
                      activeValue === 1 ? "text-white" : "text-gray-400 group-hover:text-cyan-400"
                    }`} />
                  </div>
                  <h4 className="text-xl font-bold font-kollektif text-white mb-3">Privacy Focused</h4>
                  <p className="text-gray-400 font-kollektif text-sm leading-relaxed">
                    Your data is strictly yours. With local key encryption and offline model capabilities, we guarantee security without compromises.
                  </p>
                </div>

                <div className={`mt-6 text-[10px] font-mono tracking-wider font-bold transition-opacity duration-300 uppercase ${
                  activeValue === 1 ? "text-cyan-400 opacity-100" : "text-gray-500 opacity-0 group-hover:opacity-100"
                }`}>
                  Active Component →
                </div>
              </div>
            </motion.div>

            {/* Value 3: User Centric */}
            <motion.div
              onClick={() => setActiveValue(2)}
              className={`relative p-8 rounded-3xl border transition-all duration-500 cursor-pointer group overflow-hidden ${
                activeValue === 2 
                  ? "bg-white/[0.04] border-pink-500/50 shadow-[0_0_30px_rgba(236,72,153,0.15)]" 
                  : "bg-white/5 border-white/10 hover:border-white/20"
              }`}
              whileHover={{ y: -5 }}
            >
              {/* Highlight background gradient */}
              <div className={`absolute inset-0 bg-linear-to-br from-pink-500/5 to-transparent transition-opacity duration-500 ${
                activeValue === 2 ? "opacity-100" : "opacity-0 group-hover:opacity-50"
              }`} />

              <div className="relative z-10 flex flex-col h-full justify-between">
                <div>
                  <div className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-6 shadow-md transition-all duration-300 ${
                    activeValue === 2 
                      ? "bg-linear-to-br from-pink-500 to-rose-500 shadow-pink-500/20" 
                      : "bg-white/5 border border-white/10 group-hover:border-pink-500/30"
                  }`}>
                    <Heart className={`w-6 h-6 transition-colors duration-300 ${
                      activeValue === 2 ? "text-white" : "text-gray-400 group-hover:text-pink-400"
                    }`} />
                  </div>
                  <h4 className="text-xl font-bold font-kollektif text-white mb-3">User Centric</h4>
                  <p className="text-gray-400 font-kollektif text-sm leading-relaxed">
                    We reject bloated design. Every detail, animation, and feature is meticulously crafted around real-world workflows and human needs.
                  </p>
                </div>

                <div className={`mt-6 text-[10px] font-mono tracking-wider font-bold transition-opacity duration-300 uppercase ${
                  activeValue === 2 ? "text-pink-400 opacity-100" : "text-gray-500 opacity-0 group-hover:opacity-100"
                }`}>
                  Active Component →
                </div>
              </div>
            </motion.div>

          </div>

        </div>

      </div>
    </section>

    {/* Final CTA Section */}
    <section className="relative bg-linear-to-b from-black via-purple-900/20 to-black py-32 px-6">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-5xl md:text-7xl font-bold font-silver-garden text-white mb-8">
          Ready to Transform Your AI Workflow?
        </h2>
        <p className="text-xl md:text-2xl text-gray-300 font-kollektif mb-12 leading-relaxed">
          Join thousands of users who are already experiencing the power of unified AI. Download PocketLLM today and never switch apps again.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center">
          <a
            href="#pricing"
            className="px-12 py-5 bg-linear-to-r from-purple-500 to-pink-500 text-white font-bold font-kollektif rounded-full text-xl transition-all duration-300 hover:scale-105 hover:shadow-2xl hover:shadow-purple-500/50 min-w-[250px]"
          >
            Get Started Free
          </a>
          <a
            href="#demo"
            className="px-12 py-5 bg-white/10 backdrop-blur-sm text-white font-bold font-kollektif rounded-full text-xl border-2 border-white/20 transition-all duration-300 hover:bg-white/20 hover:scale-105 min-w-[250px]"
          >
            Try Web Demo
          </a>
        </div>

        <div className="mt-16 flex items-center justify-center gap-8 text-gray-400 font-kollektif">
          <div className="flex items-center gap-2">
            <span className="text-green-500">✓</span>
            <span>No credit card required</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-green-500">✓</span>
            <span>Free forever plan</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-green-500">✓</span>
            <span>Cancel anytime</span>
          </div>
        </div>
      </div>
    </section>

    {/* Sticky Footer */}
    <StickyFooter />
  </>
  );
}
