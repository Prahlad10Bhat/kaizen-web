"use client";

import Navbar from "@/components/navbar";
import Footer from "@/components/footer";

export default function TermsOfService() {
  return (
    <main className="bg-[#050505] text-white min-h-screen relative">
      {/* Background Grid Pattern */}
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      
      <div className="relative z-10 flex flex-col min-h-screen">
        <Navbar />
        
        <div className="flex-grow pt-32 pb-24 px-6 max-w-[800px] mx-auto w-full">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-16">Simple terms. No surprises.</h1>

          <div className="space-y-12">
            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Acceptance</h2>
              <p className="text-zinc-400">Using Kaizen means accepting these terms.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">License</h2>
              <p className="text-zinc-400">Users are granted a license to use the software.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Ownership</h2>
              <p className="text-zinc-400">The Kaizen name, branding, and software remain property of Kaizen.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">User Responsibility</h2>
              <p className="text-zinc-400">Users are responsible for their own data and backups.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Availability</h2>
              <p className="text-zinc-400">Software is provided as-is.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Prohibited Uses</h2>
              <ul className="list-disc pl-5 text-zinc-400 space-y-2">
                <li>Illegal activities</li>
                <li>Unauthorized redistribution</li>
                <li>Abuse of paid features</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Limitation of Liability</h2>
              <p className="text-zinc-400">Kaizen is not responsible for data loss, damages, or compatibility issues.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Changes to Terms</h2>
              <p className="text-zinc-400">Terms may evolve over time.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Contact</h2>
              <p className="text-zinc-400">For questions, reach out to <a href="mailto:kaizenappsupport@gmail.com" className="text-kaizen-purple hover:underline">kaizenappsupport@gmail.com</a>.</p>
            </section>
          </div>
        </div>

        <Footer />
      </div>
    </main>
  );
}
