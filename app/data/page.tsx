"use client";

import Navbar from "@/components/navbar";
import Footer from "@/components/footer";
import { HardDrive, WifiOff, ShieldOff, Download, Upload, Ban, Lock } from "lucide-react";
import { motion } from "framer-motion";

export default function DataPrivacy() {
  const features = [
    {
      title: "Stored locally",
      description: "Everything stays on your device.",
      icon: <HardDrive className="w-5 h-5" />
    },
    {
      title: "Works offline",
      description: "Use Kaizen anywhere without an internet connection.",
      icon: <WifiOff className="w-5 h-5" />
    },
    {
      title: "No tracking",
      description: "Your activity is not monitored or sold.",
      icon: <ShieldOff className="w-5 h-5" />
    },
    {
      title: "Export anytime",
      description: "Create backups whenever you want.",
      icon: <Download className="w-5 h-5" />
    },
    {
      title: "Import anytime",
      description: "Move your data between devices easily.",
      icon: <Upload className="w-5 h-5" />
    },
    {
      title: "No ads",
      description: "No interruptions. No distractions.",
      icon: <Ban className="w-5 h-5" />
    },
    {
      title: "You stay in control",
      description: "Your data belongs to you.",
      icon: <Lock className="w-5 h-5" />
    }
  ];

  return (
    <main className="bg-[#050505] text-white min-h-screen relative">
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      <div className="fixed inset-0 pointer-events-none z-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_-20%,rgba(108,99,255,0.12),transparent)] mix-blend-screen"></div>

      <div className="relative z-10 flex flex-col min-h-screen">
        <Navbar />
        
        <div className="flex-grow pt-32 pb-24 px-6 max-w-[900px] mx-auto w-full">
          <div className="text-center mb-20">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">Your data. Yours, always.</h1>
            <p className="text-xl text-zinc-400">Kaizen is designed around privacy, ownership, and control.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-24">
            {features.map((item, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.1 }}
                className="p-6 rounded-2xl bg-white/5 border border-white/10 hover:border-kaizen-purple/50 transition-colors group relative overflow-hidden backdrop-blur-sm"
              >
                <div className="absolute inset-0 bg-gradient-to-br from-kaizen-purple/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <div className="w-10 h-10 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center text-kaizen-purple-light mb-4 relative z-10">
                  {item.icon}
                </div>
                <h3 className="text-lg font-semibold text-white mb-2 relative z-10 flex items-center gap-2">
                  <span className="text-green-400">✓</span> {item.title}
                </h3>
                <p className="text-zinc-400 relative z-10">{item.description}</p>
              </motion.div>
            ))}
          </div>

          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 }}
            className="p-12 rounded-[2rem] bg-gradient-to-br from-kaizen-surface to-kaizen-purple/10 border border-kaizen-purple/30 text-center shadow-[0_0_50px_rgba(99,102,241,0.15)] relative overflow-hidden"
          >
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(108,99,255,0.15),transparent)] pointer-events-none"></div>
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-6 text-white relative z-10">
              Private. Offline. Yours.
            </h2>
            <p className="text-lg md:text-xl text-zinc-400 max-w-2xl mx-auto leading-relaxed relative z-10">
              Being human is all about balance. Your tools should help you stay focused, organized, and healthy without sacrificing your privacy.
            </p>
          </motion.div>
        </div>

        <Footer />
      </div>
    </main>
  );
}
