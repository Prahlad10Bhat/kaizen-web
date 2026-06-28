"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Download, Play, Shield, WifiOff, Sparkles } from "lucide-react";
import Image from "next/image";
import { useLatestRelease } from "@/hooks/use-latest-release";
import { FaWindows, FaAndroid, FaApple } from "react-icons/fa";
import { DownloadModal } from "./download-modal";

export default function Hero() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { downloadUrl } = useLatestRelease();
  const [activeIndex, setActiveIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % 3);
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  const slideVariants = {
    front: { 
      opacity: 1, x: 0, y: 0, rotateY: 0, rotateX: 0, scale: 1.0, zIndex: 30,
      filter: "brightness(1)"
    },
    right: { 
      opacity: 0.6, x: 160, y: 0, rotateY: -12, rotateX: 0, scale: 0.85, zIndex: 20,
      filter: "brightness(0.5)"
    },
    left: { 
      opacity: 0.6, x: -160, y: 0, rotateY: 12, rotateX: 0, scale: 0.85, zIndex: 20,
      filter: "brightness(0.5)"
    }
  };

  const images = [
    { src: "/images/dashboard.jpeg", alt: "Dashboard" },
    { src: "/images/notes.jpeg", alt: "Notes" },
    { src: "/images/tasks.jpeg", alt: "Tasks" }
  ];

  return (
    <section className="relative min-h-[90vh] pt-32 pb-20 overflow-hidden flex items-center">
      {/* Background glow */}
      <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-kaizen-purple/10 blur-[120px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-6 w-full grid grid-cols-1 lg:grid-cols-2 gap-12 items-center relative z-10">
        
        {/* Left Column */}
        <motion.div 
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
          className="flex flex-col items-start text-left"
        >
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-zinc-400 text-xs font-medium mb-8">
            <Sparkles className="w-3 h-3 text-kaizen-purple-light" />
            Your all-in-one productivity system
          </div>

          <h1 className="text-5xl md:text-6xl lg:text-[72px] font-bold tracking-tighter-plus leading-[1.05] mb-6">
            <span className="text-white block">Build better systems.</span>
            <span className="text-gradient-warm block mt-1">Make real progress.</span>
          </h1>

          <p className="text-lg text-zinc-400 max-w-lg mb-10 tracking-tight leading-relaxed">
            Tasks, notes, habits, calendar, goals and more. <br className="hidden md:block"/>
            Kaizen brings everything together so you can <br className="hidden md:block"/>
            focus on what truly matters.
          </p>

          <div className="flex flex-col sm:flex-row items-center gap-4 mb-16 w-full sm:w-auto">
            <button
              onClick={() => setIsModalOpen(true)}
              className="w-full sm:w-auto px-6 py-3 sm:py-3.5 rounded-xl bg-kaizen-purple text-white font-semibold text-sm hover:bg-kaizen-purple-light transition-colors flex items-center justify-center gap-2 sm:gap-3 shadow-[0_0_20px_rgba(99,102,241,0.3)] cursor-pointer"
            >
              <Download className="w-4 h-4" />
              <span className="flex items-center">
                <span className="hidden sm:inline">Download for</span>
                <span className="sm:hidden">Download</span>
                <span className="hidden sm:flex items-center gap-1.5 ml-3 text-lg">
                  <FaWindows title="Windows" />
                  <FaAndroid title="Android (Coming Soon)" className="opacity-40" />
                  <FaApple title="Mac/iOS (Coming Soon)" className="opacity-40" />
                </span>
              </span>
            </button>
          </div>

          {/* Trust Indicators */}
          <div className="flex flex-wrap items-center gap-6 text-xs text-zinc-500 font-medium">
            <div className="flex items-center gap-2">
              <WifiOff className="w-4 h-4" />
              Works Offline
            </div>
            <div className="w-1 h-1 rounded-full bg-zinc-700"></div>
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4" />
              Privacy Focused
            </div>
          </div>
        </motion.div>

        {/* Right Column: 3D Image Collage */}
        <div 
          className="relative h-[400px] md:h-[500px] lg:h-[600px] w-full perspective-1000 hidden lg:flex items-center justify-center cursor-pointer"
          onClick={() => setActiveIndex((prev) => (prev + 1) % 3)}
        >
          {images.map((img, index) => {
            let position = "left";
            if (index === activeIndex) position = "front";
            else if (index === (activeIndex + 1) % 3) position = "right";

            return (
              <motion.div
                key={img.src}
                initial={false}
                animate={position}
                variants={slideVariants}
                transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
                className="absolute w-[90%] max-w-[650px] rounded-2xl border border-white/10 bg-kaizen-surface/90 backdrop-blur-md shadow-[0_40px_100px_-20px_rgba(0,0,0,0.7)] overflow-hidden ring-1 ring-white/20"
              >
                <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-white/30 to-transparent z-10"></div>
                <Image src={img.src} alt={img.alt} width={1000} height={600} className="w-full object-cover" priority={index === 0} />
              </motion.div>
            );
          })}
        </div>

      </div>
      <DownloadModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </section>
  );
}