import React from 'react';
import { 
  Bot, 
  Cpu, 
  RefreshCw, 
  Trash2, 
  Layers, 
  PlayCircle,
  HelpCircle,
  CheckCircle2,
  AlertTriangle
} from 'lucide-react';
import { BridgeStatus } from '../types';

interface HeaderProps {
  bridgeStatus: BridgeStatus;
  isSimulating: boolean;
  onToggleSimulate: () => void;
  onOpenSetup: () => void;
  onReset: () => void;
  onRefresh: () => void;
  isRefreshing: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  bridgeStatus,
  isSimulating,
  onToggleSimulate,
  onOpenSetup,
  onReset,
  onRefresh,
  isRefreshing,
}) => {
  return (
    <header className="bg-slate-900/90 backdrop-blur border-b border-slate-800 sticky top-0 z-30 px-4 py-3">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
        {/* Brand & Identity */}
        <div className="flex items-center gap-3 w-full md:w-auto justify-between md:justify-start">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-red-500 via-rose-600 to-amber-500 p-0.5 shadow-lg shadow-red-500/20 flex items-center justify-center">
              <div className="w-full h-full bg-slate-950 rounded-[10px] flex items-center justify-center">
                <Layers className="w-5 h-5 text-rose-400" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-base font-bold text-white tracking-tight flex items-center gap-1.5">
                  Roblox Studio <span className="text-rose-400">MCP Autonomous Bridge</span>
                </h1>
                <span className="text-[10px] px-1.5 py-0.5 rounded bg-rose-500/10 text-rose-300 border border-rose-500/20 font-mono font-medium">
                  v2.5 AI
                </span>
              </div>
              <p className="text-xs text-slate-400 hidden sm:block">
                Gemini Autonomous Game Architect &bull; Live mcpsuperassistant Relay
              </p>
            </div>
          </div>

          <div className="flex md:hidden items-center gap-2">
            <button
              onClick={onOpenSetup}
              className="px-2.5 py-1 text-xs rounded-lg bg-rose-500/10 text-rose-300 border border-rose-500/30 flex items-center gap-1.5"
            >
              <HelpCircle className="w-3.5 h-3.5" />
              Setup
            </button>
          </div>
        </div>

        {/* Status Indicators & Control Toolbar */}
        <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto justify-end">
          {/* Bridge Status Pill */}
          <div 
            onClick={onOpenSetup}
            className={`cursor-pointer px-3 py-1.5 rounded-lg border text-xs font-medium flex items-center gap-2 transition-all ${
              bridgeStatus.connected
                ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300 hover:bg-emerald-500/20'
                : isSimulating
                ? 'bg-blue-500/10 border-blue-500/30 text-blue-300 hover:bg-blue-500/20'
                : 'bg-amber-500/10 border-amber-500/30 text-amber-300 hover:bg-amber-500/20'
            }`}
          >
            <div className="relative flex items-center justify-center">
              <span className={`w-2 h-2 rounded-full ${
                bridgeStatus.connected ? 'bg-emerald-400 animate-ping absolute' : ''
              }`} />
              <span className={`w-2 h-2 rounded-full ${
                bridgeStatus.connected ? 'bg-emerald-400' : isSimulating ? 'bg-blue-400' : 'bg-amber-400'
              }`} />
            </div>

            <span>
              {bridgeStatus.connected 
                ? `Roblox Connected (${bridgeStatus.agentName || 'Bridge'})`
                : isSimulating 
                ? 'Roblox Ready (Fallback On)'
                : 'Awaiting Roblox Studio'
              }
            </span>
          </div>

          {/* Mode Switcher */}
          <button
            onClick={onToggleSimulate}
            title={isSimulating ? "Strict Live Studio execution only" : "Enable fallback simulation if Studio is paused"}
            className={`px-3 py-1.5 rounded-lg border text-xs font-medium flex items-center gap-1.5 transition-all ${
              !isSimulating
                ? 'bg-emerald-600 text-white border-emerald-500 shadow-md shadow-emerald-600/20'
                : 'bg-slate-800 hover:bg-slate-700 text-slate-300 border-slate-700'
            }`}
          >
            <PlayCircle className="w-3.5 h-3.5" />
            {!isSimulating ? 'Live Studio Engine' : 'Studio + Fallback'}
          </button>

          {/* Setup Guide Button */}
          <button
            onClick={onOpenSetup}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-medium flex items-center gap-1.5 transition-all"
          >
            <HelpCircle className="w-3.5 h-3.5 text-rose-400" />
            <span className="hidden sm:inline">Connect</span> Guide
          </button>

          {/* Refresh State */}
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            title="Refresh State from Bridge"
            className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 transition-all disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
          </button>

          {/* Reset Queue */}
          <button
            onClick={onReset}
            title="Clear Queue & Reset DataModel"
            className="p-2 rounded-lg bg-slate-800/80 hover:bg-red-500/20 text-slate-400 hover:text-red-400 border border-slate-700 hover:border-red-500/30 transition-all"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </header>
  );
};
