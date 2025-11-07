"use client"
import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Star, Github } from "lucide-react"

interface GitHubStarButtonProps {
  repo: string // Format: "owner/repo"
  className?: string
}

export default function GitHubStarButton({ repo, className = "" }: GitHubStarButtonProps) {
  const [stars, setStars] = useState<number | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchStars = async () => {
      try {
        const response = await fetch(`https://api.github.com/repos/${repo}`)
        const data = await response.json()
        setStars(data.stargazers_count)
      } catch (error) {
        console.error("Failed to fetch GitHub stars:", error)
        setStars(null)
      } finally {
        setIsLoading(false)
      }
    }

    fetchStars()
  }, [repo])

  const formatStars = (count: number) => {
    if (count >= 1000) {
      return `${(count / 1000).toFixed(1)}k`
    }
    return count.toString()
  }

  return (
    <motion.a
      href={`https://github.com/${repo}`}
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 backdrop-blur-sm border border-white/10 rounded-full transition-all duration-300 group ${className}`}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
    >
      <Github className="w-4 h-4 text-gray-400 group-hover:text-white transition-colors" />
      
      <span className="text-sm font-kollektif text-gray-300 group-hover:text-white transition-colors">
        Star
      </span>

      {isLoading ? (
        <div className="flex items-center gap-1 px-2 py-0.5 bg-white/5 rounded-full">
          <div className="w-1 h-1 bg-purple-500 rounded-full animate-pulse" />
          <div className="w-1 h-1 bg-pink-500 rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
          <div className="w-1 h-1 bg-blue-500 rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
        </div>
      ) : stars !== null ? (
        <div className="flex items-center gap-1 px-2 py-0.5 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-full">
          <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />
          <span className="text-xs font-bold text-white">{formatStars(stars)}</span>
        </div>
      ) : null}
    </motion.a>
  )
}

