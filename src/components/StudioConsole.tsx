import React, { useState } from 'react';
import { 
  LogEntry 
} from '../types';
import { 
  Terminal, 
  Trash2, 
  Filter, 
  Sparkles, 
  AlertTriangle, 
  CheckCircle2, 
  Info, 
  Cpu 
} from 'lucide-react';

interface StudioConsoleProps {
  logs: LogEntry[];
  onClearLogs: () => void;
}

export const StudioConsole: React.FC<StudioConsoleProps> = ({
  logs,
  onClearLogs,
}) => {
  const [filter, setFilter] = useState<'all' | 'ai' | 'error' | 'bridge'>('all');

  const filteredLogs = logs.filter(log => {
    if (filter === 'all') return true;
    if (filter === 'ai') return log.level === 'ai';
    if (filter === 'error') return log.level === 'error' || log.level === 'warn';
    if (filter === 'bridge') return log.level === 'bridge' || log.level === 'info';
    return true;
  });

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40 flex flex-col">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mb-3">
        <div className="flex items-center gap-2">
          <Terminal className="w-4 h-4 text-rose-400" />
          <h3 className="text-sm font-semibold text-white">
            Roblox Studio Output &amp; Autonomous Telemetry
          </h3>
          <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-400 font-mono border border-slate-700">
            {logs.length} events
          </span>
        </div>

        <div className="flex items-center gap-2">
          {/* Filters */}
          <div className="flex items-center gap-1 bg-slate-950 p-1 rounded-lg border border-slate-800 text-xs">
            <button
              onClick={() => setFilter('all')}
              className={`px-2 py-0.5 rounded text-[11px] font-medium transition-colors ${
                filter === 'all' ? 'bg-slate-800 text-white' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              All
            </button>
            <button
              onClick={() => setFilter('ai')}
              className={`px-2 py-0.5 rounded text-[11px] font-medium transition-colors flex items-center gap-1 ${
                filter === 'ai' ? 'bg-rose-500/20 text-rose-300' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <Sparkles className="w-2.5 h-2.5" /> AI
            </button>
            <button
              onClick={() => setFilter('error')}
              className={`px-2 py-0.5 rounded text-[11px] font-medium transition-colors flex items-center gap-1 ${
                filter === 'error' ? 'bg-red-500/20 text-red-300' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Errors
            </button>
          </div>

          <button
            onClick={onClearLogs}
            title="Clear Console Output"
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700 transition-colors"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Terminal View */}
      <div className="w-full h-48 bg-slate-950 rounded-xl p-3 font-mono text-xs overflow-y-auto space-y-1.5 border border-slate-800">
        {filteredLogs.length === 0 ? (
          <div className="text-slate-600 italic py-4 text-center">
            No telemetry events recorded yet.
          </div>
        ) : (
          filteredLogs.map((log) => (
            <div key={log.id} className="flex items-start gap-2 leading-relaxed">
              <span className="text-slate-600 select-none text-[10px] whitespace-nowrap mt-0.5">
                {new Date(log.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
              </span>

              <div className="mt-0.5 shrink-0">
                {log.level === 'ai' && <Sparkles className="w-3 h-3 text-rose-400" />}
                {log.level === 'error' && <AlertTriangle className="w-3 h-3 text-red-400" />}
                {log.level === 'warn' && <AlertTriangle className="w-3 h-3 text-amber-400" />}
                {log.level === 'info' && <Info className="w-3 h-3 text-blue-400" />}
                {log.level === 'bridge' && <Cpu className="w-3 h-3 text-emerald-400" />}
              </div>

              <span
                className={`break-all ${
                  log.level === 'error'
                    ? 'text-red-400 font-medium'
                    : log.level === 'warn'
                    ? 'text-amber-300'
                    : log.level === 'ai'
                    ? 'text-rose-300'
                    : log.level === 'bridge'
                    ? 'text-emerald-300'
                    : 'text-slate-300'
                }`}
              >
                {log.message}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
