import React from 'react';
import { 
  RobloxAction 
} from '../types';
import { 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  RotateCw, 
  Code2, 
  Layers, 
  Play, 
  Sparkles, 
  Trash2, 
  ExternalLink,
  ChevronRight,
  ShieldAlert
} from 'lucide-react';

interface QueueTimelineProps {
  actions: RobloxAction[];
  isSimulating: boolean;
  onMockExecute: (actionId: string) => Promise<void>;
  onInspectCode: (action: RobloxAction) => void;
  onRetryAction: (actionId: string) => Promise<void>;
}

export const QueueTimeline: React.FC<QueueTimelineProps> = ({
  actions,
  isSimulating,
  onMockExecute,
  onInspectCode,
  onRetryAction,
}) => {
  if (actions.length === 0) {
    return (
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl shadow-black/40 text-center">
        <div className="w-12 h-12 rounded-2xl bg-slate-800/80 border border-slate-700 flex items-center justify-center mx-auto mb-3 text-slate-500">
          <Layers className="w-6 h-6" />
        </div>
        <h3 className="text-sm font-semibold text-slate-300 mb-1">
          Command &amp; Action Queue is Empty
        </h3>
        <p className="text-xs text-slate-500 max-w-md mx-auto">
          Type a request in the prompt console above to generate live Roblox Studio instances, Luau scripts, and systems.
        </p>
      </div>
    );
  }

  const successCount = actions.filter(a => a.status === 'success').length;
  const pendingCount = actions.filter(a => a.status === 'pending' || a.status === 'sent' || a.status === 'executing').length;
  const failedCount = actions.filter(a => a.status === 'failed').length;

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mb-4 pb-3 border-b border-slate-800">
        <div className="flex items-center gap-2">
          <Layers className="w-4 h-4 text-rose-400" />
          <h3 className="text-sm font-semibold text-white">
            Roblox Studio Command Execution Pipeline
          </h3>
          <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-300 font-mono border border-slate-700">
            {actions.length} Total
          </span>
        </div>

        {/* Stats */}
        <div className="flex items-center gap-2 text-xs font-mono">
          <span className="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-300 border border-emerald-500/20 flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3" /> {successCount} Deployed
          </span>
          {pendingCount > 0 && (
            <span className="px-2 py-0.5 rounded bg-amber-500/10 text-amber-300 border border-amber-500/20 flex items-center gap-1">
              <Clock className="w-3 h-3 animate-spin" /> {pendingCount} Queued
            </span>
          )}
          {failedCount > 0 && (
            <span className="px-2 py-0.5 rounded bg-red-500/10 text-red-300 border border-red-500/20 flex items-center gap-1">
              <AlertCircle className="w-3 h-3" /> {failedCount} Failed
            </span>
          )}
        </div>
      </div>

      {/* Action List */}
      <div className="space-y-2.5 max-h-[380px] overflow-y-auto pr-1">
        {actions.map((act, index) => {
          const isScript = act.className === 'Script' || act.className === 'LocalScript' || act.className === 'ModuleScript' || !!act.sourceCode;

          return (
            <div
              key={act.id || index}
              className={`p-3.5 rounded-xl border transition-all flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 ${
                act.status === 'success'
                  ? 'bg-slate-950/60 border-slate-800 hover:border-slate-700'
                  : act.status === 'failed'
                  ? 'bg-red-950/20 border-red-500/30'
                  : act.status === 'auto_fixing'
                  ? 'bg-purple-950/20 border-purple-500/30'
                  : 'bg-slate-950 border-rose-500/20'
              }`}
            >
              {/* Left Info */}
              <div className="flex items-start gap-3 flex-1 min-w-0">
                <div className="mt-0.5">
                  {act.status === 'success' && (
                    <div className="w-6 h-6 rounded-full bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                    </div>
                  )}
                  {act.status === 'pending' && (
                    <div className="w-6 h-6 rounded-full bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400">
                      <Clock className="w-3.5 h-3.5" />
                    </div>
                  )}
                  {(act.status === 'sent' || act.status === 'executing') && (
                    <div className="w-6 h-6 rounded-full bg-rose-500/10 border border-rose-500/30 flex items-center justify-center text-rose-400">
                      <RotateCw className="w-3.5 h-3.5 animate-spin" />
                    </div>
                  )}
                  {act.status === 'auto_fixing' && (
                    <div className="w-6 h-6 rounded-full bg-purple-500/10 border border-purple-500/30 flex items-center justify-center text-purple-400">
                      <Sparkles className="w-3.5 h-3.5 animate-pulse" />
                    </div>
                  )}
                  {act.status === 'failed' && (
                    <div className="w-6 h-6 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center text-red-400">
                      <AlertCircle className="w-3.5 h-3.5" />
                    </div>
                  )}
                </div>

                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-1.5">
                    <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-300 uppercase tracking-wide">
                      {act.type}
                    </span>
                    {act.className && (
                      <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-rose-500/10 text-rose-300 border border-rose-500/20">
                        {act.className}
                      </span>
                    )}
                    <span className="text-xs font-semibold text-white truncate font-mono">
                      {act.targetPath}
                    </span>
                  </div>

                  {act.errorMessage && (
                    <p className="text-[11px] text-red-400 mt-1 font-mono break-all">
                      ⚠️ {act.errorMessage}
                    </p>
                  )}

                  {act.resultMessage && (
                    <p className="text-[11px] text-slate-400 mt-0.5 truncate">
                      {act.resultMessage}
                    </p>
                  )}
                </div>
              </div>

              {/* Right Action Buttons */}
              <div className="flex items-center gap-2 self-end sm:self-auto shrink-0">
                {isScript && (
                  <button
                    onClick={() => onInspectCode(act)}
                    className="px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-medium flex items-center gap-1.5 border border-slate-700 transition-colors"
                  >
                    <Code2 className="w-3.5 h-3.5 text-rose-400" />
                    <span>View Luau</span>
                  </button>
                )}

                {act.status === 'pending' && (
                  <button
                    onClick={() => onMockExecute(act.id)}
                    className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-500 text-white text-xs font-medium flex items-center gap-1.5 shadow-md shadow-rose-600/20 transition-all"
                  >
                    <Play className="w-3 h-3 fill-white" />
                    <span>Deploy</span>
                  </button>
                )}

                {act.status === 'failed' && (
                  <button
                    onClick={() => onRetryAction(act.id)}
                    className="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-500 text-white text-xs font-medium flex items-center gap-1.5 shadow-md shadow-amber-600/20 transition-all"
                  >
                    <RotateCw className="w-3 h-3" />
                    <span>Retry</span>
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
