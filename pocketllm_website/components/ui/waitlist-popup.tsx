"use client"
import { useState, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { X, Rocket, User, Mail } from "lucide-react"

export default function WaitlistPopup() {
  const [isOpen, setIsOpen] = useState(false)
  const [formData, setFormData] = useState({ name: "", email: "" })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSuccess, setIsSuccess] = useState(false)

  useEffect(() => {
    // Show popup when user scrolls near bottom
    const handleScroll = () => {
      const scrollPosition = window.scrollY + window.innerHeight
      const documentHeight = document.documentElement.scrollHeight
      const hasSeenWaitlist = localStorage.getItem("waitlist-popup-seen")

      // Show when user is 80% down the page
      if (scrollPosition > documentHeight * 0.8 && !hasSeenWaitlist && !isOpen) {
        setIsOpen(true)
      }
    }

    window.addEventListener("scroll", handleScroll)
    return () => window.removeEventListener("scroll", handleScroll)
  }, [isOpen])

  const handleClose = () => {
    setIsOpen(false)
    localStorage.setItem("waitlist-popup-seen", "true")
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1500))

    setIsSuccess(true)
    setIsSubmitting(false)

    // Close after success
    setTimeout(() => {
      handleClose()
    }, 2500)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
          />

          {/* Popup */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="fixed bottom-8 right-8 w-[90%] max-w-md z-50 hidden md:block"
          >
            <div className="relative bg-gradient-to-br from-gray-900 via-black to-gray-900 border border-white/10 rounded-2xl p-6 md:p-8 shadow-2xl overflow-hidden">
              {/* Animated Background */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/20 rounded-full blur-3xl animate-pulse" />
              <div className="absolute bottom-0 left-0 w-32 h-32 bg-purple-500/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />

              {/* Close Button */}
              <button
                onClick={handleClose}
                className="absolute top-4 right-4 p-2 hover:bg-white/10 rounded-full transition-colors z-10"
                aria-label="Close"
              >
                <X className="w-5 h-5 text-gray-400 hover:text-white" />
              </button>

              <div className="relative z-10">
                {!isSuccess ? (
                  <>
                    {/* Icon */}
                    <div className="flex justify-center mb-4">
                      <div className="p-3 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-full">
                        <Rocket className="w-8 h-8 text-blue-400" />
                      </div>
                    </div>

                    {/* Title */}
                    <h2 className="text-2xl md:text-3xl font-silver-garden text-center bg-gradient-to-r from-white via-gray-200 to-white/80 bg-clip-text text-transparent mb-2">
                      Join the Waitlist
                    </h2>

                    {/* Description */}
                    <p className="text-gray-400 text-center text-sm md:text-base font-kollektif mb-6">
                      Be among the first to experience PocketLLM. Get early access and exclusive updates!
                    </p>

                    {/* Form */}
                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div className="relative">
                        <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                        <input
                          type="text"
                          name="name"
                          value={formData.name}
                          onChange={handleChange}
                          placeholder="Your name"
                          required
                          className="w-full pl-11 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all font-kollektif"
                        />
                      </div>

                      <div className="relative">
                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                        <input
                          type="email"
                          name="email"
                          value={formData.email}
                          onChange={handleChange}
                          placeholder="Your email"
                          required
                          className="w-full pl-11 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all font-kollektif"
                        />
                      </div>

                      <button
                        type="submit"
                        disabled={isSubmitting}
                        className="w-full py-3 bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600 text-white font-semibold rounded-lg transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed font-kollektif"
                      >
                        {isSubmitting ? (
                          <span className="flex items-center justify-center gap-2">
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            Joining...
                          </span>
                        ) : (
                          "Join Waitlist"
                        )}
                      </button>
                    </form>

                    {/* Note */}
                    <p className="text-xs text-gray-500 text-center mt-4 font-kollektif">
                      🎉 Limited spots available. Join now!
                    </p>
                  </>
                ) : (
                  <div className="text-center py-8">
                    <div className="flex justify-center mb-4">
                      <div className="p-3 bg-green-500/20 rounded-full">
                        <motion.div
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: "spring", damping: 15 }}
                        >
                          <svg className="w-8 h-8 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                        </motion.div>
                      </div>
                    </div>
                    <h3 className="text-2xl font-silver-garden text-white mb-2">Welcome Aboard!</h3>
                    <p className="text-gray-400 font-kollektif">You're on the waitlist. We'll be in touch soon!</p>
                  </div>
                )}
              </div>
            </div>
          </motion.div>

          {/* Mobile Version - Center */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90%] max-w-md z-50 md:hidden"
          >
            <div className="relative bg-gradient-to-br from-gray-900 via-black to-gray-900 border border-white/10 rounded-2xl p-6 shadow-2xl overflow-hidden">
              {/* Animated Background */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/20 rounded-full blur-3xl animate-pulse" />
              <div className="absolute bottom-0 left-0 w-32 h-32 bg-purple-500/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />

              {/* Close Button */}
              <button
                onClick={handleClose}
                className="absolute top-4 right-4 p-2 hover:bg-white/10 rounded-full transition-colors z-10"
                aria-label="Close"
              >
                <X className="w-5 h-5 text-gray-400 hover:text-white" />
              </button>

              <div className="relative z-10">
                {!isSuccess ? (
                  <>
                    <div className="flex justify-center mb-4">
                      <div className="p-3 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-full">
                        <Rocket className="w-8 h-8 text-blue-400" />
                      </div>
                    </div>

                    <h2 className="text-2xl font-silver-garden text-center bg-gradient-to-r from-white via-gray-200 to-white/80 bg-clip-text text-transparent mb-2">
                      Join the Waitlist
                    </h2>

                    <p className="text-gray-400 text-center text-sm font-kollektif mb-6">
                      Be among the first to experience PocketLLM!
                    </p>

                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div className="relative">
                        <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                        <input
                          type="text"
                          name="name"
                          value={formData.name}
                          onChange={handleChange}
                          placeholder="Your name"
                          required
                          className="w-full pl-11 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all font-kollektif"
                        />
                      </div>

                      <div className="relative">
                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                        <input
                          type="email"
                          name="email"
                          value={formData.email}
                          onChange={handleChange}
                          placeholder="Your email"
                          required
                          className="w-full pl-11 pr-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all font-kollektif"
                        />
                      </div>

                      <button
                        type="submit"
                        disabled={isSubmitting}
                        className="w-full py-3 bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600 text-white font-semibold rounded-lg transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed font-kollektif"
                      >
                        {isSubmitting ? (
                          <span className="flex items-center justify-center gap-2">
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            Joining...
                          </span>
                        ) : (
                          "Join Waitlist"
                        )}
                      </button>
                    </form>
                  </>
                ) : (
                  <div className="text-center py-8">
                    <div className="flex justify-center mb-4">
                      <div className="p-3 bg-green-500/20 rounded-full">
                        <motion.div
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: "spring", damping: 15 }}
                        >
                          <svg className="w-8 h-8 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                        </motion.div>
                      </div>
                    </div>
                    <h3 className="text-2xl font-silver-garden text-white mb-2">Welcome Aboard!</h3>
                    <p className="text-gray-400 font-kollektif text-sm">You're on the waitlist!</p>
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

