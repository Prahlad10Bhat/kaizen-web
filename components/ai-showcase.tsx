"use client";

import { motion } from "framer-motion";
import { Sparkles, ArrowRight, BrainCircuit } from "lucide-react";

export default function AIShowcase() {
  return (
    <section className="py-32 relative overflow-hidden bg-black">
      <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-kaizen-purple/30 to-transparent"></div>
      
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-kaizen-purple/10 blur-[150px] rounded-full pointer-events-none" />
      
      <div className="max-w-7xl mx-auto px-6 relative z-10 flex flex-col lg:flex-row items-center gap-16">
        <div className="w-full lg:w-1/2">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-kaizen-purple/10 border border-kaizen-purple/20 text-kaizen-purple-light text-sm font-medium mb-6"
          >
            <Sparkles className="w-4 h-4" />
            Kaizen Intelligence
          </motion.div>
          
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6 text-white leading-tight"
          >
            Your personal <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-kaizen-purple-light to-kaizen-purple">
              chief of staff.
            </span>
          </motion.h2>
          
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-lg text-zinc-400 mb-8 leading-relaxed max-w-lg"
          >
            Stop wasting time organizing. Kaizen's AI automatically categorizes tasks, extracts action items from notes, and protects your focus time based on your peak productivity hours.
          </motion.p>
          
          <motion.ul
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.3 }}
            className="space-y-4 mb-10"
          >
            {[
              "Auto-prioritize tasks based on deadlines",
              "Smart scheduling finds deep work blocks",
              "Natural language task creation",
            ].map((feature, i) => (
              <li key={i} className="flex items-center gap-3 text-zinc-300">
                <div className="w-6 h-6 rounded-full bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                  <CheckIcon className="w-3 h-3 text-kaizen-purple-light" />
                </div>
                {feature}
              </li>
            ))}
          </motion.ul>
        </div>
        
        <div className="w-full lg:w-1/2">
          <motion.div
            initial={{ opacity: 0, scale: 0.9, rotateY: -10 }}
            whileInView={{ opacity: 1, scale: 1, rotateY: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
            className="relative perspective-1000"
          >
            <div className="relative rounded-[2rem] border border-white/10 bg-kaizen-surface/40 backdrop-blur-3xl shadow-[0_0_80px_rgba(108,99,255,0.15)] overflow-hidden ring-1 ring-white/10 p-8 flex flex-col gap-6">
              
              {/* Chat bubble 1 */}
              <div className="self-end max-w-[80%] bg-white/5 border border-white/10 p-4 rounded-2xl rounded-tr-sm">
                <p className="text-sm text-zinc-300">Schedule 2 hours of deep work for the marketing proposal tomorrow.</p>
              </div>

              {/* AI Processing state */}
              <div className="flex items-center gap-3 text-kaizen-purple-light text-sm font-medium animate-pulse">
                <BrainCircuit className="w-5 h-5" />
                Analyzing schedule...
              </div>

              {/* Chat bubble 2 (AI Response) */}
              <div className="self-start max-w-[90%] bg-kaizen-purple/10 border border-kaizen-purple/20 p-5 rounded-2xl rounded-tl-sm relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-kaizen-purple/50 to-transparent"></div>
                <p className="text-sm text-zinc-200 mb-4">Found a perfect block. I've scheduled it and moved your 1:1 to Thursday.</p>
                
                <div className="bg-black/40 rounded-xl p-3 border border-white/5 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-kaizen-purple/20 flex flex-col items-center justify-center border border-kaizen-purple/30">
                      <span className="text-[10px] uppercase text-kaizen-purple-light font-bold">Wed</span>
                      <span className="text-sm font-bold text-white leading-none">14</span>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-white">Marketing Proposal</div>
                      <div className="text-xs text-zinc-500">9:00 AM - 11:00 AM</div>
                    </div>
                  </div>
                  <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center">
                    <CheckIcon className="w-4 h-4 text-white" />
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function CheckIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
