"use client";

import Navbar from "@/components/navbar";
import Footer from "@/components/footer";
import { Mail, MessageSquare, Lightbulb, Bug } from "lucide-react";
import { motion } from "framer-motion";

export default function FeedbackPage() {
  return (
    <main className="bg-[#050505] text-white min-h-screen relative">
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      <div className="fixed inset-0 pointer-events-none z-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_-20%,rgba(108,99,255,0.12),transparent)] mix-blend-screen"></div>

      <div className="relative z-10 flex flex-col min-h-screen">
        <Navbar />
        
        <div className="flex-grow pt-32 pb-24 px-6 max-w-[800px] mx-auto w-full flex flex-col items-center justify-center">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-16"
          >
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-kaizen-purple/10 border border-kaizen-purple/20 text-kaizen-purple-light mb-8">
              <MessageSquare className="w-8 h-8" />
            </div>
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">Help shape Kaizen.</h1>
            <p className="text-xl text-zinc-400 max-w-2xl mx-auto">
              Kaizen is built for you. Your feedback directly influences what we build next.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-16 w-full">
            <motion.div 
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="p-8 rounded-2xl bg-white/5 border border-white/10 flex flex-col items-center text-center backdrop-blur-sm"
            >
              <Lightbulb className="w-6 h-6 text-yellow-400 mb-4" />
              <h3 className="text-lg font-semibold text-white mb-2">Feature Ideas</h3>
              <p className="text-sm text-zinc-400">Have an idea that would make Kaizen better? Let us know.</p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className="p-8 rounded-2xl bg-white/5 border border-white/10 flex flex-col items-center text-center backdrop-blur-sm"
            >
              <Bug className="w-6 h-6 text-red-400 mb-4" />
              <h3 className="text-lg font-semibold text-white mb-2">Bug Reports</h3>
              <p className="text-sm text-zinc-400">Found something broken? Tell us so we can fix it quickly.</p>
            </motion.div>
          </div>

          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="w-full p-12 rounded-[2rem] bg-gradient-to-br from-kaizen-surface to-kaizen-purple/10 border border-kaizen-purple/30 text-center shadow-[0_0_50px_rgba(99,102,241,0.15)] relative overflow-hidden"
          >
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(108,99,255,0.15),transparent)] pointer-events-none"></div>
            <h2 className="text-2xl md:text-3xl font-bold tracking-tight mb-6 text-white relative z-10">
              We're always listening.
            </h2>
            <p className="text-zinc-400 mb-8 relative z-10">
              Send us an email with your thoughts, suggestions, or just to say hi!
            </p>
            
            <a
              href="mailto:kaizenappsupport@gmail.com"
              className="inline-flex items-center gap-3 px-8 py-4 rounded-xl bg-kaizen-purple text-white font-semibold text-sm hover:bg-kaizen-purple-light transition-colors shadow-[0_0_20px_rgba(99,102,241,0.3)] relative z-10"
            >
              <Mail className="w-5 h-5" />
              Email Support
            </a>
          </motion.div>
        </div>

        <Footer />
      </div>
    </main>
  );
}
