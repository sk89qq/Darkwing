import React, { useState, useEffect, useCallback } from 'react';
import { 
  RobloxAction, 
  RobloxInstanceNode, 
  LogEntry, 
  BridgeStatus 
} from './types';
import { Header } from './components/Header';
import { PromptConsole } from './components/PromptConsole';
import { QueueTimeline } from './components/QueueTimeline';
import { HierarchyInspector } from './components/HierarchyInspector';
import { StudioConsole } from './components/StudioConsole';
import { Workspace3DViewport } from './components/Workspace3DViewport';
import { LuauScratchpad } from './components/LuauScratchpad';
import { CodeModal } from './components/CodeModal';
import { SetupModal } from './components/SetupModal';
import { Layers, Box, Terminal, Code2, Zap } from 'lucide-react';

export default function App() {
  const [bridgeStatus, setBridgeStatus] = useState<BridgeStatus>({
    connected: false,
    lastPing: 0,
    bridgeType: 'simulator',
    totalExecuted: 0,
    pendingCount: 0,
  });

  const [actions, setActions] = useState<RobloxAction[]>([]);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [robloxTree, setRobloxTree] = useState<RobloxInstanceNode>({
    id: 'datamodel-root',
    name: 'DataModel',
    className: 'DataModel',
    path: 'game',
    children: []
  });

  const [isSimulating, setIsSimulating] = useState<boolean>(true);
  const [isPlanning, setIsPlanning] = useState<boolean>(false);
  const [isExecutingDirect, setIsExecutingDirect] = useState<boolean>(false);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  const [inspectItem, setInspectItem] = useState<RobloxAction | RobloxInstanceNode | null>(null);
  const [isSetupOpen, setIsSetupOpen] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<'viewport' | 'code' | 'logs'>('viewport');

  // Fetch state from server
  const fetchState = useCallback(async () => {
    try {
      const res = await fetch('/api/bridge/state');
      if (!res.ok) return;
      const data = await res.json();

      setBridgeStatus(prev => ({
        ...prev,
        connected: data.connected,
        lastPing: data.lastPing,
        agentName: data.agentInfo?.name,
        bridgeType: data.agentInfo?.type || 'simulator',
        totalExecuted: data.stats?.success || 0,
        pendingCount: data.stats?.pending || 0,
      }));

      if (data.queue) setActions(data.queue);
      if (data.logs) setLogs(data.logs);
      if (data.tree) setRobloxTree(data.tree);
    } catch (err) {
      console.error('Failed to sync state:', err);
    }
  }, []);

  // Poll state every 2 seconds
  useEffect(() => {
    fetchState();
    const interval = setInterval(fetchState, 2000);
    return () => clearInterval(interval);
  }, [fetchState]);

  // Handle plan generation from Gemini
  const handleGeneratePlan = async (prompt: string, autonomous: boolean) => {
    setIsPlanning(true);
    try {
      const res = await fetch('/api/ai/plan-and-execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, autoExecute: autonomous }),
      });
      const data = await res.json();
      if (data.error) throw new Error(data.error);

      await fetchState();

      // If in simulation sandbox mode, auto simulate execution
      if (isSimulating && data.plan?.actions) {
        for (const act of data.plan.actions) {
          await fetch('/api/bridge/mock-execute', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ actionId: act.id }),
          });
          await new Promise(r => setTimeout(r, 300));
          await fetchState();
        }
      }
    } catch (err: any) {
      console.error('Plan generation failed:', err);
    } finally {
      setIsPlanning(false);
    }
  };

  // Mock simulate single action
  const handleMockExecute = async (actionId: string) => {
    try {
      await fetch('/api/bridge/mock-execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ actionId }),
      });
      await fetchState();
    } catch (err) {
      console.error('Mock execution error:', err);
    }
  };

  // Execute direct custom Luau code
  const handleExecuteLuau = async (code: string) => {
    setIsExecutingDirect(true);
    try {
      const customAction: RobloxAction = {
        id: `direct-${Date.now()}`,
        type: 'set_script_source',
        targetPath: 'game.ServerScriptService.LiveCommandRunner',
        className: 'Script',
        name: 'LiveCommandRunner',
        parentPath: 'game.ServerScriptService',
        sourceCode: code,
        status: 'pending',
        createdAt: Date.now(),
      };

      if (isSimulating) {
        await fetch('/api/bridge/mock-execute', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ actionId: customAction.id }),
        });
      }
      await fetchState();
    } catch (err) {
      console.error('Execution error:', err);
    } finally {
      setIsExecutingDirect(false);
    }
  };

  // Reset workspace queue
  const handleReset = async () => {
    try {
      await fetch('/api/bridge/reset', { method: 'POST' });
      await fetchState();
    } catch (err) {
      console.error('Reset error:', err);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await fetchState();
    setTimeout(() => setIsRefreshing(false), 500);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-rose-500/30 selection:text-rose-200">
      {/* Top Navigation Bar */}
      <Header
        bridgeStatus={bridgeStatus}
        isSimulating={isSimulating}
        onToggleSimulate={() => setIsSimulating(!isSimulating)}
        onOpenSetup={() => setIsSetupOpen(true)}
        onReset={handleReset}
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
      />

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 space-y-6">
        {/* Top Autonomous Prompt Architect */}
        <PromptConsole
          onGeneratePlan={handleGeneratePlan}
          isLoading={isPlanning}
          totalPendingActions={actions.filter(a => a.status === 'pending').length}
        />

        {/* Center Grid: 3D Viewport & Explorer */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Left Column: 3D Viewport & Scratchpad */}
          <div className="lg:col-span-8 space-y-6">
            {/* Viewport / Code Tabs */}
            <div className="flex items-center gap-2 border-b border-slate-800 pb-2">
              <button
                onClick={() => setActiveTab('viewport')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                  activeTab === 'viewport'
                    ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Box className="w-3.5 h-3.5" />
                3D Live Workspace Viewport
              </button>

              <button
                onClick={() => setActiveTab('code')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                  activeTab === 'code'
                    ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Code2 className="w-3.5 h-3.5" />
                Luau Command Bar
              </button>
            </div>

            {activeTab === 'viewport' ? (
              <Workspace3DViewport
                rootNode={robloxTree}
                onSelectInstance={(node) => setInspectItem(node)}
                selectedPath={inspectItem && 'path' in inspectItem ? inspectItem.path : undefined}
              />
            ) : (
              <LuauScratchpad
                onExecuteCode={handleExecuteLuau}
                isLoading={isExecutingDirect}
              />
            )}

            {/* Studio Execution Logs & Reasoning Stream */}
            <StudioConsole
              logs={logs}
              onClearLogs={() => setLogs([])}
            />
          </div>

          {/* Right Column: Roblox DataModel Explorer & Command Queue */}
          <div className="lg:col-span-4 space-y-6">
            {/* DataModel Explorer */}
            <HierarchyInspector
              rootNode={robloxTree}
              onInspectNode={(node) => setInspectItem(node)}
            />
          </div>
        </div>

        {/* Command Queue Timeline */}
        <div className="w-full">
          <QueueTimeline
            actions={actions}
            isSimulating={isSimulating}
            onMockExecute={handleMockExecute}
            onInspectCode={(action) => setInspectItem(action)}
            onRetryAction={handleMockExecute}
          />
        </div>
      </main>

      {/* Code Inspector Modal */}
      <CodeModal
        item={inspectItem}
        onClose={() => setInspectItem(null)}
      />

      {/* Connection & Setup Modal */}
      <SetupModal
        isOpen={isSetupOpen}
        onClose={() => setIsSetupOpen(false)}
      />
    </div>
  );
}
