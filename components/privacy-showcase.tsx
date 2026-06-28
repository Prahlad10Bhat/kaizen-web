"use client";

import { motion } from "framer-motion";
import { Sparkles, Lock, WifiOff, Shield, Database, CloudOff, EyeOff, Download, Check, Feather } from "lucide-react";

export default function PrivacyShowcase() {
  return (
    <section id="privacy" className="py-32 relative overflow-hidden bg-black">
      <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-kaizen-purple/30 to-transparent"></div>
      
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-kaizen-purple/10 blur-[150px] rounded-full pointer-events-none" />
      
      <div className="max-w-7xl mx-auto px-6 relative z-10 flex flex-col lg:flex-row items-center gap-16">
        <div className="w-full lg:w-1/2">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-kaizen-purple/10 border border-kaizen-purple/20 text-kaizen-purple-light text-sm font-medium mb-6"
          >
            <Sparkles className="w-4 h-4" />
            Built for Focus. Designed for Life.
          </motion.div>
          
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6 text-white leading-tight"
          >
            Your data. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-kaizen-purple-light to-kaizen-purple">
              Yours, always.
            </span>
          </motion.h2>
          
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-zinc-400 mb-10 leading-relaxed max-w-lg"
          >
            Kaizen is built with privacy at its core. Your data is stored locally on your device, works offline, and never leaves your control.
          </motion.p>
          
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.3 }}
            className="flex flex-row sm:flex-col gap-4 sm:gap-8 overflow-x-auto sm:overflow-visible snap-x snap-mandatory pb-4 sm:pb-0 -mx-6 px-6 sm:mx-0 sm:px-0 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none] mb-10"
          >
            <div className="flex gap-4 w-[85vw] sm:w-auto flex-shrink-0 snap-center sm:snap-align-none p-5 sm:p-0 rounded-2xl sm:rounded-none bg-[#0f0f13]/80 sm:bg-transparent border border-white/5 sm:border-transparent">
              <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                <Lock className="w-5 h-5 text-kaizen-purple-light" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white mb-1">100% Local & Private</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">All your data stays on your device. No servers, no cloud, no tracking.</p>
              </div>
            </div>

            <div className="flex gap-4 w-[85vw] sm:w-auto flex-shrink-0 snap-center sm:snap-align-none p-5 sm:p-0 rounded-2xl sm:rounded-none bg-[#0f0f13]/80 sm:bg-transparent border border-white/5 sm:border-transparent">
              <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                <WifiOff className="w-5 h-5 text-kaizen-purple-light" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white mb-1">Works Offline</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">Access your notes, tasks, calendar, and more—anytime, anywhere. No internet required.</p>
              </div>
            </div>

            <div className="flex gap-4 w-[85vw] sm:w-auto flex-shrink-0 snap-center sm:snap-align-none p-5 sm:p-0 rounded-2xl sm:rounded-none bg-[#0f0f13]/80 sm:bg-transparent border border-white/5 sm:border-transparent">
              <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                <Shield className="w-5 h-5 text-kaizen-purple-light" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white mb-1">You're in Control</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">Export, backup, and manage your data whenever you want. You own it, always.</p>
              </div>
            </div>

            <div className="flex gap-4 w-[85vw] sm:w-auto flex-shrink-0 snap-center sm:snap-align-none p-5 sm:p-0 rounded-2xl sm:rounded-none bg-[#0f0f13]/80 sm:bg-transparent border border-white/5 sm:border-transparent">
              <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                <Feather className="w-5 h-5 text-kaizen-purple-light" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white mb-1">Minimal Footprint</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">Highly optimized to consume less storage space, keeping your device running smoothly without bloat.</p>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.4 }}
            className="flex items-center gap-2 text-sm text-zinc-500 font-medium"
          >
            <Lock className="w-4 h-4" />
            No accounts. No data collection. Just you and your work.
          </motion.div>
        </div>
        
        <div className="w-full lg:w-1/2">
          <motion.div
            initial={{ opacity: 0, scale: 0.9, rotateY: -10 }}
            whileInView={{ opacity: 1, scale: 1, rotateY: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
            className="relative perspective-1000"
          >
            <div className="relative rounded-[2rem] border border-white/10 bg-kaizen-surface/40 backdrop-blur-3xl shadow-[0_0_80px_rgba(108,99,255,0.15)] overflow-hidden ring-1 ring-white/10 p-8 flex flex-col gap-8">
              
              <div className="flex flex-col items-center text-center mt-4">
                <div className="w-20 h-20 rounded-full bg-kaizen-purple/10 flex items-center justify-center border border-kaizen-purple/20 mb-6 shadow-[0_0_40px_rgba(99,102,241,0.3)]">
                  <Shield className="w-10 h-10 text-kaizen-purple-light" />
                </div>
                <h3 className="text-2xl font-bold text-white mb-2">Private by design</h3>
                <p className="text-sm text-zinc-400 max-w-xs mx-auto">
                  Everything you do in Kaizen is saved locally and stays on your device.
                </p>
              </div>

              <div className="flex flex-row sm:flex-col gap-3 bg-black/40 rounded-2xl p-4 border border-white/5 overflow-x-auto sm:overflow-visible snap-x snap-mandatory [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
                {[
                  { icon: Database, title: "Data stored locally", desc: "On your device only", status: "Local" },
                  { icon: CloudOff, title: "Offline first", desc: "Full functionality without internet", status: "Available" },
                  { icon: EyeOff, title: "No tracking", desc: "We don't collect or share anything", status: "None" },
                  { icon: Download, title: "Export & backup", desc: "Your data, your choice", status: "Always" },
                  { icon: Feather, title: "Lightweight app", desc: "Minimal storage footprint", status: "< 100MB" }
                ].map((item, i) => (
                  <div key={i} className="flex flex-col sm:flex-row sm:items-center justify-between p-4 sm:p-3 rounded-xl bg-white/5 border border-white/5 w-[220px] sm:w-auto flex-shrink-0 snap-center sm:snap-align-none">
                    <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-4 mb-4 sm:mb-0">
                      <div className="w-10 h-10 rounded-lg bg-kaizen-purple/10 flex items-center justify-center border border-kaizen-purple/20 shrink-0">
                        <item.icon className="w-5 h-5 text-kaizen-purple-light" />
                      </div>
                      <div>
                        <div className="text-sm font-bold text-white">{item.title}</div>
                        <div className="text-xs text-zinc-500">{item.desc}</div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between sm:justify-end gap-2 w-full sm:w-auto border-t border-white/10 sm:border-0 pt-3 sm:pt-0">
                      <span className="text-xs font-bold text-green-500">{item.status}</span>
                      <div className="w-5 h-5 rounded-full bg-green-500/10 flex items-center justify-center">
                        <Check className="w-3 h-3 text-green-500" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex justify-center items-center gap-2 text-xs text-kaizen-purple-light font-medium mt-2">
                <Lock className="w-3 h-3" />
                Private. Offline. Under your control.
              </div>

            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
