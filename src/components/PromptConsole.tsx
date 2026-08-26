import React, { useState } from 'react';
import { 
  Sparkles, 
  Send, 
  Bot, 
  Zap, 
  Layers, 
  RotateCw, 
  Shield, 
  Flame, 
  Compass, 
  Cpu 
} from 'lucide-react';

interface PromptConsoleProps {
  onGeneratePlan: (prompt: string, autonomous: boolean) => Promise<void>;
  isLoading: boolean;
  totalPendingActions: number;
}

const PRESET_IDEAS = [
  {
    label: '🚀 VOIDA Modular Ship & Flight Core',
    prompt: 'Create a Modular Ship Flight and Power Grid Controller in ServerScriptService that routes reactor power from PelicanCore to thrusters, shields, and turrets with realistic space inertia and damping.',
  },
  {
    label: '🎯 Plasma Turret Auto-Aim & Ballistics',
    prompt: 'Implement an autonomous Plasma Turret targeting system in Workspace that rotates towards enemies in Workspace.Enemies, calculates leading targets based on velocity, and fires plasma bolts.',
  },
  {
    label: '⛏️ Asteroid Mining & Salvage System',
    prompt: 'Build an Asteroid Mining Laser mechanic where beams hit Workspace.Asteroids, shatter them with health degradation, and spawn collectible salvage scrap into Workspace.DroppedParts.',
  },
  {
    label: '🪙 Leaderstats & Player DataStore',
    prompt: 'Generate a complete Player DataStore leaderstats system with Coins and Level saving via DataStoreService, plus animated rotating gold coins in Workspace that give +10 coins on touch.',
  },
];

export const PromptConsole: React.FC<PromptConsoleProps> = ({
  onGeneratePlan,
  isLoading,
  totalPendingActions,
}) => {
  const [prompt, setPrompt] = useState('');
  const [autonomous, setAutonomous] = useState(true);

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!prompt.trim() || isLoading) return;
    await onGeneratePlan(prompt, autonomous);
  };

  const handleSelectPreset = (presetPrompt: string) => {
    setPrompt(presetPrompt);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40 relative overflow-hidden">
      {/* Decorative Glow */}
      <div className="absolute -top-16 -right-16 w-48 h-48 bg-rose-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mb-4">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400">
            <Sparkles className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm font-semibold text-white tracking-tight flex items-center gap-2">
              Gemini AI Autonomous Game Architect
            </h2>
            <p className="text-xs text-slate-400">
              Describe systems, mechanics, or UI — Gemini generates DataModel instances and complete Luau scripts
            </p>
          </div>
        </div>

        {totalPendingActions > 0 && (
          <div className="flex items-center gap-2 px-3 py-1 rounded-lg bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs font-mono">
            <Zap className="w-3.5 h-3.5 animate-pulse" />
            <span>{totalPendingActions} Pending Studio Actions</span>
          </div>
        )}
      </div>

      {/* Input Form */}
      <form onSubmit={handleSubmit} className="space-y-3">
        <div className="relative">
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="e.g., Create a VOIDA modular spaceship energy routing system and auto-targeting plasma turrets..."
            rows={3}
            disabled={isLoading}
            className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all resize-none leading-relaxed"
          />
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 pt-1">
          {/* Preset Quick Chips */}
          <div className="flex flex-wrap items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
            {PRESET_IDEAS.map((preset, idx) => (
              <button
                key={idx}
                type="button"
                onClick={() => handleSelectPreset(preset.prompt)}
                className="px-2.5 py-1 rounded-lg bg-slate-800/80 hover:bg-slate-700 text-slate-300 text-[11px] font-medium border border-slate-700/80 transition-colors whitespace-nowrap"
              >
                {preset.label}
              </button>
            ))}
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-2 self-end sm:self-auto">
            <label className="flex items-center gap-2 text-xs text-slate-400 cursor-pointer select-none px-2 py-1">
              <input
                type="checkbox"
                checked={autonomous}
                onChange={(e) => setAutonomous(e.target.checked)}
                className="w-3.5 h-3.5 rounded bg-slate-950 border-slate-700 text-rose-600 focus:ring-rose-500 focus:ring-offset-slate-900"
              />
              <span>Auto-Execute</span>
            </label>

            <button
              type="submit"
              disabled={isLoading || !prompt.trim()}
              className="px-4 py-2 rounded-lg bg-gradient-to-r from-rose-600 via-rose-500 to-red-600 hover:from-rose-500 hover:to-red-500 text-white text-xs font-semibold flex items-center gap-2 shadow-lg shadow-rose-600/30 transition-all disabled:opacity-50"
            >
              {isLoading ? (
                <>
                  <RotateCw className="w-3.5 h-3.5 animate-spin" />
                  <span>Synthesizing Architecture...</span>
                </>
              ) : (
                <>
                  <Send className="w-3.5 h-3.5" />
                  <span>Generate &amp; Dispatch</span>
                </>
              )}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
};
