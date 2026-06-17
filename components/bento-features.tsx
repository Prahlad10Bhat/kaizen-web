"use client";

import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { Brain, CalendarCheck, LayoutList, BookOpen, Clock, Sparkles } from "lucide-react";

const features = [
  {
    title: "AI-Powered Organization",
    description: "Your personal assistant automatically tags, prioritizes, and schedules your tasks.",
    icon: <Brain className="w-6 h-6 text-kaizen-purple" />,
    className: "md:col-span-2 md:row-span-2",
  },
  {
    title: "Smart Calendar",
    description: "Two-way sync with Google Calendar. Never double-book again.",
    icon: <CalendarCheck className="w-6 h-6 text-blue-400" />,
    className: "md:col-span-1 md:row-span-1",
  },
  {
    title: "Kanban & Lists",
    description: "Visualize your workflow with flexible views.",
    icon: <LayoutList className="w-6 h-6 text-green-400" />,
    className: "md:col-span-1 md:row-span-1",
  },
  {
    title: "Deep Work Notes",
    description: "Distraction-free editor with markdown support.",
    icon: <BookOpen className="w-6 h-6 text-yellow-400" />,
    className: "md:col-span-1 md:row-span-2",
  },
  {
    title: "Time Tracking",
    description: "Built-in Pomodoro and time logging.",
    icon: <Clock className="w-6 h-6 text-orange-400" />,
    className: "md:col-span-2 md:row-span-1 flex-row items-center gap-6",
  },
];

function FeatureCard({ feature, index }: { feature: typeof features[0], index: number }) {
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const mouseXSpring = useSpring(x);
  const mouseYSpring = useSpring(y);

  const rotateX = useTransform(mouseYSpring, [-0.5, 0.5], ["5deg", "-5deg"]);
  const rotateY = useTransform(mouseXSpring, [-0.5, 0.5], ["-5deg", "5deg"]);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement, MouseEvent>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;
    const xPct = mouseX / width - 0.5;
    const yPct = mouseY / height - 0.5;
    x.set(xPct);
    y.set(yPct);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.1 }}
      className={`perspective-1000 ${feature.className}`}
      style={{ transformStyle: "preserve-3d" }}
    >
      <motion.div
        onMouseMove={handleMouseMove}
        onMouseLeave={handleMouseLeave}
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d",
        }}
        className="group relative w-full h-full rounded-3xl border border-white/5 bg-kaizen-surface p-8 overflow-hidden hover:border-white/20 transition-colors duration-500 flex flex-col justify-between"
      >
        <div className="absolute inset-0 bg-gradient-to-br from-white/[0.02] to-transparent pointer-events-none" />
        
        <div className={`relative z-10 flex ${feature.className.includes('flex-row') ? 'flex-row items-center gap-6' : 'flex-col gap-6'}`} style={{ transform: "translateZ(30px)" }}>
          <div className="w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0 group-hover:scale-110 transition-transform duration-500 ease-out shadow-lg">
            {feature.icon}
          </div>
          
          <div>
            <h3 className="text-xl font-semibold mb-2 text-white/90">{feature.title}</h3>
            <p className="text-zinc-500 leading-relaxed max-w-sm">{feature.description}</p>
          </div>
        </div>
        
        {/* Subtle hover glow effect */}
        <div className="absolute -bottom-1/2 -right-1/2 w-full h-full bg-kaizen-purple/20 blur-[80px] opacity-0 group-hover:opacity-100 transition-opacity duration-700 pointer-events-none" />
      </motion.div>
    </motion.div>
  );
}

export default function BentoFeatures() {
  return (
    <section className="py-24 relative overflow-hidden" id="features-bento">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-kaizen-purple/10 blur-[150px] rounded-full pointer-events-none" />
      
      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-kaizen-purple/10 text-kaizen-purple text-sm font-medium mb-6"
          >
            <Sparkles className="w-4 h-4" />
            Everything you need
          </motion.div>
          
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold tracking-tight mb-6"
          >
            A tool for thought. <br className="hidden md:block" />
            <span className="text-zinc-500">And action.</span>
          </motion.h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 auto-rows-[220px] gap-4">
          {features.map((feature, i) => (
            <FeatureCard key={feature.title} feature={feature} index={i} />
          ))}
        </div>
      </div>
    </section>
  );
}

