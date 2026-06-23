"use client";

import Navbar from "@/components/navbar";
import Footer from "@/components/footer";

export default function PrivacyPolicy() {
  return (
    <main className="bg-[#050505] text-white min-h-screen relative">
      {/* Background Grid Pattern */}
      <div className="fixed inset-0 pointer-events-none z-0 opacity-[0.15] bg-grid-white mix-blend-screen"></div>
      
      <div className="relative z-10 flex flex-col min-h-screen">
        <Navbar />
        
        <div className="flex-grow pt-32 pb-24 px-6 max-w-[800px] mx-auto w-full">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-4">Privacy comes first.</h1>
          <p className="text-xl text-zinc-400 mb-16">Kaizen is built around a simple principle: your data belongs to you.</p>

          <div className="space-y-12">
            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">What Gets Stored</h2>
              <ul className="list-disc pl-5 text-zinc-400 space-y-2">
                <li>Tasks</li>
                <li>Notes</li>
                <li>Habits</li>
                <li>Workouts</li>
                <li>Calendar entries</li>
                <li>App settings</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Local Storage</h2>
              <ul className="list-disc pl-5 text-zinc-400 space-y-2">
                <li>Data is stored locally on the user's device.</li>
                <li>Kaizen does not upload personal data to company servers.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Tracking & Analytics</h2>
              <ul className="list-disc pl-5 text-zinc-400 space-y-2">
                <li>No tracking.</li>
                <li>No advertising identifiers.</li>
                <li>No selling of user data.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Backups</h2>
              <ul className="list-disc pl-5 text-zinc-400 space-y-2">
                <li>Users can export and import their own data.</li>
                <li>Backup files remain under user control.</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Future Integrations</h2>
              <p className="text-zinc-400">Any future third-party integrations will be clearly disclosed before use.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4 text-white">Policy Updates</h2>
              <p className="text-zinc-400">Privacy policies may be updated as features evolve.</p>
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
