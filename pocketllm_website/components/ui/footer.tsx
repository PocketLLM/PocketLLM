"use client"
import { motion } from "framer-motion"

// Footer data for PocketLLM
const footerData = {
  sections: [
    { title: "Product", links: ["Features", "Pricing", "Download", "Roadmap"] },
    { title: "Resources", links: ["Documentation", "API Reference", "Community Forum", "Support"] },
    { title: "Company", links: ["About", "Blog", "Careers", "Contact"] },
    { title: "Legal", links: ["Privacy Policy", "Terms of Service", "Security", "Refund Policy"] },
  ],
  social: [
    { href: "https://twitter.com/PocketLLM", label: "Twitter", icon: "x" },
    { href: "https://github.com/PocketLLM/PocketLLM", label: "GitHub", icon: "Git" },
    { href: "https://linkedin.com/company/syntaxandsips", label: "LinkedIn", icon: "in" },
  ],
  title: "PocketLLM",
  subtitle: "Your Pocket AI",
  copyright: "© 2025 PocketLLM. All rights reserved",
}

// Reusable components
const NavSection = ({ title, links, index }: { title: string; links: string[]; index: number }) => (
  <motion.div
    initial={{ opacity: 0, x: -20 }}
    animate={{ opacity: 1, x: 0 }}
    transition={{ duration: 0.6, delay: index * 0.1 }}
    className="flex flex-col gap-2"
  >
    <motion.h3
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.3 + index * 0.1, duration: 0.5 }}
      className="mb-2 uppercase text-gray-400 text-xs font-semibold tracking-wider border-b border-white/10 pb-1 hover:text-white transition-colors duration-300"
    >
      {title}
    </motion.h3>
    {links.map((link, linkIndex) => (
      <motion.a
        key={linkIndex}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: (index * 0.1) + (linkIndex * 0.05) }}
        href="#"
        whileHover={{
          x: 8,
          transition: { type: "spring", stiffness: 300, damping: 20 },
        }}
        className="text-gray-400 hover:text-white transition-colors duration-300 font-kollektif text-xs md:text-sm group relative"
      >
        <span className="relative">
          {link}
          <motion.span
            className="absolute bottom-0 left-0 h-0.5 bg-purple-500"
            initial={{ width: 0 }}
            whileHover={{ width: "100%" }}
            transition={{ duration: 0.3 }}
          />
        </span>
      </motion.a>
    ))}
  </motion.div>
)

const SocialLink = ({ href, label, icon, index }: { href: string; label: string; icon: string; index: number }) => (
  <motion.a
    initial={{ opacity: 0, scale: 0 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ type: "spring", stiffness: 200, damping: 10, delay: 2 + (index * 0.1) }}
    href={href}
    target="_blank"
    rel="noopener noreferrer"
    whileHover={{
      scale: 1.2,
      rotate: 12,
      transition: { type: "spring", stiffness: 300, damping: 15 },
    }}
    whileTap={{ scale: 0.9 }}
    className="w-8 h-8 md:w-10 md:h-10 rounded-full bg-white/10 hover:bg-linear-to-r hover:from-purple-500 hover:to-pink-500 flex items-center justify-center transition-colors duration-300 group backdrop-blur-sm border border-white/10"
    aria-label={label}
  >
    <motion.span
      className="text-sm md:text-base font-bold text-gray-400 group-hover:text-white"
      whileHover={{ scale: 1.1 }}
    >
      {icon}
    </motion.span>
  </motion.a>
)

export default function StickyFooter() {
  return (
    <footer className="relative w-full bg-gradient-to-br from-black via-gray-900 to-black py-12 md:py-16 lg:py-20 px-4 md:px-8 lg:px-12 overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent pointer-events-none" />

      <div className="absolute top-0 right-0 w-48 h-48 md:w-96 md:h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse" />
      <div className="absolute bottom-0 left-0 w-48 h-48 md:w-96 md:h-96 bg-pink-500/10 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />

      <div className="max-w-7xl mx-auto relative z-10">
        {/* Navigation Section */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-12 mb-12 md:mb-16">
          {footerData.sections.map((section, index) => (
            <NavSection key={section.title} title={section.title} links={section.links} index={index} />
          ))}
        </div>

        {/* Divider */}
        <div className="w-full h-px bg-gradient-to-r from-transparent via-white/10 to-transparent mb-8 md:mb-12" />

        {/* Footer Bottom Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-8">
          <div className="flex-1">
            <h1 className="text-4xl md:text-5xl lg:text-6xl xl:text-7xl leading-tight font-silver-garden bg-gradient-to-r from-white via-gray-300 to-white/60 bg-clip-text text-transparent">
              {footerData.title}
            </h1>

            <div className="flex items-center gap-4 mt-4">
              <div className="w-12 h-0.5 bg-gradient-to-r from-purple-500 to-pink-500" />
              <p className="text-gray-400 text-sm md:text-base font-kollektif hover:text-white transition-colors duration-300">
                {footerData.subtitle}
              </p>
            </div>
          </div>

          <div className="text-left md:text-right">
            <p className="text-gray-400 text-sm mb-4 hover:text-white transition-colors duration-300 font-kollektif">
              {footerData.copyright}
            </p>

            <div className="flex gap-3">
              {footerData.social.map((social, index) => (
                <SocialLink
                  key={social.label}
                  href={social.href}
                  label={social.label}
                  icon={social.icon}
                  index={index}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}