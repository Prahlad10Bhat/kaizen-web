"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";

const tabs = [
  { id: "Notes", image: "/images/notes.jpeg" },
  { id: "Tasks", image: "/images/tasks.jpeg" },
  { id: "Habits", image: "/images/habit_tracker.jpeg" },
  { id: "Calendar", image: "/images/calendar.jpeg" },
  { id: "AI", image: "/images/dashboard.jpeg" }, // Using dashboard.jpeg as placeholder
];

export default function ProductPreview() {
  const [active, setActive] = useState(tabs[0].id);

  const activeTab = tabs.find((t) => t.id === active);

  return (
    <section className="py-32 flex items-center relative" id="features">
      <div className="max-w-7xl mx-auto px-6 w-full">
        <div className="grid lg:grid-cols-[1fr_2fr] gap-16 lg:gap-24 items-center">
          <div className="flex flex-col">
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-kaizen-purple uppercase tracking-[0.2em] text-sm font-semibold mb-8 flex items-center gap-2"
            >
              <span className="w-8 h-px bg-kaizen-purple"></span>
              Core System
            </motion.p>

            <div className="space-y-2 relative" onMouseLeave={() => setActive(active)}>
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActive(tab.id)}
                  onMouseEnter={() => setActive(tab.id)}
                  className={`relative w-full text-left px-6 py-4 rounded-2xl transition-all duration-300 ${
                    active === tab.id
                      ? "text-white"
                      : "text-zinc-500 hover:text-zinc-300"
                  }`}
                >
                  {active === tab.id && (
                    <motion.div
                      layoutId="active-tab"
                      className="absolute inset-0 bg-white/5 border border-white/10 rounded-2xl"
                      transition={{ type: "spring", stiffness: 300, damping: 30 }}
                    />
                  )}
                  <span className="relative z-10 text-3xl font-semibold tracking-tight">{tab.id}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="relative w-full aspect-[16/9] bg-kaizen-surface rounded-[2rem] border border-white/5 p-4 shadow-2xl overflow-hidden flex flex-col">
            <div className="absolute inset-0 bg-gradient-to-br from-kaizen-purple/5 to-transparent pointer-events-none"></div>
            
            {/* Window header */}
            <div className="flex items-center gap-2 px-4 py-3 mb-2 border-b border-white/5">
              <div className="w-3 h-3 rounded-full bg-zinc-800"></div>
              <div className="w-3 h-3 rounded-full bg-zinc-800"></div>
              <div className="w-3 h-3 rounded-full bg-zinc-800"></div>
            </div>

            <div className="relative flex-1 rounded-xl overflow-hidden border border-white/5 bg-[#0a0a0a]">
              <AnimatePresence mode="wait">
                <motion.div
                  key={active}
                  initial={{ opacity: 0, scale: 0.98, filter: "blur(4px)" }}
                  animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
                  exit={{ opacity: 0, scale: 1.02, filter: "blur(4px)" }}
                  transition={{ duration: 0.4, ease: "easeInOut" }}
                  className="absolute inset-0 w-full h-full"
                >
                  {activeTab?.image ? (
                     <Image
                      src={activeTab.image}
                      alt={`${activeTab.id} Preview`}
                      fill
                      className="object-cover object-left-top"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-zinc-600 font-medium">
                      {active} Preview
                    </div>
                  )}
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}