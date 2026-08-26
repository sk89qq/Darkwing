import React, { useState } from 'react';
import { 
  Terminal, 
  Play, 
  Send, 
  Copy, 
  Check, 
  Code2, 
  Zap, 
  Trash2, 
  Sparkles,
  RotateCw
} from 'lucide-react';

interface LuauScratchpadProps {
  onExecuteCode: (code: string) => Promise<void>;
  isLoading: boolean;
}

export const LuauScratchpad: React.FC<LuauScratchpadProps> = ({
  onExecuteCode,
  isLoading,
}) => {
  const [code, setCode] = useState<string>(`-- Live Luau Command / Script Execution
-- Runs in Roblox Studio Command Bar or DataModel
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("⚡ Hello from AI Studio Autonomous Bridge!")
print("Connected Players: " .. #Players:GetPlayers())
`);
  const [copied, setCopied] = useState(false);

  const handleRun = async () => {
    if (!code.trim() || isLoading) return;
    await onExecuteCode(code);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40 flex flex-col">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Code2 className="w-4 h-4 text-rose-400" />
          <h3 className="text-sm font-semibold text-white">
            Luau Command Bar &amp; Direct Script Runner
          </h3>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleCopy}
            className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium flex items-center gap-1 border border-slate-700 transition-colors"
          >
            {copied ? (
              <>
                <Check className="w-3 h-3 text-emerald-400" />
                <span className="text-emerald-400">Copied</span>
              </>
            ) : (
              <>
                <Copy className="w-3 h-3" />
                <span>Copy</span>
              </>
            )}
          </button>

          <button
            onClick={() => setCode('')}
            className="p-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700 transition-colors"
            title="Clear Code"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      <div className="relative flex-1">
        <textarea
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="-- Write custom Luau code to dispatch to Roblox Studio..."
          rows={6}
          disabled={isLoading}
          className="w-full bg-slate-950/90 border border-slate-800 rounded-xl p-3.5 text-xs font-mono text-slate-100 placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-rose-500/50 focus:border-rose-500 transition-all resize-none leading-relaxed"
        />
      </div>

      <div className="mt-3 flex items-center justify-between">
        <span className="text-[11px] text-slate-400 font-mono">
          Language: <strong className="text-rose-400">Luau (Roblox Studio)</strong>
        </span>

        <button
          onClick={handleRun}
          disabled={isLoading || !code.trim()}
          className="px-4 py-2 rounded-lg bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white text-xs font-semibold flex items-center gap-2 shadow-lg shadow-rose-600/30 transition-all disabled:opacity-50"
        >
          {isLoading ? (
            <>
              <RotateCw className="w-3.5 h-3.5 animate-spin" />
              <span>Sending to Studio...</span>
            </>
          ) : (
            <>
              <Play className="w-3.5 h-3.5 fill-white" />
              <span>Execute in Roblox Studio</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};
