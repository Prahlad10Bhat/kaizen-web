"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState } from "react";
import Image from "next/image";
import { LayoutList, BookOpen, CalendarCheck, Target, Box } from "lucide-react";

const features = [
  {
    id: "tasks",
    title: "Tasks & Projects",
    description: "Organize your work with powerful task management.",
    icon: <LayoutList className="w-5 h-5" />,
    image: "/images/tasks.jpeg",
  },
  {
    id: "notes",
    title: "Notes",
    description: "Capture ideas and organize your thoughts.",
    icon: <BookOpen className="w-5 h-5" />,
    image: "/images/notes.jpeg",
  },
  {
    id: "habits",
    title: "Habit Tracker",
    description: "Build better habits with beautiful streak tracking.",
    icon: <Target className="w-5 h-5" />,
    image: "/images/habit_tracker.jpeg",
  },
  {
    id: "calendar",
    title: "Calendar",
    description: "Plan your days and never miss what matters.",
    icon: <CalendarCheck className="w-5 h-5" />,
    image: "/images/calendar.jpeg",
  },
  {
    id: "more",
    title: "And More",
    description: "AI, Canvas, App Tracker, BoxClock and more.",
    icon: <Box className="w-5 h-5" />,
    image: "/images/dashboard.jpeg",
  },
];

export default function InteractiveShowcase() {
  const [activeFeature, setActiveFeature] = useState(features[0].id);

  const activeIndex = features.findIndex((f) => f.id === activeFeature);

  return (
    <section id="features" className="py-16 md:py-32 relative bg-kaizen-bg">
      <div className="max-w-7xl mx-auto px-6">
        
        {/* Header */}
        <div className="mb-20 text-center">
          <div className="inline-flex items-center gap-2 text-orange-400/80 text-xs font-bold tracking-widest uppercase mb-6">
            <span className="text-orange-400">❖</span> EVERYTHING IN ONE PLACE
          </div>
          <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-4 text-white">
            Everything you need. Nothing you don't.
          </h2>
          <p className="text-lg text-zinc-400">
            Powerful tools that work together seamlessly.
          </p>
        </div>

        {/* Content Layout */}
        <div className="flex flex-col xl:flex-row gap-8 relative items-center xl:items-start">
          
          {/* Left Side: Feature Cards */}
          <div className="w-full xl:w-1/2 flex flex-wrap gap-4">
            {features.map((feature) => {
              const isActive = activeFeature === feature.id;
              return (
                <button
                  key={feature.id}
                  onClick={() => setActiveFeature(feature.id)}
                  className={`text-left p-6 rounded-2xl transition-all duration-300 relative border w-full sm:w-[calc(50%-8px)] lg:w-[calc(33.33%-11px)] xl:w-[calc(50%-8px)] flex-grow cursor-pointer ${
                    isActive
                      ? "bg-gradient-to-br from-kaizen-surface to-kaizen-purple/20 border-kaizen-purple/30 shadow-[0_0_30px_rgba(99,102,241,0.15)]"
                      : "bg-kaizen-surface/50 border-white/5 hover:bg-kaizen-surface hover:border-white/10"
                  }`}
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 transition-colors ${
                    isActive ? "bg-kaizen-purple text-white shadow-lg" : "bg-white/5 text-zinc-400"
                  }`}>
                    {feature.icon}
                  </div>
                  
                  <h3 className={`text-sm font-bold mb-2 ${isActive ? "text-white" : "text-zinc-200"}`}>
                    {feature.title}
                  </h3>
                  
                  <p className={`text-xs leading-relaxed ${isActive ? "text-zinc-300" : "text-zinc-500"}`}>
                    {feature.description}
                  </p>
                </button>
              );
            })}
          </div>

          {/* Right Side: Image Preview */}
          <div className="w-full xl:w-1/2 relative aspect-[16/9] rounded-[2rem] border border-white/10 bg-kaizen-surface/50 backdrop-blur-xl overflow-hidden shadow-2xl ring-1 ring-white/5 mt-8 xl:mt-0">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[80%] h-[80%] bg-kaizen-purple/10 blur-[100px] rounded-full pointer-events-none" />
            
            <AnimatePresence mode="wait">
              <motion.div
                key={activeFeature}
                initial={{ opacity: 0, scale: 0.98, filter: "blur(5px)" }}
                animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
                exit={{ opacity: 0, scale: 1.02, filter: "blur(5px)" }}
                transition={{ duration: 0.4 }}
                className="absolute inset-0 p-6 flex items-center justify-center"
              >
                <div className="relative w-full h-full rounded-xl overflow-hidden border border-white/10 shadow-2xl bg-black/40">
                  <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/50 to-transparent z-10"></div>
                  
                  {activeFeature === "more" ? (
                    <div className="w-full h-full grid grid-cols-2 gap-3 p-3 bg-zinc-950/40">
                      {[
                        { src: "/images/canvas.jpeg", title: "Canvas" },
                        { src: "/images/box_clock.jpeg", title: "BoxClock" },
                        { src: "/images/workouts.jpeg", title: "Workouts" },
                        { src: "/images/screentime.jpeg", title: "App Tracker" },
                      ].map((item, index) => (
                        <div key={index} className="relative w-full h-full rounded-lg overflow-hidden border border-white/5 group bg-zinc-900/50 shadow-inner cursor-pointer">
                          <Image
                            src={item.src}
                            alt={item.title}
                            fill
                            className="object-cover object-top opacity-80 group-hover:opacity-100 group-hover:scale-102 transition-all duration-300"
                          />
                          <div className="absolute bottom-2 left-2 px-2.5 py-1 rounded bg-black/75 border border-white/10 text-[10px] font-bold text-white shadow-md backdrop-blur-sm">
                            {item.title}
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <Image
                      src={features[activeIndex].image}
                      alt={features[activeIndex].title}
                      fill
                      className="object-cover object-top opacity-90"
                      priority
                    />
                  )}
                </div>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </div>
    </section>
  );
}
