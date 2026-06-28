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
          className="py-32 relative overflow-hidden bg-[#050505] flex flex-col items-center"
        >
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] bg-kaizen-purple/10 blur-[150px] rounded-full pointer-events-none" />
          
          <div className="relative z-10 flex flex-col sm:flex-row items-center gap-6 mb-12">
            <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-white">
              Ready to upgrade your productivity?
            </h2>
            
            <a
              href={downloadUrl}
              className="px-6 py-3 rounded-full bg-kaizen-purple text-white font-semibold text-sm hover:bg-kaizen-purple-light transition-colors flex items-center gap-2 shadow-[0_0_20px_rgba(99,102,241,0.3)]"
            >
              Get Kaizen for Windows
              <Download className="w-4 h-4" />
            </a>
          </div>

        </motion.section>

        <Footer />
      </div>
    </main>
  );
}