"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Palette, Check, Sun, Moon, Flower2, Coffee, Leaf, Feather, Layout, Cloud, User } from "lucide-react";

const themes = [
  { id: "light", name: "Light", mode: "light", color: "#ffffff", surface: "#f3f4f6", accent: "#374151", icon: Sun },
  { id: "dark", name: "Dark", mode: "dark", color: "#111827", surface: "#1f2937", accent: "#818cf8", icon: Moon },
  { id: "cherry", name: "Cherry Blossom", mode: "light", color: "#fdf2f8", surface: "#fbcfe8", accent: "#f43f5e", icon: Flower2 },
  { id: "coffee", name: "Coffee", mode: "dark", color: "#271c19", surface: "#3a2a26", accent: "#b48c68", icon: Coffee },
  { id: "ember", name: "Ember", mode: "dark", color: "#2d1a1a", surface: "#3f2424", accent: "#f97316", icon: Leaf },
  { id: "ivory", name: "Ivory", mode: "light", color: "#fdfbf7", surface: "#f3f0e6", accent: "#374151", icon: Feather },
  { id: "ash", name: "Ash", mode: "light", color: "#e5e7eb", surface: "#f3f4f6", accent: "#374151", icon: Layout },
  { id: "plush", name: "Plush", mode: "light", color: "#f5f0e6", surface: "#ffffff", accent: "#31416d", icon: Cloud },
];

export default function ThemeShowcase() {
  const [activeThemeId, setActiveThemeId] = useState(themes[1].id); // default to dark
  const activeTheme = themes.find(t => t.id === activeThemeId) || themes[1];
  const isDark = activeTheme.mode === "dark";

  return (
    <section className="py-32 relative overflow-hidden bg-[#050505]">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_0%,rgba(255,255,255,0.03),transparent)] pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-white text-sm font-medium mb-6"
          >
            <Palette className="w-4 h-4" />
            Make it yours
          </motion.div>
          
          <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-6 text-white">
            Beautiful themes for <br />
            every mood.
          </h2>
          <p className="text-xl text-zinc-400">
            Customize Kaizen to match your aesthetic. Instantly switch between carefully crafted color palettes that look great day or night.
          </p>
        </div>

        <div className="flex flex-col items-center gap-12">
          {/* Theme Selector */}
          <div className="flex flex-wrap justify-center gap-4 p-2 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-md shadow-2xl">
            {themes.map((theme) => {
              const Icon = theme.icon;
              const isActive = activeThemeId === theme.id;
              return (
                <button
                  key={theme.id}
                  onClick={() => setActiveThemeId(theme.id)}
                  className={`relative px-4 py-2 rounded-xl font-medium text-sm transition-all duration-300 flex items-center gap-2 ${
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
                  <span className="relative z-10 flex items-center gap-2">
                    <Icon className="w-4 h-4" />
                    {theme.name}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Theme Preview App UI */}
          <div 
            className="relative w-full max-w-5xl aspect-[16/10] rounded-[2rem] border overflow-hidden flex transition-all duration-300 shadow-[0_40px_100px_-20px_rgba(0,0,0,0.5)]"
            style={{ 
              borderColor: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
              backgroundColor: activeTheme.color 
            }}
          >
            {/* Top Window Bar (Mac/Windows style) */}
            <div className="absolute top-0 right-0 p-4 flex items-center justify-end gap-4 z-20 w-full pointer-events-none">
              <div className="flex items-center gap-2 text-xs font-medium opacity-50" style={{ color: isDark ? 'white' : 'black' }}>
                <div className="w-3 h-3 rounded-full border border-current opacity-50 flex items-center justify-center">?</div>
                App Tour
              </div>
              <div className="flex gap-2 opacity-30" style={{ color: isDark ? 'white' : 'black' }}>
                <div className="w-3 h-[1px] bg-current"></div>
                <div className="w-3 h-3 border border-current"></div>
                <div className="w-3 h-3 relative">
                  <div className="absolute inset-0 border border-current rotate-45 scale-y-[0.1]"></div>
                  <div className="absolute inset-0 border border-current -rotate-45 scale-y-[0.1]"></div>
                </div>
              </div>
            </div>
            
            {/* Top Gloss */}
            <div className={`absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-current to-transparent z-10 opacity-30 ${isDark ? "text-white" : "text-black"}`}></div>
            
            {/* Icon Sidebar */}
            <div 
              className="w-16 md:w-20 border-r flex flex-col items-center py-6 gap-6 transition-colors duration-300 z-10"
              style={{ borderColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)', backgroundColor: activeTheme.color }}
            >
              {/* Logo */}
              <div className="mb-4">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M4 12L12 4L20 12L12 20L4 12Z" fill={activeTheme.accent} />
                  <path d="M4 12L12 4V20L4 12Z" fill="white" fillOpacity="0.5" />
                </svg>
              </div>

              {/* Top Icons */}
              <div className="flex flex-col gap-5 w-full items-center">
                {[
                  <svg key="1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>,
                  <svg key="2" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>,
                  <svg key="3" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" x2="8" y1="13" y2="13"/><line x1="16" x2="8" y1="17" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>,
                  <svg key="4" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg>,
                  <svg key="5" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>,
                  <svg key="6" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c-2.28 0-4.5 1.5-4.5 4.5 0 1.5 1 2.5 2.5 2.5s2.5-1 2.5-2.5"/><path d="M12 2c0 2 2.5 4.5 2.5 7.5S12 15 12 15s-2.5-2-2.5-5.5S12 2 12 2z"/></svg>,
                  <svg key="7" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" x2="12" y1="22.08" y2="12"/></svg>,
                  <svg key="8" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>,
                  <svg key="9" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
                  <svg key="10" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/></svg>,
                ].map((icon, i) => (
                  <div key={i} className={`flex justify-center w-full opacity-40 transition-colors duration-300 ${isDark ? "text-white" : "text-black"}`}>
                    {icon}
                  </div>
                ))}
              </div>

              <div className="mt-auto flex flex-col gap-5 w-full items-center">
                {/* Message */}
                <div className={`flex justify-center w-full opacity-40 transition-colors duration-300 ${isDark ? "text-white" : "text-black"}`}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                </div>
                
                {/* Active Settings */}
                <div className="relative flex justify-center w-full py-2" style={{ backgroundColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' }}>
                  <div className="absolute left-0 top-0 bottom-0 w-[3px]" style={{ backgroundColor: activeTheme.accent }}></div>
                  <div style={{ color: activeTheme.accent }}>
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
                  </div>
                </div>

                {/* Profile */}
                <div className="w-6 h-6 rounded-full bg-zinc-800 border flex items-center justify-center mb-2" style={{ borderColor: isDark ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.2)' }}>
                  <User className="w-3.5 h-3.5 text-zinc-400" />
                </div>
              </div>
            </div>

            {/* Main Content Area */}
            <div className="flex-1 overflow-y-auto pb-24 relative transition-colors duration-300" style={{ backgroundColor: activeTheme.surface }}>
              
              <div className="max-w-4xl mx-auto px-8 md:px-12 py-10 pt-16">
                {/* Header */}
                <div className="flex items-center justify-between mb-12">
                  <h3 className={`text-3xl md:text-4xl font-bold transition-colors duration-300 ${isDark ? "text-white" : "text-black"}`}>Settings</h3>
                  
                  <div className="flex items-center gap-4">
                    <span className="text-xs font-medium opacity-50" style={{ color: isDark ? 'white' : 'black' }}>v1.0.12</span>
                    <button 
                      className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium border transition-colors duration-300 ${
                        isDark ? "bg-white/5 border-white/10 text-white hover:bg-white/10" : "bg-black/5 border-black/10 text-black hover:bg-black/10"
                      }`}
                    >
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
                      Up to Date
                    </button>
                  </div>
                </div>

                <div className="flex flex-col gap-10">
                  {/* Theme Section */}
                  <section>
                    <h4 className="text-xs font-bold tracking-widest mb-3 opacity-40 uppercase" style={{ color: isDark ? 'white' : 'black' }}>Theme</h4>
                    <div 
                      className="rounded-xl overflow-hidden border flex flex-col transition-colors duration-300"
                      style={{ 
                        backgroundColor: isDark ? 'rgba(255,255,255,0.02)' : 'rgba(255,255,255,0.5)',
                        borderColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' 
                      }}
                    >
                      <div className="px-5 py-4 flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <activeTheme.icon className="w-4 h-4" style={{ color: activeTheme.accent }} />
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>Theme</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium" style={{ color: activeTheme.accent }}>{activeTheme.name}</span>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-30" style={{ color: isDark ? 'white' : 'black' }}><path d="m9 18 6-6-6-6"/></svg>
                        </div>
                      </div>
                    </div>
                  </section>

                  {/* Notifications Section */}
                  <section>
                    <h4 className="text-xs font-bold tracking-widest mb-3 opacity-40 uppercase" style={{ color: isDark ? 'white' : 'black' }}>Notifications</h4>
                    <div 
                      className="rounded-xl overflow-hidden border flex flex-col transition-colors duration-300"
                      style={{ 
                        backgroundColor: isDark ? 'rgba(255,255,255,0.02)' : 'rgba(255,255,255,0.5)',
                        borderColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' 
                      }}
                    >
                      <div className={`px-5 py-4 flex items-center justify-between border-b ${isDark ? 'border-white/5' : 'border-black/5'}`}>
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={isDark ? "text-zinc-400" : "text-zinc-600"}><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>Enable Notifications</span>
                        </div>
                        {/* Toggle */}
                        <div className="w-10 h-6 rounded-full relative transition-colors duration-300" style={{ backgroundColor: activeTheme.accent }}>
                          <div className={`absolute right-1 top-1 bottom-1 w-4 rounded-full shadow-sm transition-colors duration-300 ${isDark ? 'bg-white' : 'bg-black'}`} style={{ opacity: isDark ? 0.9 : 0.8 }}></div>
                        </div>
                      </div>

                      <div className={`px-5 py-4 flex items-center justify-between border-b ${isDark ? 'border-white/5' : 'border-black/5'}`}>
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={isDark ? "text-zinc-400" : "text-zinc-600"}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>Enable Floating Timer</span>
                        </div>
                        {/* Toggle */}
                        <div className="w-10 h-6 rounded-full relative transition-colors duration-300" style={{ backgroundColor: activeTheme.accent }}>
                          <div className={`absolute right-1 top-1 bottom-1 w-4 rounded-full shadow-sm transition-colors duration-300 ${isDark ? 'bg-white' : 'bg-black'}`} style={{ opacity: isDark ? 0.9 : 0.8 }}></div>
                        </div>
                      </div>

                      <div className="px-5 py-4 flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={isDark ? "text-zinc-400" : "text-zinc-600"}><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>Alarm Tune</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium" style={{ color: activeTheme.accent }}>Alarm Tune</span>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-30" style={{ color: isDark ? 'white' : 'black' }}><path d="m9 18 6-6-6-6"/></svg>
                        </div>
                      </div>
                    </div>
                  </section>

                  {/* Support Section */}
                  <section>
                    <h4 className="text-xs font-bold tracking-widest mb-3 opacity-40 uppercase" style={{ color: isDark ? 'white' : 'black' }}>Support & Community</h4>
                    <div 
                      className="rounded-xl overflow-hidden border flex flex-col transition-colors duration-300"
                      style={{ 
                        backgroundColor: isDark ? 'rgba(255,255,255,0.02)' : 'rgba(255,255,255,0.5)',
                        borderColor: isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' 
                      }}
                    >
                      <div className={`px-5 py-4 flex items-center justify-between border-b ${isDark ? 'border-white/5' : 'border-black/5'}`}>
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={isDark ? "text-zinc-400" : "text-zinc-600"}><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>What's New</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium" style={{ color: activeTheme.accent }}>Changelog</span>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-30" style={{ color: isDark ? 'white' : 'black' }}><path d="m9 18 6-6-6-6"/></svg>
                        </div>
                      </div>

                      <div className="px-5 py-4 flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${isDark ? 'bg-white/5' : 'bg-black/5'}`}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={isDark ? "text-zinc-400" : "text-zinc-600"}><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                          </div>
                          <span className={`text-sm font-semibold ${isDark ? "text-zinc-200" : "text-zinc-800"}`}>Feedback</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium" style={{ color: activeTheme.accent }}>Send feedback</span>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-30" style={{ color: isDark ? 'white' : 'black' }}><path d="m9 18 6-6-6-6"/></svg>
                        </div>
                      </div>
                    </div>
                  </section>
                </div>
              </div>

              {/* Floating Timer */}
              <div className="absolute bottom-6 right-6 flex items-center gap-3 px-4 py-2 rounded-full border shadow-lg z-20 backdrop-blur-md"
                style={{ 
                  backgroundColor: isDark ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.8)',
                  borderColor: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'
                }}
              >
                <div className="w-4 h-4 rounded-full border-2" style={{ borderTopColor: activeTheme.accent, borderBottomColor: activeTheme.accent, borderLeftColor: activeTheme.accent, borderRightColor: 'transparent', transform: 'rotate(-45deg)' }}></div>
                <span className={`text-sm font-bold tracking-widest ${isDark ? "text-white" : "text-black"}`}>25:00</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
