"use client";

import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { motion, AnimatePresence } from "framer-motion";
import { X, Download } from "lucide-react";
import { FaWindows, FaAndroid, FaApple } from "react-icons/fa";
import { useLatestRelease } from "@/hooks/use-latest-release";

interface DownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function DownloadModal({ isOpen, onClose }: DownloadModalProps) {
  const { downloadUrl } = useLatestRelease();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          />
          
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="relative w-full max-w-md bg-kaizen-surface border border-white/10 rounded-2xl shadow-2xl overflow-hidden"
          >
            <div className="p-6 border-b border-white/10 flex justify-between items-center">
              <h2 className="text-xl font-bold">Download Kaizen</h2>
              <button
                onClick={onClose}
                className="p-2 rounded-lg hover:bg-white/5 transition-colors text-zinc-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* Windows */}
              <a
                href={downloadUrl}
                onClick={onClose}
                className="flex items-center justify-between w-full p-4 rounded-xl border border-kaizen-purple/30 bg-kaizen-purple/10 hover:bg-kaizen-purple/20 transition-colors group cursor-pointer"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-kaizen-purple/20 flex items-center justify-center text-kaizen-purple-light">
                    <FaWindows className="w-5 h-5" />
                  </div>
                  <div className="text-left">
                    <div className="font-semibold text-white">Windows</div>
                    <div className="text-sm text-zinc-400">Download for Windows 10/11</div>
                  </div>
                </div>
                <Download className="w-5 h-5 text-kaizen-purple-light opacity-0 group-hover:opacity-100 transition-opacity -translate-x-2 group-hover:translate-x-0 duration-300" />
              </a>

              {/* Mac */}
              <div className="flex items-center justify-between w-full p-4 rounded-xl border border-white/5 bg-white/5 opacity-50 cursor-not-allowed">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center text-zinc-400">
                    <FaApple className="w-5 h-5" />
                  </div>
                  <div className="text-left">
                    <div className="font-semibold text-white">Mac & iOS</div>
                    <div className="text-sm text-zinc-400">Coming soon</div>
                  </div>
                </div>
              </div>

              {/* Android */}
              <div className="flex items-center justify-between w-full p-4 rounded-xl border border-white/5 bg-white/5 opacity-50 cursor-not-allowed">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center text-zinc-400">
                    <FaAndroid className="w-5 h-5" />
                  </div>
                  <div className="text-left">
                    <div className="font-semibold text-white">Android</div>
                    <div className="text-sm text-zinc-400">Coming soon</div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body
  );
}
