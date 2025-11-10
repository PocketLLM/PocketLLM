import { TextAnimate } from "@/components/ui/text-animate";
import { Highlighter } from "@/components/ui/highlighter";
import ColorBends from "@/components/ui/ColorBends";
import StickyFooter from "@/components/ui/footer";
import GitHubStarButton from "@/components/ui/github-star-button";
import NewsletterPopup from "@/components/ui/newsletter-popup";
import WaitlistPopup from "@/components/ui/waitlist-popup";

export default function Home() {
  return (
    <>
      {/* Newsletter Popup */}
      <NewsletterPopup />

      {/* Waitlist Popup */}
      <WaitlistPopup />

      <div className="relative min-h-screen w-full pt-20">
        {/* Background */}
        <div className="absolute inset-0 z-0">
          <ColorBends />
        </div>

        {/* Content */}
        <main className="relative z-10 flex min-h-screen flex-col items-center justify-center px-6 py-20 text-center max-w-5xl mx-auto">
        {/* Hero Title */}
        <div className="mb-12">
          <div className="mb-8">
            <TextAnimate
              animation="blurIn"
              by="character"
              duration={2}
              delay={0.1}
              className="text-5xl md:text-7xl lg:text-8xl font-bold font-silver-garden text-white drop-shadow-[0_0_30px_rgba(255,255,255,0.5)]"
              as="h1"
            >
              PocketLLM.
            </TextAnimate>
          </div>

          <TextAnimate
            animation="blurIn"
            by="character"
            duration={2}
            delay={0.9}
            className="text-3xl md:text-4xl lg:text-5xl font-bold font-kollektif text-white drop-shadow-[0_0_20px_rgba(255,255,255,0.4)]"
            as="h2"
          >
            Your Pocket AI. One chat for every LLM.
          </TextAnimate>
        </div>

        {/* Subtext */}
        <div className="mb-12 max-w-3xl">
          <p className="text-lg md:text-xl lg:text-2xl font-kollektif text-gray-200 leading-relaxed">
            Connect{" "}
            <Highlighter action="highlight" color="#8B5CF6" isView>
              OpenAI
            </Highlighter>
            ,{" "}
            <Highlighter action="highlight" color="#EC4899" isView>
              Gemini
            </Highlighter>
            ,{" "}
            <Highlighter action="highlight" color="#3B82F6" isView>
              Groq
            </Highlighter>
            , and more. Manage conversations, switch models instantly, and carry serious AI power in one app. Built with Flutter for fast, cross-platform delivery.
          </p>
        </div>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center mb-8">
          <a
            href="#pricing"
            className="px-8 py-4 bg-linear-to-r from-purple-500 to-pink-500 text-white font-bold font-kollektif rounded-full text-lg transition-all duration-300 hover:scale-105 hover:shadow-2xl hover:shadow-purple-500/50 min-w-[200px]"
          >
            Get Started Free
          </a>
          <a
            href="#demo"
            className="px-8 py-4 bg-white/10 backdrop-blur-sm text-white font-bold font-kollektif rounded-full text-lg border-2 border-white/20 transition-all duration-300 hover:bg-white/20 hover:scale-105 min-w-[200px]"
          >
            Try Web Demo
          </a>
        </div>

        {/* GitHub Star Button */}
        <div className="flex justify-center">
          <GitHubStarButton repo="PocketLLM/PocketLLM" />
        </div>
      </main>
    </div>

    {/* Models Showcase Section */}
    <section id="models" className="relative bg-black py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white text-center mb-8">
          All AI Models, One App
        </h2>
        <p className="text-xl md:text-2xl text-gray-300 font-kollektif text-center max-w-4xl mx-auto mb-16 leading-relaxed">
          Why juggle multiple apps when you can have them all? PocketLLM integrates with every major AI provider including OpenAI&apos;s GPT models, Google&apos;s Gemini, Groq&apos;s lightning-fast inference, and local Ollama models. Switch seamlessly between models without losing context.
        </p>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="group bg-linear-to-br from-purple-500/10 to-purple-500/5 backdrop-blur-sm p-8 rounded-2xl border border-purple-500/20 hover:border-purple-500 transition-all duration-300 hover:scale-105">
            <div className="text-4xl mb-4">🤖</div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-3">OpenAI GPT</h3>
            <p className="text-gray-400 font-kollektif text-sm">
              GPT-4, GPT-3.5, and all variants
            </p>
          </div>

          <div className="group bg-linear-to-br from-pink-500/10 to-pink-500/5 backdrop-blur-sm p-8 rounded-2xl border border-pink-500/20 hover:border-pink-500 transition-all duration-300 hover:scale-105">
            <div className="text-4xl mb-4">✨</div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Google Gemini</h3>
            <p className="text-gray-400 font-kollektif text-sm">
              Gemini Pro and Ultra models
            </p>
          </div>

          <div className="group bg-linear-to-br from-blue-500/10 to-blue-500/5 backdrop-blur-sm p-8 rounded-2xl border border-blue-500/20 hover:border-blue-500 transition-all duration-300 hover:scale-105">
            <div className="text-4xl mb-4">⚡</div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Groq</h3>
            <p className="text-gray-400 font-kollektif text-sm">
              Lightning-fast inference engine
            </p>
          </div>

          <div className="group bg-linear-to-br from-green-500/10 to-green-500/5 backdrop-blur-sm p-8 rounded-2xl border border-green-500/20 hover:border-green-500 transition-all duration-300 hover:scale-105">
            <div className="text-4xl mb-4">🏠</div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Ollama</h3>
            <p className="text-gray-400 font-kollektif text-sm">
              Run models locally for privacy
            </p>
          </div>
        </div>
      </div>
    </section>

    {/* Key Features Section */}
    <section id="features" className="relative bg-linear-to-b from-black via-gray-900 to-black py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white text-center mb-20">
          Built for Power Users
        </h2>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {/* Feature 1 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-purple-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">🔗</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Multi-Provider Support</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Access every major AI from a single, beautifully designed interface
            </p>
          </div>

          {/* Feature 2 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-pink-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-pink-500 to-purple-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">🔐</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Secure Key Management</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Your API keys stay safe with encrypted local storage
            </p>
          </div>

          {/* Feature 3 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-blue-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">🔄</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Cross-Platform Sync</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Start on your phone, continue on desktop with full sync
            </p>
          </div>

          {/* Feature 4 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-green-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-green-500 to-emerald-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">🏠</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Local Model Support</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Run models locally with Ollama integration for privacy
            </p>
          </div>

          {/* Feature 5 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-yellow-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">🔍</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Smart Search</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Find anything in your conversations with AI-powered search
            </p>
          </div>

          {/* Feature 6 */}
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10 hover:border-red-500/50 transition-all duration-300 group">
            <div className="w-14 h-14 bg-linear-to-br from-red-500 to-pink-500 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <span className="text-2xl">⚙️</span>
            </div>
            <h3 className="text-2xl font-bold font-kollektif text-white mb-4">Advanced Controls</h3>
            <p className="text-gray-400 font-kollektif leading-relaxed">
              Fine-tune temperature, tokens, and system prompts for perfect results
            </p>
          </div>
        </div>
      </div>
    </section>

    {/* Use Cases Section */}
    <section id="use-cases" className="relative bg-black py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white text-center mb-20">
          How People Use PocketLLM
        </h2>

        <div className="grid md:grid-cols-2 gap-8">
          {/* Use Case 1 */}
          <div className="relative bg-linear-to-br from-purple-500/10 via-transparent to-transparent p-10 rounded-3xl border border-purple-500/20 hover:border-purple-500/50 transition-all duration-300 group overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/10 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-500"></div>
            <div className="relative z-10">
              <div className="text-5xl mb-6">👨‍💻</div>
              <h3 className="text-3xl font-bold font-kollektif text-white mb-4">Developers</h3>
              <p className="text-gray-300 font-kollektif text-lg leading-relaxed">
                Code review, debugging, and technical documentation. Get instant help with complex algorithms and architecture decisions.
              </p>
            </div>
          </div>

          {/* Use Case 2 */}
          <div className="relative bg-linear-to-br from-pink-500/10 via-transparent to-transparent p-10 rounded-3xl border border-pink-500/20 hover:border-pink-500/50 transition-all duration-300 group overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-pink-500/10 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-500"></div>
            <div className="relative z-10">
              <div className="text-5xl mb-6">✍️</div>
              <h3 className="text-3xl font-bold font-kollektif text-white mb-4">Writers</h3>
              <p className="text-gray-300 font-kollektif text-lg leading-relaxed">
                Creative writing, editing, and content generation. Overcome writer&apos;s block and refine your prose with AI assistance.
              </p>
            </div>
          </div>

          {/* Use Case 3 */}
          <div className="relative bg-linear-to-br from-blue-500/10 via-transparent to-transparent p-10 rounded-3xl border border-blue-500/20 hover:border-blue-500/50 transition-all duration-300 group overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-500"></div>
            <div className="relative z-10">
              <div className="text-5xl mb-6">🎓</div>
              <h3 className="text-3xl font-bold font-kollektif text-white mb-4">Students</h3>
              <p className="text-gray-300 font-kollektif text-lg leading-relaxed">
                Research assistance and learning support. Get explanations, study guides, and help understanding complex topics.
              </p>
            </div>
          </div>

          {/* Use Case 4 */}
          <div className="relative bg-linear-to-br from-green-500/10 via-transparent to-transparent p-10 rounded-3xl border border-green-500/20 hover:border-green-500/50 transition-all duration-300 group overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-green-500/10 rounded-full blur-3xl group-hover:scale-150 transition-transform duration-500"></div>
            <div className="relative z-10">
              <div className="text-5xl mb-6">💼</div>
              <h3 className="text-3xl font-bold font-kollektif text-white mb-4">Professionals</h3>
              <p className="text-gray-300 font-kollektif text-lg leading-relaxed">
                Meeting summaries and business communication. Draft emails, create presentations, and analyze data efficiently.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    {/* Trust Signals Section */}
    <section id="trust" className="relative bg-linear-to-b from-black via-purple-900/10 to-black py-32 px-6">
      <div className="max-w-5xl mx-auto text-center">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white mb-8">
          Trusted by Thousands Worldwide
        </h2>
        <p className="text-xl md:text-2xl text-gray-300 font-kollektif leading-relaxed mb-16">
          Join 10,000+ users who&apos;ve consolidated their AI workflow into one powerful application. Built with privacy-first principles and enterprise-grade security.
        </p>

        <div className="grid md:grid-cols-3 gap-8 mb-16">
          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10">
            <div className="text-5xl font-bold font-silver-garden text-transparent bg-linear-to-r from-purple-400 to-pink-400 bg-clip-text mb-2">
              10,000+
            </div>
            <p className="text-gray-400 font-kollektif">Active Users</p>
          </div>

          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10">
            <div className="text-5xl font-bold font-silver-garden text-transparent bg-linear-to-r from-pink-400 to-blue-400 bg-clip-text mb-2">
              99.9%
            </div>
            <p className="text-gray-400 font-kollektif">Uptime</p>
          </div>

          <div className="bg-white/5 backdrop-blur-sm p-8 rounded-2xl border border-white/10">
            <div className="text-5xl font-bold font-silver-garden text-transparent bg-linear-to-r from-blue-400 to-green-400 bg-clip-text mb-2">
              4.9/5
            </div>
            <p className="text-gray-400 font-kollektif">User Rating</p>
          </div>
        </div>
      </div>
    </section>

    {/* Technical Features Section */}
    <section id="technical" className="relative bg-black py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white text-center mb-8">
          Under the Hood
        </h2>
        <p className="text-xl text-gray-400 font-kollektif text-center mb-20 max-w-3xl mx-auto">
          Built with cutting-edge technology for maximum performance and reliability
        </p>

        <div className="grid md:grid-cols-2 gap-8">
          <div className="bg-linear-to-br from-purple-500/5 to-transparent p-8 rounded-2xl border border-purple-500/20">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">📱</span>
              </div>
              <div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Built with Flutter</h3>
                <p className="text-gray-400 font-kollektif leading-relaxed">
                  Native performance on all platforms with a single codebase. Smooth 60fps animations and instant response times.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-linear-to-br from-pink-500/5 to-transparent p-8 rounded-2xl border border-pink-500/20">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-pink-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">⚡</span>
              </div>
              <div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">FastAPI Backend</h3>
                <p className="text-gray-400 font-kollektif leading-relaxed">
                  Lightning-fast response times with modern Python async architecture. Handle thousands of requests per second.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-linear-to-br from-blue-500/5 to-transparent p-8 rounded-2xl border border-blue-500/20">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">☁️</span>
              </div>
              <div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">Supabase Integration</h3>
                <p className="text-gray-400 font-kollektif leading-relaxed">
                  Reliable cloud storage and sync powered by PostgreSQL. Your data is always available, everywhere.
                </p>
              </div>
            </div>
          </div>

          <div className="bg-linear-to-br from-green-500/5 to-transparent p-8 rounded-2xl border border-green-500/20">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">🔒</span>
              </div>
              <div>
                <h3 className="text-2xl font-bold font-kollektif text-white mb-3">End-to-End Encryption</h3>
                <p className="text-gray-400 font-kollektif leading-relaxed">
                  Your data, your privacy. Military-grade encryption ensures your conversations stay completely private.
                </p>
              </div>
            </div>
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
    <section id="about" className="relative bg-black py-32 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="grid md:grid-cols-2 gap-16 items-center mb-20">
          <div>
            <h2 className="text-5xl md:text-6xl font-bold font-silver-garden text-white mb-6">
              Why We Built PocketLLM
            </h2>
            <p className="text-xl text-gray-300 font-kollektif leading-relaxed mb-6">
              We were tired of switching between different AI apps and losing context. PocketLLM was born from the need for a single, elegant solution that brings all AI models together in one place.
            </p>
            <p className="text-lg text-gray-400 font-kollektif leading-relaxed">
              Our team of developers and designers spent months crafting the perfect AI companion—one that&apos;s powerful enough for professionals yet simple enough for everyone.
            </p>
          </div>
          <div className="relative">
            <div className="absolute inset-0 bg-linear-to-br from-purple-500/20 to-pink-500/20 rounded-3xl blur-3xl"></div>
            <div className="relative bg-white/5 backdrop-blur-sm p-12 rounded-3xl border border-white/10">
              <div className="text-6xl mb-6 text-center">🚀</div>
              <h3 className="text-3xl font-bold font-kollektif text-white text-center mb-4">Our Mission</h3>
              <p className="text-gray-300 font-kollektif text-center leading-relaxed">
                Democratizing AI access for everyone, regardless of technical expertise. We believe the future of human-AI collaboration should be seamless and intuitive.
              </p>
            </div>
          </div>
        </div>

        {/* Team Values */}
        <div className="grid md:grid-cols-3 gap-8">
          <div className="text-center">
            <div className="w-16 h-16 bg-linear-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <span className="text-3xl">💡</span>
            </div>
            <h3 className="text-xl font-bold font-kollektif text-white mb-3">Innovation First</h3>
            <p className="text-gray-400 font-kollektif">
              Constantly pushing boundaries to deliver cutting-edge AI experiences
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-linear-to-br from-pink-500 to-blue-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <span className="text-3xl">🔒</span>
            </div>
            <h3 className="text-xl font-bold font-kollektif text-white mb-3">Privacy Focused</h3>
            <p className="text-gray-400 font-kollektif">
              Your data belongs to you. We never compromise on security or privacy
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-linear-to-br from-blue-500 to-green-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <span className="text-3xl">❤️</span>
            </div>
            <h3 className="text-xl font-bold font-kollektif text-white mb-3">User Centric</h3>
            <p className="text-gray-400 font-kollektif">
              Every feature is designed with real user needs and feedback in mind
            </p>
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
