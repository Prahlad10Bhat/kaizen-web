"use client";

import { useEffect, useState } from "react";
import { Download, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={`fixed top-0 left-0 w-full z-50 transition-all duration-500 ${
        scrolled
          ? "bg-kaizen-surface/60 backdrop-blur-xl border-b border-kaizen-border shadow-lg shadow-black/20"
          : "bg-transparent border-b border-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 h-16 md:h-20 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <img src="/images/logo.png" alt="Kaizen Logo" className="w-8 h-8 object-contain" />
          <span className="font-bold text-lg tracking-tight">
            Kaizen
          </span>
        </div>

        <div className="hidden md:flex items-center gap-8">
          {["Features", "Themes", "Integrations", "Changelog", "GitHub"].map((item) => (
            <a
              key={item}
              href="#"
              className="text-sm font-medium text-zinc-400 hover:text-white transition-colors"
            >
              {item}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-4">
          <button className="px-5 py-2.5 rounded-full bg-kaizen-purple text-white text-sm font-medium hover:bg-kaizen-purple-light transition-colors flex items-center gap-2 shadow-[0_0_20px_rgba(99,102,241,0.3)]">
            Download for Windows
            <Download className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
}