"use client";

import Navbar from "@/components/navbar";
import Hero from "@/components/hero";
import ProductOverview from "@/components/product-overview";
import InteractiveShowcase from "@/components/interactive-showcase";
import ThemeShowcase from "@/components/theme-showcase";
import AIShowcase from "@/components/ai-showcase";
import Philosophy from "@/components/philosophy";
import Footer from "@/components/footer";
import { Download } from "lucide-react";
import { useLatestRelease } from "@/hooks/use-latest-release";

export default function Home() {
  const { downloadUrl } = useLatestRelease();
  return (
    <main className="bg-kaizen-bg text-white min-h-screen relative">
      {/* Background Grid Pattern */}
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      
      {/* Interactive mouse spotlight (simulated via radial gradient) */}
      <div className="fixed inset-0 pointer-events-none z-0 bg-[radial-gradient(ellipse_800px_800px_at_50%_-20%,rgba(108,99,255,0.12),transparent)] mix-blend-screen"></div>

      <div className="relative z-10">
        <Navbar />
        <Hero />
        <ProductOverview />
        <InteractiveShowcase />
        <ThemeShowcase />
        <AIShowcase />
        <Philosophy />
        
        {/* Final CTA Section */}
        <section className="py-32 relative overflow-hidden bg-[#050505] flex flex-col items-center">
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

          <div className="relative z-10 flex items-center gap-4 text-xs font-medium text-zinc-500 border border-white/10 rounded-full px-6 py-2 bg-white/5">
            <span>v1.0.0</span>
            <div className="w-1 h-1 rounded-full bg-zinc-700"></div>
            <span>100% Free</span>
            <div className="w-1 h-1 rounded-full bg-zinc-700"></div>
            <span>Open Source</span>
          </div>
        </section>

        <Footer />
      </div>
    </main>
  );
}