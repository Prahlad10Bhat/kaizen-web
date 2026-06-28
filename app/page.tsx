"use client";

import Navbar from "@/components/navbar";
import Hero from "@/components/hero";
import ProductOverview from "@/components/product-overview";
import InteractiveShowcase from "@/components/interactive-showcase";
import ThemeShowcase from "@/components/theme-showcase";
import PrivacyShowcase from "@/components/privacy-showcase";
import Philosophy from "@/components/philosophy";
import Footer from "@/components/footer";
import { Download } from "lucide-react";
import { useLatestRelease } from "@/hooks/use-latest-release";

import { motion } from "framer-motion";

export default function Home() {
  const { downloadUrl } = useLatestRelease();

  const fadeUpProps: any = {
    initial: { opacity: 0, y: 40 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true, margin: "-100px" },
    transition: { duration: 0.8, ease: "easeOut" }
  };

  return (
    <main className="bg-kaizen-bg text-white min-h-screen relative">
      {/* Background Grid Pattern */}
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      
      {/* Interactive mouse spotlight (simulated via radial gradient) */}
      <div className="fixed inset-0 pointer-events-none z-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_-20%,rgba(108,99,255,0.12),transparent)] mix-blend-screen"></div>

      <div className="relative z-10">
        <Navbar />
        <Hero />
        
        <motion.div {...fadeUpProps}>
          <ProductOverview />
        </motion.div>
        
        <motion.div {...fadeUpProps}>
          <InteractiveShowcase />
        </motion.div>
        
        {/* Kept static as requested */}
        <ThemeShowcase />
        
        <motion.div {...fadeUpProps}>
          <PrivacyShowcase />
        </motion.div>
        
        <motion.div {...fadeUpProps}>
          <Philosophy />
        </motion.div>
        
        {/* Final CTA Section */}
        <motion.section 
          {...fadeUpProps}
          className="py-16 md:py-24 relative overflow-hidden bg-[#050505] flex flex-col items-center px-4 text-center sm:text-left"
        >
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] bg-kaizen-purple/10 blur-[150px] rounded-full pointer-events-none" />
          
          <div className="relative z-10 flex flex-col sm:flex-row items-center justify-center gap-6 md:gap-8">
            <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-white text-center sm:text-left">
              Ready to upgrade your productivity?
            </h2>
            
            <a
              href={downloadUrl}
              className="px-8 py-3.5 rounded-full bg-kaizen-purple text-white text-sm hover:bg-kaizen-purple-light transition-colors flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(99,102,241,0.3)] shrink-0"
            >
              <span className="font-light opacity-90">Download for</span>
              <div className="flex items-center gap-1.5 font-semibold">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M0 3.449L9.75 2.1v9.131H0V3.449zm10.95-1.57L24 0v11.08H10.95V1.88zm0 10.375H24V24l-13.05-1.854V12.254zm-1.2 0H0v8.925l9.75-1.378V12.255z" />
                </svg>
                Windows
              </div>
            </a>
          </div>
        </motion.section>

        <Footer />
      </div>
    </main>
  );
}