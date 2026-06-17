"use client";

import { motion } from "framer-motion";

export default function SocialProof() {
  return (
    <section className="py-20 border-y border-white/5 relative overflow-hidden bg-kaizen-surface/30">
      <div className="max-w-7xl mx-auto px-6">
        <p className="text-center text-zinc-500 text-sm font-medium tracking-wide uppercase mb-10">
          Trusted by high-performing teams at
        </p>
        
        <div className="flex flex-wrap justify-center items-center gap-12 md:gap-24 opacity-60 grayscale">
          {["Acme Corp", "Quantum", "Nexus", "Starlight", "Horizon"].map((company, i) => (
            <motion.div
              key={company}
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1, duration: 0.5 }}
              className="text-xl md:text-2xl font-bold tracking-tight text-white/80 select-none flex items-center gap-2"
            >
              <div className="w-6 h-6 bg-white/20 rounded-md rotate-45"></div>
              {company}
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
