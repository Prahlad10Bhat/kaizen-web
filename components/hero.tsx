"use client";

import { motion } from "framer-motion";
import { Download, Play, Shield, WifiOff, Globe as GitHubIcon, Sparkles } from "lucide-react";
import Image from "next/image";
import { useLatestRelease } from "@/hooks/use-latest-release";

export default function Hero() {
  const { downloadUrl } = useLatestRelease();
  return (
    <section className="relative min-h-[90vh] pt-32 pb-20 overflow-hidden flex items-center">
      {/* Background glow */}
      <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-kaizen-purple/10 blur-[120px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-6 w-full grid grid-cols-1 lg:grid-cols-2 gap-12 items-center relative z-10">
        
        {/* Left Column */}
        <motion.div 
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="flex flex-col items-start text-left"
        >
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-zinc-400 text-xs font-medium mb-8">
            <Sparkles className="w-3 h-3 text-kaizen-purple-light" />
            Your all-in-one productivity system
          </div>

          <h1 className="text-5xl md:text-6xl lg:text-[72px] font-bold tracking-tighter-plus leading-[1.05] mb-6">
            <span className="text-white block">Build better systems.</span>
            <span className="text-gradient-warm block mt-1">Make real progress.</span>
          </h1>

          <p className="text-lg text-zinc-400 max-w-lg mb-10 tracking-tight leading-relaxed">
            Tasks, notes, habits, calendar, goals and more. <br className="hidden md:block"/>
            Kaizen brings everything together so you can <br className="hidden md:block"/>
            focus on what truly matters.
          </p>

          <div className="flex flex-col sm:flex-row items-center gap-4 mb-16 w-full sm:w-auto">
            <a
              href={downloadUrl}
              className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-kaizen-purple text-white font-semibold text-sm hover:bg-kaizen-purple-light transition-colors flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(99,102,241,0.3)]"
            >
              <Download className="w-4 h-4" />
              Download for Windows
            </a>
            <button className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-transparent text-white font-semibold text-sm border border-white/20 hover:bg-white/5 transition-colors flex items-center justify-center gap-2">
              <Play className="w-4 h-4" />
              Watch Demo
            </button>
          </div>

          {/* Trust Indicators */}
          <div className="flex flex-wrap items-center gap-6 text-xs text-zinc-500 font-medium">
            <div className="flex items-center gap-2">
              <GitHubIcon className="w-4 h-4" />
              Free & Open Source
            </div>
            <div className="w-1 h-1 rounded-full bg-zinc-700"></div>
            <div className="flex items-center gap-2">
              <WifiOff className="w-4 h-4" />
              Works Offline
            </div>
            <div className="w-1 h-1 rounded-full bg-zinc-700"></div>
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4" />
              Privacy Focused
            </div>
          </div>
        </motion.div>

        {/* Right Column: 3D Image Collage */}
        <div className="relative h-[400px] md:h-[600px] lg:h-[700px] w-full perspective-1000 hidden lg:block">
          
          {/* Back image (Tasks/Calendar) */}
          <motion.div
            initial={{ opacity: 0, x: 100, y: -50, rotateY: -15, scale: 0.8 }}
            animate={{ opacity: 0.5, x: 200, y: -60, rotateY: -10, scale: 0.85 }}
            transition={{ duration: 1, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
            className="absolute top-10 right-[-100px] w-[500px] rounded-xl border border-white/10 bg-black/40 shadow-2xl overflow-hidden ring-1 ring-white/5 z-10"
          >
            <Image src="/images/tasks.jpeg" alt="Tasks" width={800} height={500} className="w-full object-cover opacity-80" />
          </motion.div>

          {/* Middle image (Notes) */}
          <motion.div
            initial={{ opacity: 0, x: 100, y: 0, rotateY: -10, scale: 0.9 }}
            animate={{ opacity: 0.8, x: 100, y: 20, rotateY: -5, scale: 0.95 }}
            transition={{ duration: 1, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
            className="absolute top-32 right-[-20px] w-[600px] rounded-xl border border-white/10 bg-black/60 shadow-[0_20px_50px_rgba(0,0,0,0.5)] overflow-hidden ring-1 ring-white/10 z-20"
          >
            <Image src="/images/notes.jpeg" alt="Notes" width={800} height={500} className="w-full object-cover" />
          </motion.div>

          {/* Front image (Dashboard) */}
          <motion.div
            initial={{ opacity: 0, x: 50, y: 50, rotateY: -5, scale: 0.95 }}
            animate={{ opacity: 1, x: -40, y: 120, rotateY: 0, scale: 1.05 }}
            transition={{ duration: 1, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="absolute top-10 left-0 w-[700px] rounded-2xl border border-white/10 bg-kaizen-surface/90 backdrop-blur-md shadow-[0_40px_100px_-20px_rgba(0,0,0,0.7)] overflow-hidden ring-1 ring-white/20 z-30"
          >
            <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/30 to-transparent"></div>
            <Image src="/images/dashboard.jpeg" alt="Dashboard" width={1000} height={600} className="w-full object-cover" priority />
          </motion.div>
        </div>

      </div>
    </section>
  );
}