"use client";

import { motion } from "framer-motion";
import { 
  CheckSquare, 
  FileText, 
  Calendar, 
  Circle, 
  Heart, 
  Dumbbell, 
  Target, 
  Scale, 
  Box, 
  Zap, 
  Sparkles 
} from "lucide-react";
import { FaApple, FaWindows, FaLinux } from "react-icons/fa";

export default function ProductOverview() {
  const features = [
    { name: "Tasks", icon: <CheckSquare className="w-4 h-4" /> },
    { name: "Notes", icon: <FileText className="w-4 h-4" /> },
    { name: "Calendar", icon: <Calendar className="w-4 h-4" /> },
    { name: "Habits", icon: <Circle className="w-4 h-4" /> },
    { name: "Health", icon: <Heart className="w-4 h-4" /> },
    { name: "Workouts", icon: <Dumbbell className="w-4 h-4" /> },
    { name: "Focus", icon: <Target className="w-4 h-4" /> },
  ];

  const cards = [
    {
      icon: <Heart className="w-8 h-8" />,
      title: (
        <>
          Balance productivity <br />
          and <span className="text-kaizen-purple-light">well-being.</span>
        </>
      ),
      description: "Bring together your tasks, calendar, and goals with your workouts and habits. Perform at your best—sustainably.",
    },
    {
      icon: <Box className="w-8 h-8" />,
      title: (
        <>
          A workspace that adapts <br />
          to <span className="text-kaizen-purple-light">your life.</span>
        </>
      ),
      description: "Start with the essentials and add what you need. Kaizen is modular, flexible, and designed to grow with you.",
    },
    {
      icon: <Zap className="w-8 h-8" />,
      title: (
        <>
          One system. <br />
          <span className="text-kaizen-purple-light">Everything</span> connected.
        </>
      ),
      description: "Notes become tasks. Tasks become progress. Habits build results. Everything works together so you can focus on what truly matters.",
    },
  ];

  return (
    <section id="why-kaizen" className="py-24 relative overflow-hidden bg-kaizen-bg">
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-start">
          {/* Left Column */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8 }}
            className="flex flex-col"
          >
            <h2 className="text-4xl md:text-5xl lg:text-[56px] font-bold tracking-tight mb-6 leading-[1.1]">
              <span className="text-kaizen-purple-light">Being human</span> <br />
              <span className="text-white">is all about balance.</span> <br />
              <span className="text-white">Kaizen helps you</span> <br />
              <span className="text-kaizen-purple-light">find it.</span>
            </h2>
            
            <p className="text-lg text-zinc-400 leading-relaxed mb-10 max-w-lg">
              Unify your work, health, and personal growth in one powerful system. Stay focused, build better habits, and make progress—<span className="text-kaizen-purple-light">without sacrificing what matters.</span>
            </p>

            <div className="flex flex-wrap items-center gap-4 mb-10 text-sm font-medium text-zinc-300">
              {features.map((f) => (
                <div key={f.name} className="flex items-center gap-2">
                  {f.icon}
                  <span>{f.name}</span>
                </div>
              ))}
            </div>

            <div className="flex items-center gap-3 text-lg font-medium text-zinc-400 mb-12">
              <Scale className="w-5 h-5 text-kaizen-purple-light" />
              <span>
                One system. Every part of you. <span className="text-kaizen-purple-light">In balance.</span>
              </span>
            </div>

            <div className="flex flex-col">
              <span className="text-sm text-zinc-500 font-medium mb-3">Available on</span>
              <div className="flex flex-wrap gap-3 text-white/80">
                <div className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white/5 border border-white/10 text-sm font-medium transition-colors hover:bg-white/10 cursor-pointer">
                  <FaWindows className="w-4 h-4" /> Windows
                </div>
              </div>
            </div>
          </motion.div>

          {/* Right Column */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="flex flex-col gap-4"
          >
            {cards.map((card, i) => (
              <div key={i} className="p-8 rounded-2xl bg-[#0f0f13]/80 border border-white/5 flex flex-col sm:flex-row gap-6 items-start hover:border-kaizen-purple/30 transition-colors shadow-lg backdrop-blur-sm cursor-pointer">
                <div className="flex-shrink-0 w-16 h-16 rounded-2xl bg-kaizen-purple/10 border border-kaizen-purple/20 flex items-center justify-center text-kaizen-purple-light">
                  {card.icon}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white tracking-tight mb-3 leading-snug">
                    {card.title}
                  </h3>
                  <p className="text-sm text-zinc-400 leading-relaxed">
                    {card.description}
                  </p>
                </div>
              </div>
            ))}
          </motion.div>
        </div>

      </div>
    </section>
  );
}
