import React, { useState } from 'react';
import { 
  RobloxInstanceNode 
} from '../types';
import { 
  Folder, 
  FileCode, 
  Box, 
  ChevronRight, 
  ChevronDown, 
  Search, 
  Code2, 
  Sparkles, 
  Layers, 
  Eye, 
  Server, 
  HardDrive, 
  Layout, 
  User, 
  Sun, 
  Volume2 
} from 'lucide-react';

interface HierarchyInspectorProps {
  rootNode: RobloxInstanceNode;
  onInspectNode: (node: RobloxInstanceNode) => void;
}

export const HierarchyInspector: React.FC<HierarchyInspectorProps> = ({
  rootNode,
  onInspectNode,
}) => {
  const [search, setSearch] = useState('');
  const [expandedPaths, setExpandedPaths] = useState<Set<string>>(
    new Set([
      'game',
      'game.Workspace',
      'game.ServerScriptService',
      'game.ReplicatedStorage',
      'game.StarterGui',
    ])
  );

  const toggleExpand = (path: string) => {
    const next = new Set(expandedPaths);
    if (next.has(path)) {
      next.delete(path);
    } else {
      next.add(path);
    }
    setExpandedPaths(next);
  };

  const renderNode = (node: RobloxInstanceNode, depth: number = 0) => {
    const hasChildren = node.children && node.children.length > 0;
    const isExpanded = expandedPaths.has(node.path);
    const isScript = node.className === 'Script' || node.className === 'LocalScript' || node.className === 'ModuleScript' || !!node.sourceCode;

    if (search && !node.name.toLowerCase().includes(search.toLowerCase()) && !node.path.toLowerCase().includes(search.toLowerCase())) {
      // If none of children match either, skip
      const hasMatchingChild = (n: RobloxInstanceNode): boolean => {
        if (n.name.toLowerCase().includes(search.toLowerCase())) return true;
        return (n.children || []).some(hasMatchingChild);
      };
      if (!hasMatchingChild(node)) return null;
    }

    const nodeKey = node.id || `${node.path}_${node.className || 'Instance'}_${depth}`;

    return (
      <div key={nodeKey} className="select-none">
        <div 
          className={`flex items-center justify-between py-1.5 px-2 rounded-lg hover:bg-slate-800/80 transition-colors group cursor-pointer ${
            depth === 0 ? 'bg-slate-950/40 font-semibold' : ''
          }`}
          style={{ paddingLeft: `${Math.max(8, depth * 16)}px` }}
          onClick={() => {
            if (hasChildren) toggleExpand(node.path);
            if (isScript) onInspectNode(node);
          }}
        >
          <div className="flex items-center gap-1.5 min-w-0 flex-1">
            {hasChildren ? (
              <button 
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  toggleExpand(node.path);
                }}
                className="p-0.5 text-slate-500 hover:text-slate-200"
              >
                {isExpanded ? (
                  <ChevronDown className="w-3.5 h-3.5" />
                ) : (
                  <ChevronRight className="w-3.5 h-3.5" />
                )}
              </button>
            ) : (
              <div className="w-3.5 h-3.5" />
            )}

            {getInstanceIcon(node.className, node.name)}

            <span className="text-xs text-slate-200 font-mono truncate">
              {node.name}
            </span>

            {node.className && (
              <span className="text-[10px] text-slate-500 font-mono hidden group-hover:inline">
                ({node.className})
              </span>
            )}
          </div>

          {isScript && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                onInspectNode(node);
              }}
              title="Inspect Luau Code"
              className="p-1 rounded bg-rose-500/10 text-rose-300 hover:bg-rose-500/20 border border-rose-500/30 text-[10px] font-mono flex items-center gap-1 opacity-80 group-hover:opacity-100 transition-opacity"
            >
              <Code2 className="w-3 h-3" />
              <span>View</span>
            </button>
          )}
        </div>

        {hasChildren && isExpanded && (
          <div className="space-y-0.5">
            {node.children!.map((child) => renderNode(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40 flex flex-col h-[580px]">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Layers className="w-4 h-4 text-rose-400" />
          <h3 className="text-sm font-semibold text-white">
            Roblox DataModel Explorer
          </h3>
        </div>
        <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-rose-300 font-mono border border-slate-700">
          Live Hierarchy
        </span>
      </div>

      {/* Search Bar */}
      <div className="relative mb-3">
        <Search className="w-3.5 h-3.5 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Filter DataModel instances..."
          className="w-full bg-slate-950 border border-slate-800 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-rose-500/50"
        />
      </div>

      {/* Tree Content */}
      <div className="flex-1 overflow-y-auto space-y-0.5 pr-1 -mr-1">
        {renderNode(rootNode)}
      </div>
    </div>
  );
};

function getInstanceIcon(className: string, name: string) {
  switch (className) {
    case 'Workspace':
      return <Box className="w-3.5 h-3.5 text-blue-400" />;
    case 'ServerScriptService':
      return <Server className="w-3.5 h-3.5 text-amber-400" />;
    case 'ReplicatedStorage':
      return <HardDrive className="w-3.5 h-3.5 text-emerald-400" />;
    case 'StarterGui':
      return <Layout className="w-3.5 h-3.5 text-purple-400" />;
    case 'StarterPlayer':
    case 'StarterPlayerScripts':
    case 'StarterCharacterScripts':
      return <User className="w-3.5 h-3.5 text-cyan-400" />;
    case 'Lighting':
      return <Sun className="w-3.5 h-3.5 text-amber-300" />;
    case 'SoundService':
      return <Volume2 className="w-3.5 h-3.5 text-rose-400" />;
    case 'Script':
      return <FileCode className="w-3.5 h-3.5 text-green-400" />;
    case 'LocalScript':
      return <FileCode className="w-3.5 h-3.5 text-blue-400" />;
    case 'ModuleScript':
      return <FileCode className="w-3.5 h-3.5 text-yellow-400" />;
    case 'RemoteEvent':
    case 'RemoteFunction':
      return <Sparkles className="w-3.5 h-3.5 text-rose-400" />;
    case 'Part':
    case 'SpawnLocation':
    case 'Model':
      return <Box className="w-3.5 h-3.5 text-slate-400" />;
    case 'Folder':
    default:
      return <Folder className="w-3.5 h-3.5 text-slate-400" />;
  }
}
