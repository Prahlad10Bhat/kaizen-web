"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import Image from "next/image";
import { Palette, Sun, Moon, Flower2, Coffee, Leaf, Feather, Layout, Cloud, User } from "lucide-react";

const themes = [
  { id: "light", name: "Light", mode: "light", color: "#ffffff", surface: "#f3f4f6", accent: "#374151", icon: Sun },
  { id: "dark", name: "Dark", mode: "dark", color: "#111827", surface: "#1f2937", accent: "#818cf8", icon: Moon },
  { id: "cherry", name: "Cherry Blossom", mode: "light", color: "#fdf2f8", surface: "#fbcfe8", accent: "#f43f5e", icon: Flower2 },
  { id: "coffee", name: "Coffee", mode: "dark", color: "#271c19", surface: "#3a2a26", accent: "#b48c68", icon: Coffee },
  { id: "ember", name: "Ember", mode: "dark", color: "#2d1a1a", surface: "#3f2424", accent: "#f97316", icon: Leaf },
  { id: "ivory", name: "Ivory", mode: "light", color: "#fdfbf7", surface: "#f3f0e6", accent: "#374151", icon: Feather },
];

export default function ThemeShowcase() {
  const [activeThemeId, setActiveThemeId] = useState(themes[1].id); // default to dark
  const activeTheme = themes.find(t => t.id === activeThemeId) || themes[1];
  const isDark = activeTheme.mode === "dark";

  return (
    <section id="themes" className="py-16 md:py-32 relative overflow-hidden bg-[#050505]">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_0%,rgba(255,255,255,0.03),transparent)] pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 relative z-10">
        <div className="text-center max-w-3xl mx-auto mb-10 md:mb-16">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-white text-sm font-medium mb-6"
          >
            <Palette className="w-4 h-4" />
            Make it yours
          </motion.div>
          
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight mb-4 sm:mb-6 text-white leading-tight">
            Beautiful themes for <br />
            every mood.
          </h2>
          <p className="text-base sm:text-xl text-zinc-400">
            Customize Kaizen to match your aesthetic. Instantly switch between carefully crafted color palettes that look great day or night.
          </p>
        </div>

        <div className="flex flex-col items-center gap-8 md:gap-12">
          {/* Theme Selector */}
          <div className="w-full sm:w-fit grid grid-cols-2 gap-2 sm:flex sm:flex-wrap sm:justify-center sm:gap-4 p-2 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-md shadow-2xl">
            {themes.map((theme) => {
              const Icon = theme.icon;
              const isActive = activeThemeId === theme.id;
              return (
                <button
                  key={theme.id}
                  onClick={() => setActiveThemeId(theme.id)}
                  className={`relative px-3 sm:px-4 py-2 rounded-xl font-medium text-sm transition-all duration-300 flex items-center justify-center gap-2 cursor-pointer min-w-0 ${
                    isActive ? "text-white" : "text-zinc-400 hover:text-white"
                  }`}
                >
                  {isActive && (
                    <motion.div
                      layoutId="theme-pill"
                      className="absolute inset-0 bg-white/10 border border-white/20 rounded-xl"
                      transition={{ type: "spring", stiffness: 300, damping: 30 }}
                    />
                  )}
                  <span className="relative z-10 flex items-center gap-2 min-w-0">
                    <Icon className="w-4 h-4" />
                    <span className="truncate">{theme.name}</span>
                  </span>
                </button>
              );
            })}
          </div>

          {/* Theme Preview */}
          <div 
            className="relative w-full max-w-4xl mx-auto aspect-[4/3] sm:aspect-[21/9] rounded-2xl sm:rounded-[2rem] border overflow-hidden flex items-center justify-center transition-colors duration-500 shadow-[0_40px_100px_-20px_rgba(0,0,0,0.5)]"
            style={{ 
              borderColor: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
              backgroundColor: activeTheme.color 
            }}
          >
            {/* Top Gloss */}
            <div className={`absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-current to-transparent z-10 opacity-30 ${isDark ? "text-white" : "text-black"}`}></div>
            
            {/* Subtle glow behind logo */}
            <div 
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1/2 h-1/2 blur-[80px] rounded-full opacity-20 pointer-events-none transition-colors duration-500"
              style={{ backgroundColor: activeTheme.accent }}
            ></div>

            <motion.div
              key={activeTheme.id}
              initial={{ opacity: 0, scale: 0.85, filter: "blur(10px)" }}
              animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
              transition={{ duration: 0.5, type: "spring", stiffness: 200, damping: 20 }}
              className="relative w-[40%] max-w-[180px] sm:max-w-[220px] aspect-square z-20"
            >
              <Image 
                src={`/images/app_themes/logo_${activeTheme.id}.png`} 
                alt={`${activeTheme.name} theme preview`}
                fill
                className="object-contain drop-shadow-2xl"
                priority
              />
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}
