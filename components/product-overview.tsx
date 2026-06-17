"use client";

import { motion } from "framer-motion";
import { Sparkles, Zap, Shield, Globe } from "lucide-react";

export default function ProductOverview() {
  const stats = [
    { label: "Downloads", value: "2.5M+", icon: <Globe className="w-5 h-5 text-kaizen-purple" /> },
    { label: "Time Saved", value: "140M hrs", icon: <Zap className="w-5 h-5 text-yellow-500" /> },
    { label: "Uptime", value: "99.99%", icon: <Shield className="w-5 h-5 text-green-500" /> },
    { label: "Rating", value: "4.9/5", icon: <Sparkles className="w-5 h-5 text-blue-500" /> },
  ];

  return (
    <section className="py-24 relative overflow-hidden bg-kaizen-bg">
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8 }}
          >
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-6 leading-tight">
              A unified system for <br />
              <span className="text-zinc-500">modern knowledge workers.</span>
            </h2>
            <p className="text-lg text-zinc-400 leading-relaxed mb-8">
              Kaizen replaces your fragmented tool stack. By combining tasks, notes, calendar, and habit tracking into a single lightning-fast native app, you reclaim your focus and execute at your highest level.
            </p>
            <div className="flex gap-4">
              <div className="flex flex-col">
                <span className="text-sm text-zinc-500 font-medium mb-1">Available on</span>
                <div className="flex gap-3 text-white/80">
                  <span className="px-3 py-1.5 rounded-md bg-white/5 border border-white/10 text-sm font-medium">macOS</span>
                  <span className="px-3 py-1.5 rounded-md bg-white/5 border border-white/10 text-sm font-medium">Windows</span>
                  <span className="px-3 py-1.5 rounded-md bg-white/5 border border-white/10 text-sm font-medium">Linux</span>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="grid grid-cols-2 gap-4"
          >
            {stats.map((stat, i) => (
              <div key={stat.label} className="p-6 rounded-2xl bg-kaizen-surface border border-white/5 shadow-xl flex flex-col gap-4">
                <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                  {stat.icon}
                </div>
                <div>
                  <div className="text-3xl font-bold text-white tracking-tight mb-1">{stat.value}</div>
                  <div className="text-sm font-medium text-zinc-500">{stat.label}</div>
                </div>
              </div>
            ))}
          </motion.div>
        </div>
      </div>
    </section>
  );
}
