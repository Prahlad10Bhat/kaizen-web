"use client";

import { useState } from "react";
import { ArrowUp } from "lucide-react";
import { useLatestRelease } from "@/hooks/use-latest-release";
import { DownloadModal } from "./download-modal";

export default function Footer() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { downloadUrl } = useLatestRelease();
  return (
    <footer className="bg-[#050505] pt-16 md:pt-24 pb-8 md:pb-12 border-t border-white/5 relative overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-[1px] bg-gradient-to-r from-transparent via-kaizen-purple/50 to-transparent opacity-50"></div>
      
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-y-12 sm:gap-x-8 lg:gap-8 mb-16">
          <div className="col-span-1 sm:col-span-2">
            <a href="/" className="flex items-center gap-3 mb-6 hover:opacity-90 transition-opacity">
              <img src="/images/logo.png" alt="Kaizen Logo" className="w-12 h-12 object-contain" />
              <span className="font-bold text-2xl tracking-tight text-white">Kaizen</span>
            </a>
            <p className="text-zinc-400 max-w-sm mb-6 leading-relaxed">
              One place for your tasks, notes, habits, workouts, and focus sessions. Built to help you make progress every day.
            </p>
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/10 transition-colors cursor-pointer">
                <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
                  <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
                </svg>
              </div>
            </div>
          </div>

          <div>
            <h4 className="font-semibold text-white mb-6">Product</h4>
            <ul className="space-y-4">
              {[
                { name: "Why Kaizen", href: "/#why-kaizen" },
                { name: "Features", href: "/#features" },
                { name: "Themes", href: "/#themes" },
              ].map((item) => (
                <li key={item.name}>
                  <a href={item.href} className="text-zinc-500 hover:text-white transition-colors text-sm">
                    {item.name}
                  </a>
                </li>
              ))}
              <li>
                <button onClick={() => setIsModalOpen(true)} className="text-zinc-500 hover:text-white transition-colors text-sm cursor-pointer">
                  Download
                </button>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-white mb-6">Resources</h4>
            <ul className="space-y-4">
              {[
                { name: "GitHub", href: "https://github.com/Prahlad10Bhat/Kaizen" },
                { name: "Feedback", href: "/feedback" }
              ].map((item) => (
                <li key={item.name}>
                  <a href={item.href} target={item.name === "GitHub" ? "_blank" : undefined} rel={item.name === "GitHub" ? "noopener noreferrer" : undefined} className="text-zinc-500 hover:text-white transition-colors text-sm">
                    {item.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-white mb-6">Legal</h4>
            <ul className="space-y-4">
              {[
                { name: "Data & Privacy", href: "/data" },
                { name: "Privacy Policy", href: "/privacy" },
                { name: "Terms of Service", href: "/terms" },
              ].map((item) => (
                <li key={item.name}>
                  <a href={item.href} className="text-zinc-500 hover:text-white transition-colors text-sm">
                    {item.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-white/5 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-zinc-600 text-sm">
            Kaizen © 2026
          </p>
          <button 
            onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
            className="flex items-center gap-2 text-sm font-medium text-zinc-500 hover:text-white transition-colors cursor-pointer"
          >
            Back to top
            <ArrowUp className="w-4 h-4" />
          </button>
        </div>
      </div>
      <DownloadModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </footer>
  );
}
