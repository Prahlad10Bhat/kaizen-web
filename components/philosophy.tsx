"use client";

import { motion } from "framer-motion";

export default function Philosophy() {
  return (
    <section className="py-16 md:py-24 relative overflow-hidden bg-kaizen-bg flex items-center justify-center">
      {/* Subtle grid and vignette */}
      <div className="absolute inset-0 bg-grid-white opacity-10 pointer-events-none"></div>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,transparent_0%,var(--color-kaizen-bg)_70%)] pointer-events-none"></div>

      <div className="max-w-4xl mx-auto px-6 relative z-10 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
        >
          <h2 className="text-4xl md:text-5xl lg:text-7xl font-bold tracking-tighter-plus text-white mb-8 leading-[1.1]">
            Designed for <span className="text-zinc-500 italic font-serif tracking-normal">deep work</span>. <br />
            Built for velocity.
          </h2>
          
          <p className="text-xl md:text-2xl text-zinc-400 leading-relaxed max-w-3xl mx-auto font-medium">
            We believe that your tools should get out of the way. Every interaction in Kaizen is engineered for speed, so you can spend less time managing your work and more time actually doing it.
          </p>
        </motion.div>
      </div>
    </section>
  );
}
