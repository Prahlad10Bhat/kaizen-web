"use client";

import { useEffect, useState } from "react";
import { Download, ChevronRight } from "lucide-react";
import { motion } from "framer-motion";
import { DownloadModal } from "./download-modal";
import { FaWindows, FaAndroid, FaApple } from "react-icons/fa";

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);

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
        <a href="/" className="flex items-center gap-3 hover:opacity-90 transition-opacity">
          <img src="/images/logo.png" alt="Kaizen Logo" className="w-12 h-12 object-contain" />
          <span className="font-bold text-2xl tracking-tight">
            Kaizen
          </span>
        </a>

        <div className="hidden md:flex items-center gap-8">
          {[
            { name: "Why Kaizen", href: "/#why-kaizen" },
            { name: "Features", href: "/#features" },
            { name: "Themes", href: "/#themes" },
            { name: "Privacy", href: "/#privacy" }
          ].map((item) => (
            <a
              key={item.name}
              href={item.href}
              className="text-sm font-medium text-zinc-400 hover:text-white transition-colors"
            >
              {item.name}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-4">
          <button
            onClick={() => setIsModalOpen(true)}
            className="px-5 py-2.5 rounded-full bg-kaizen-purple text-white text-sm font-medium hover:bg-kaizen-purple-light transition-colors flex items-center gap-3 shadow-[0_0_20px_rgba(99,102,241,0.3)] cursor-pointer"
          >
            <span className="flex items-center">
              Download for
              <span className="flex items-center gap-1.5 ml-3 text-lg">
                <FaWindows title="Windows" />
                <FaAndroid title="Android (Coming Soon)" className="opacity-40" />
                <FaApple title="Mac/iOS (Coming Soon)" className="opacity-40" />
              </span>
            </span>
            <Download className="w-4 h-4 ml-1" />
          </button>
        </div>
      </div>
      <DownloadModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </header>
  );
}