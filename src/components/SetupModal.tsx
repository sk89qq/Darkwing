import React, { useState, useEffect } from 'react';
import { 
  X, 
  Copy, 
  Check, 
  Terminal, 
  Plug, 
  Layers, 
  Cpu, 
  HelpCircle, 
  ExternalLink,
  ShieldCheck,
  CheckCircle2,
  Sparkles,
  RotateCw
} from 'lucide-react';

interface SetupModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SetupModal: React.FC<SetupModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<'plugin' | 'node' | 'python'>('plugin');
  const [copied, setCopied] = useState<string | null>(null);
  const [scripts, setScripts] = useState<{
    cloudUrl?: string;
    nodeBridgeScript?: string;
    pythonBridgeScript?: string;
    robloxStudioPluginLuau?: string;
  }>({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setLoading(true);
      fetch('/api/bridge/scripts')
        .then(res => res.json())
        .then(data => {
          setScripts(data);
          setLoading(false);
        })
        .catch(err => {
          console.error('Failed to load bridge scripts:', err);
          setLoading(false);
        });
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleCopy = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopied(id);
    setTimeout(() => setCopied(null), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Modal Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400">
              <Plug className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-semibold text-white">
                Roblox Studio Connection &amp; Bridge Setup
              </h3>
              <p className="text-xs text-slate-400">
                Connect your live Roblox Studio place to this autonomous AI engine
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center gap-2 p-3 bg-slate-950/40 border-b border-slate-800">
          <button
            onClick={() => setActiveTab('plugin')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
              activeTab === 'plugin'
                ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            Method 1: Direct Studio Luau Plugin (Recommended)
          </button>

          <button
            onClick={() => setActiveTab('node')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
              activeTab === 'node'
                ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Cpu className="w-3.5 h-3.5" />
            Method 2: Node.js Relay
          </button>

          <button
            onClick={() => setActiveTab('python')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
              activeTab === 'python'
                ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Terminal className="w-3.5 h-3.5" />
            Method 3: Python Runner
          </button>
        </div>

        {/* Modal Body */}
        <div className="flex-1 p-5 overflow-y-auto space-y-4">
          {activeTab === 'plugin' && (
            <div className="space-y-4">
              <div className="bg-rose-500/10 border border-rose-500/20 rounded-xl p-3.5 text-xs text-rose-200 leading-relaxed flex items-start gap-2.5">
                <ShieldCheck className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />
                <div>
                  <strong className="font-semibold block text-white mb-0.5">
                    Zero local installation required!
                  </strong>
                  This direct Luau script polls your AI Studio cloud instance via Roblox’s native <code className="bg-rose-950/60 px-1 py-0.5 rounded text-rose-300">HttpService</code> and builds instances in real time.
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="text-xs font-semibold text-slate-200 uppercase tracking-wide">
                  Step 1: Enable Http Requests in Roblox Studio
                </h4>
                <ol className="list-decimal list-inside text-xs text-slate-400 space-y-1 pl-1">
                  <li>In Roblox Studio, open <strong>Home &gt; Game Settings &gt; Security</strong>.</li>
                  <li>Toggle ON <strong>&quot;Allow HTTP Requests&quot;</strong>.</li>
                  <li>Click <strong>Save</strong>.</li>
                </ol>
              </div>

              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-semibold text-slate-200 uppercase tracking-wide">
                    Step 2: Run Plugin in Studio Command Bar
                  </h4>
                  <button
                    onClick={() => handleCopy(scripts.robloxStudioPluginLuau || '', 'plugin')}
                    className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium flex items-center gap-1 border border-slate-700 transition-colors"
                  >
                    {copied === 'plugin' ? (
                      <>
                        <Check className="w-3 h-3 text-emerald-400" />
                        <span className="text-emerald-400">Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3 h-3" />
                        <span>Copy Luau Script</span>
                      </>
                    )}
                  </button>
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3 font-mono text-xs text-slate-300 max-h-56 overflow-y-auto">
                  <pre className="whitespace-pre-wrap select-text">
                    {scripts.robloxStudioPluginLuau || '-- Loading script...'}
                  </pre>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'node' && (
            <div className="space-y-4">
              <div className="text-xs text-slate-300 leading-relaxed">
                Run this local Node.js relay on your computer to bridge local MCP server or plugins with AI Studio.
              </div>

              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-200 font-mono">
                    roblox_mcp_bridge.js
                  </span>
                  <button
                    onClick={() => handleCopy(scripts.nodeBridgeScript || '', 'node')}
                    className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium flex items-center gap-1 border border-slate-700 transition-colors"
                  >
                    {copied === 'node' ? (
                      <>
                        <Check className="w-3 h-3 text-emerald-400" />
                        <span className="text-emerald-400">Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3 h-3" />
                        <span>Copy Script</span>
                      </>
                    )}
                  </button>
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3 font-mono text-xs text-slate-300 max-h-56 overflow-y-auto">
                  <pre className="whitespace-pre-wrap select-text">
                    {scripts.nodeBridgeScript || '// Loading...'}
                  </pre>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'python' && (
            <div className="space-y-4">
              <div className="text-xs text-slate-300 leading-relaxed">
                Run this lightweight Python runner to bridge local Roblox Studio instances with AI Studio.
              </div>

              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-200 font-mono">
                    roblox_mcp_bridge.py
                  </span>
                  <button
                    onClick={() => handleCopy(scripts.pythonBridgeScript || '', 'python')}
                    className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium flex items-center gap-1 border border-slate-700 transition-colors"
                  >
                    {copied === 'python' ? (
                      <>
                        <Check className="w-3 h-3 text-emerald-400" />
                        <span className="text-emerald-400">Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3 h-3" />
                        <span>Copy Script</span>
                      </>
                    )}
                  </button>
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3 font-mono text-xs text-slate-300 max-h-56 overflow-y-auto">
                  <pre className="whitespace-pre-wrap select-text">
                    {scripts.pythonBridgeScript || '# Loading...'}
                  </pre>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-4 bg-slate-950/80 border-t border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span>Studio will automatically synchronize upon connection</span>
          </div>

          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium transition-colors"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
};
