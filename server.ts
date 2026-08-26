import express, { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = 3000;

// Permissive CORS and payload configuration for Roblox Studio HttpService
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// ----------------------------------------------------
// In-Memory Bridge & DataModel State
// ----------------------------------------------------
interface ActionItem {
  id: string;
  type: string;
  targetPath: string;
  className?: string;
  name?: string;
  parentPath?: string;
  properties?: Record<string, any>;
  sourceCode?: string;
  status: 'pending' | 'sent' | 'executing' | 'success' | 'failed' | 'auto_fixing';
  createdAt: number;
  completedAt?: number;
  resultMessage?: string;
  errorMessage?: string;
  retryCount?: number;
}

interface LogEntry {
  id: string;
  timestamp: number;
  level: 'info' | 'warn' | 'error' | 'ai' | 'bridge';
  message: string;
  details?: any;
  actionId?: string;
}

interface InstanceNode {
  id: string;
  name: string;
  className: string;
  path: string;
  properties?: Record<string, any>;
  sourceCode?: string;
  children?: InstanceNode[];
}

let actionsQueue: ActionItem[] = [];
let logs: LogEntry[] = [
  {
    id: 'log-init',
    timestamp: Date.now(),
    level: 'info',
    message: 'Roblox Studio MCP Autonomous Bridge initialized.',
  }
];

let bridgeConnected = false;
let lastBridgePing = 0;
let bridgeAgentInfo = {
  name: 'Roblox MCP Bridge Runner',
  type: 'simulator' as 'mcp_superassistant' | 'studio_plugin' | 'python_runner' | 'node_runner' | 'simulator',
  version: '1.0.0',
};

// Scan disk directory into Roblox Instance Nodes
function scanDirToNodes(dirPath: string, parentGamePath: string): InstanceNode[] {
  if (!fs.existsSync(dirPath)) return [];
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    const nodes: InstanceNode[] = [];

    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        const folderName = entry.name;
        const gamePath = `${parentGamePath}.${folderName}`;
        const childNodes = scanDirToNodes(fullPath, gamePath);
        nodes.push({
          id: `dir-${gamePath.replace(/[^a-zA-Z0-9]/g, '_')}`,
          name: folderName,
          className: 'Folder',
          path: gamePath,
          children: childNodes,
        });
      } else if (entry.isFile()) {
        let scriptName = entry.name;
        let className = 'ModuleScript';
        if (scriptName.endsWith('.server.luau') || scriptName.endsWith('.server.lua')) {
          scriptName = scriptName.replace(/\.server\.luau?$/, '');
          className = 'Script';
        } else if (scriptName.endsWith('.client.luau') || scriptName.endsWith('.client.lua')) {
          scriptName = scriptName.replace(/\.client\.luau?$/, '');
          className = 'LocalScript';
        } else if (scriptName.endsWith('.luau') || scriptName.endsWith('.lua')) {
          scriptName = scriptName.replace(/\.luau?$/, '');
          if (parentGamePath.includes('StarterPlayer') || parentGamePath.includes('StarterGui')) {
            className = 'LocalScript';
          } else if (parentGamePath.includes('ServerScriptService') && (scriptName.includes('Main') || scriptName.includes('Server') || scriptName.includes('Spawner') || scriptName.includes('Logger') || scriptName.includes('Builder') || scriptName.includes('Manager') || scriptName.includes('System') || scriptName.includes('Router'))) {
            className = 'Script';
          } else {
            className = 'ModuleScript';
          }
        } else {
          continue;
        }

        const hasFolderWithSameName = nodes.some(n => n.name === scriptName && n.className === 'Folder');
        const gamePath = hasFolderWithSameName ? `${parentGamePath}.${scriptName}_Script` : `${parentGamePath}.${scriptName}`;
        let sourceCode = '';
        try {
          sourceCode = fs.readFileSync(fullPath, 'utf-8');
        } catch (e) {}

        nodes.push({
          id: `file-${gamePath.replace(/[^a-zA-Z0-9]/g, '_')}-${entry.name.replace(/[^a-zA-Z0-9]/g, '_')}`,
          name: hasFolderWithSameName ? `${scriptName} (${className})` : scriptName,
          className,
          path: gamePath,
          sourceCode,
          properties: {},
          children: [],
        });
      }
    }
    return nodes;
  } catch (err) {
    console.error(`Failed to scan dir ${dirPath}:`, err);
    return [];
  }
}

// Build complete live DataModel Tree from /src/roblox filesystem
function buildInitialRobloxTree(): InstanceNode {
  const robloxRoot = path.join(process.cwd(), 'src', 'roblox');

  const sssChildren = scanDirToNodes(path.join(robloxRoot, 'ServerScriptService'), 'game.ServerScriptService');
  const repChildren = scanDirToNodes(path.join(robloxRoot, 'ReplicatedStorage'), 'game.ReplicatedStorage');
  const ssChildren = scanDirToNodes(path.join(robloxRoot, 'ServerStorage'), 'game.ServerStorage');
  const guiChildren = scanDirToNodes(path.join(robloxRoot, 'StarterGui'), 'game.StarterGui');
  const spsChildren = scanDirToNodes(path.join(robloxRoot, 'StarterPlayer', 'StarterPlayerScripts'), 'game.StarterPlayer.StarterPlayerScripts');
  const scsChildren = scanDirToNodes(path.join(robloxRoot, 'StarterPlayer', 'StarterCharacterScripts'), 'game.StarterPlayer.StarterCharacterScripts');

  return {
    id: 'datamodel-root',
    name: 'DataModel',
    className: 'DataModel',
    path: 'game',
    children: [
      {
        id: 'dm-workspace',
        name: 'Workspace',
        className: 'Workspace',
        path: 'game.Workspace',
        properties: { FilteringEnabled: true, Gravity: 0 },
        children: [
          {
            id: 'dm-baseplate',
            name: 'Baseplate',
            className: 'Part',
            path: 'game.Workspace.Baseplate',
            properties: {
              Size: 'Vector3(1024, 4, 1024)',
              Position: 'Vector3(0, -2, 0)',
              Anchored: true,
              Color: 'Color3.fromRGB(15, 18, 25)',
              Material: 'Enum.Material.SmoothPlastic',
            }
          },
          {
            id: 'dm-space-arena',
            name: 'SpaceCombatArena',
            className: 'Folder',
            path: 'game.Workspace.SpaceCombatArena',
            properties: {},
            children: [
              {
                id: 'dm-spawn-core',
                name: 'SpawnLocation',
                className: 'SpawnLocation',
                path: 'game.Workspace.SpaceCombatArena.SpawnLocation',
                properties: {
                  Size: 'Vector3(16, 1, 16)',
                  Position: 'Vector3(0, 3.5, 0)',
                  Anchored: true,
                  Neutral: true,
                }
              }
            ]
          }
        ]
      },
      {
        id: 'dm-serverscriptservice',
        name: 'ServerScriptService',
        className: 'ServerScriptService',
        path: 'game.ServerScriptService',
        children: sssChildren,
      },
      {
        id: 'dm-replicatedstorage',
        name: 'ReplicatedStorage',
        className: 'ReplicatedStorage',
        path: 'game.ReplicatedStorage',
        children: repChildren,
      },
      {
        id: 'dm-serverstorage',
        name: 'ServerStorage',
        className: 'ServerStorage',
        path: 'game.ServerStorage',
        children: ssChildren,
      },
      {
        id: 'dm-startergui',
        name: 'StarterGui',
        className: 'StarterGui',
        path: 'game.StarterGui',
        children: guiChildren,
      },
      {
        id: 'dm-starterplayer',
        name: 'StarterPlayer',
        className: 'StarterPlayer',
        path: 'game.StarterPlayer',
        children: [
          {
            id: 'dm-starterplayerscripts',
            name: 'StarterPlayerScripts',
            className: 'StarterPlayerScripts',
            path: 'game.StarterPlayer.StarterPlayerScripts',
            children: spsChildren,
          },
          {
            id: 'dm-startercharacterscripts',
            name: 'StarterCharacterScripts',
            className: 'StarterCharacterScripts',
            path: 'game.StarterPlayer.StarterCharacterScripts',
            children: scsChildren,
          }
        ]
      },
      {
        id: 'dm-lighting',
        name: 'Lighting',
        className: 'Lighting',
        path: 'game.Lighting',
        properties: {
          ClockTime: 0,
          Brightness: 0.5,
          GlobalShadows: true,
          Ambient: 'Color3.fromRGB(20, 25, 40)',
          OutdoorAmbient: 'Color3.fromRGB(10, 15, 30)',
        },
        children: []
      },
      {
        id: 'dm-soundservice',
        name: 'SoundService',
        className: 'SoundService',
        path: 'game.SoundService',
        children: []
      }
    ]
  };
}

let robloxTree: InstanceNode = buildInitialRobloxTree();

function addLog(level: LogEntry['level'], message: string, details?: any, actionId?: string) {
  const entry: LogEntry = {
    id: `log-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    timestamp: Date.now(),
    level,
    message,
    details,
    actionId,
  };
  logs.push(entry);
  if (logs.length > 500) {
    logs = logs.slice(-400);
  }
  return entry;
}

// Helper to update DataModel tree when actions succeed
function applyActionToTree(action: ActionItem) {
  const parts = action.targetPath.split('.');
  if (parts.length < 2) return;

  if (action.type === 'create_instance' || action.type === 'set_script_source' || action.type === 'set_properties') {
    const parentPath = action.parentPath || parts.slice(0, -1).join('.');
    const itemName = action.name || parts[parts.length - 1];
    const fullPath = action.targetPath;

    function findAndAdd(node: InstanceNode): boolean {
      if (node.path === parentPath) {
        node.children = node.children || [];
        const existingIdx = node.children.findIndex(c => c.path === fullPath || c.name === itemName);
        const newNode: InstanceNode = {
          id: `inst-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          name: itemName,
          className: action.className || 'Part',
          path: fullPath,
          properties: action.properties || {},
          sourceCode: action.sourceCode,
          children: existingIdx >= 0 ? node.children[existingIdx].children : [],
        };
        if (existingIdx >= 0) {
          node.children[existingIdx] = {
            ...node.children[existingIdx],
            ...newNode,
            children: node.children[existingIdx].children || [],
          };
        } else {
          node.children.push(newNode);
        }
        return true;
      }
      if (node.children) {
        for (const child of node.children) {
          if (findAndAdd(child)) return true;
        }
      }
      return false;
    }

    findAndAdd(robloxTree);
  } else if (action.type === 'delete_instance') {
    function findAndDelete(node: InstanceNode): boolean {
      if (node.children) {
        const idx = node.children.findIndex(c => c.path === action.targetPath);
        if (idx >= 0) {
          node.children.splice(idx, 1);
          return true;
        }
        for (const child of node.children) {
          if (findAndDelete(child)) return true;
        }
      }
      return false;
    }
    findAndDelete(robloxTree);
  }
}

// ----------------------------------------------------
// Gemini AI Autonomous Engine
// ----------------------------------------------------
function getGeminiClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.warn('GEMINI_API_KEY is not set.');
    return null;
  }
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

// ----------------------------------------------------
// API Endpoints
// ----------------------------------------------------

// 1. Get Bridge & Studio State
app.get('/api/bridge/state', (req: Request, res: Response) => {
  const isAlive = Date.now() - lastBridgePing < 15000;
  res.json({
    connected: isAlive || bridgeConnected,
    lastPing: lastBridgePing,
    agentInfo: bridgeAgentInfo,
    queue: actionsQueue,
    logs: logs.slice(-100),
    tree: robloxTree,
    stats: {
      totalActions: actionsQueue.length,
      pending: actionsQueue.filter(a => a.status === 'pending').length,
      success: actionsQueue.filter(a => a.status === 'success').length,
      failed: actionsQueue.filter(a => a.status === 'failed').length,
    }
  });
});

// 2. Ping / Heartbeat from local bridge or runner
app.post('/api/bridge/ping', (req: Request, res: Response) => {
  const { agentName, type, version } = req.body || {};
  lastBridgePing = Date.now();
  bridgeConnected = true;
  if (agentName) bridgeAgentInfo.name = agentName;
  if (type) bridgeAgentInfo.type = type;
  if (version) bridgeAgentInfo.version = version;

  addLog('bridge', `Bridge ping from ${bridgeAgentInfo.name} (${bridgeAgentInfo.type})`);
  res.json({ status: 'ok', timestamp: Date.now() });
});

// 2b. Sync Full Live DataModel Hierarchy & Scripts from Roblox Studio
app.all('/api/bridge/sync-tree', (req: Request, res: Response) => {
  let { tree, stats } = req.body || {};
  
  // Also handle stringified bodies if sent as raw text
  if (typeof req.body === 'string') {
    try {
      const parsed = JSON.parse(req.body);
      tree = parsed.tree;
      stats = parsed.stats;
    } catch (e) {}
  }

  lastBridgePing = Date.now();
  bridgeConnected = true;

  if (tree && typeof tree === 'object') {
    robloxTree = tree;
    const instCount = stats?.instanceCount || (tree.children ? tree.children.length : 'all');
    addLog('bridge', `🔄 Live Studio Sync: Loaded ${instCount} service trees from Roblox Studio.`);
  }

  res.json({ status: 'ok', synchronized: true, timestamp: Date.now() });
});

// 2c. Report endpoint alias for backward compatibility
app.all('/api/bridge/report', (req: Request, res: Response) => {
  lastBridgePing = Date.now();
  bridgeConnected = true;
  res.json({ status: 'ok', timestamp: Date.now() });
});

// 3. Bridge polling for next pending tasks (called by local runner)
app.get('/api/bridge/poll', (req: Request, res: Response) => {
  lastBridgePing = Date.now();
  bridgeConnected = true;

  const nextAction = actionsQueue.find(a => a.status === 'pending');
  if (nextAction) {
    nextAction.status = 'sent';
    addLog('bridge', `Dispatched action [${nextAction.type}] ${nextAction.targetPath} to local bridge runner.`, null, nextAction.id);
    res.json({ hasAction: true, action: nextAction });
  } else {
    res.json({ hasAction: false });
  }
});

// 4. Bridge posting execution result
app.post('/api/bridge/result', async (req: Request, res: Response) => {
  const { actionId, success, result, error, stdout, autoFix } = req.body || {};
  lastBridgePing = Date.now();
  bridgeConnected = true;

  const action = actionsQueue.find(a => a.id === actionId);
  if (!action) {
    res.status(404).json({ error: 'Action not found' });
    return;
  }

  if (success) {
    action.status = 'success';
    action.completedAt = Date.now();
    action.resultMessage = result || stdout || 'Executed successfully in Roblox Studio';
    applyActionToTree(action);
    addLog('info', `✅ Success in Roblox Studio: [${action.type}] ${action.targetPath}`, { result, stdout }, action.id);
    res.json({ status: 'ok', action });
    return;
  }

  // Handle failure
  action.status = 'failed';
  action.errorMessage = error || stdout || 'Execution failed in Roblox Studio';
  action.retryCount = (action.retryCount || 0) + 1;
  addLog('error', `❌ Roblox Studio Error on ${action.targetPath}: ${action.errorMessage}`, { error, stdout }, action.id);

  // If autoFix is enabled and we haven't retried more than 3 times, let Gemini auto-fix!
  if (autoFix !== false && (action.retryCount || 0) <= 3) {
    action.status = 'auto_fixing';
    addLog('ai', `🤖 Gemini Autonomous Self-Correction triggered for ${action.targetPath}...`, null, action.id);

    try {
      const fixedAction = await triggerAutonomousAutoFix(action, action.errorMessage);
      if (fixedAction) {
        actionsQueue.push(fixedAction);
        addLog('ai', `✨ Autonomous Fix generated for ${action.targetPath}! Queued revised action.`, fixedAction, fixedAction.id);
        res.json({ status: 'auto_fixed', originalAction: action, fixedAction });
        return;
      }
    } catch (err: any) {
      addLog('error', `Autonomous fix error: ${err?.message || err}`);
    }
  }

  res.json({ status: 'failed', action });
});

// 5. Mock Simulation Execute (for browser testing without local bridge)
app.post('/api/bridge/mock-execute', (req: Request, res: Response) => {
  const { actionId } = req.body;
  const action = actionsQueue.find(a => a.id === actionId);
  if (!action) {
    res.status(404).json({ error: 'Action not found' });
    return;
  }

  action.status = 'executing';
  addLog('bridge', `[Simulator] Executing ${action.type} on ${action.targetPath}...`, null, action.id);

  setTimeout(() => {
    action.status = 'success';
    action.completedAt = Date.now();
    action.resultMessage = `Simulated execution of ${action.type} (${action.className || 'Instance'}) in Roblox DataModel`;
    applyActionToTree(action);
    addLog('info', `✅ [Simulator] Successfully applied ${action.targetPath} to DataModel tree.`, null, action.id);
  }, 400);

  res.json({ status: 'simulating', action });
});

// 6. Clear Queue & Reset DataModel
app.post('/api/bridge/reset', (req: Request, res: Response) => {
  actionsQueue = [];
  robloxTree = buildInitialRobloxTree();
  logs = [
    {
      id: `log-${Date.now()}`,
      timestamp: Date.now(),
      level: 'info',
      message: 'Workspace, scripts, and action queues reset & reloaded from disk.',
    }
  ];
  res.json({ status: 'ok', tree: robloxTree });
});

// 6b. Reload Tree from disk
app.post('/api/bridge/reload-disk', (req: Request, res: Response) => {
  robloxTree = buildInitialRobloxTree();
  addLog('info', '🔄 Reloaded all Luau scripts and services from disk into DataModel.');
  res.json({ status: 'ok', tree: robloxTree });
});

// ----------------------------------------------------
// Gemini Autonomous Planning Endpoint
// ----------------------------------------------------
app.post('/api/ai/plan-and-execute', async (req: Request, res: Response) => {
  const { prompt, autoExecute } = req.body;

  if (!prompt || typeof prompt !== 'string') {
    res.status(400).json({ error: 'Prompt is required' });
    return;
  }

  addLog('ai', `🧠 Gemini analyzing request: "${prompt}"...`);

  const ai = getGeminiClient();
  if (!ai) {
    // Fallback template builder if no API key is available
    const fallbackActions = generateFallbackRobloxPlan(prompt);
    for (const act of fallbackActions) {
      actionsQueue.push(act);
      addLog('info', `Queued action: [${act.type}] ${act.targetPath}`, null, act.id);
    }
    res.json({
      plan: {
        title: 'Roblox Studio Implementation Plan',
        summary: `Generated ${fallbackActions.length} actions based on your request.`,
        actions: fallbackActions,
      }
    });
    return;
  }

  try {
    const systemPrompt = `You are a Principal Roblox Engine Architect and Luau Expert.
Your mission is to take high-level user requests (game features, UI, mechanics, systems) and generate the exact, sequential, production-grade Roblox Studio Instance creations and Luau scripts.

Current Roblox DataModel tree context:
${JSON.stringify(robloxTree, null, 2)}

You MUST output STRICT JSON in this exact structure:
{
  "title": "Short descriptive title of the system",
  "summary": "2-3 sentence overview of the architecture and mechanics",
  "actions": [
    {
      "type": "create_instance" | "set_script_source" | "set_properties" | "delete_instance",
      "targetPath": "game.ServerScriptService.LeaderstatsManager",
      "className": "Script" | "LocalScript" | "ModuleScript" | "Part" | "Model" | "Folder" | "ScreenGui" | "Frame" | "TextButton" | "RemoteEvent" | "Sound" | "ProximityPrompt" | "Highlight",
      "name": "LeaderstatsManager",
      "parentPath": "game.ServerScriptService",
      "properties": {
        "Position": "Vector3(0, 5, 0)",
        "Size": "Vector3(4, 4, 4)",
        "Anchored": true,
        "CanCollide": false
      },
      "sourceCode": "-- Full production Luau code here if it is a Script, LocalScript, or ModuleScript"
    }
  ]
}

RULES FOR LUAU CODE:
1. Always write complete, bug-free, modern Luau (typed or idiomatic).
2. Never write placeholders, stubs, or '-- TODO'. Write complete production implementations with proper error checks (pcall for DataStores), services (game:GetService('Players'), game:GetService('ReplicatedStorage'), game:GetService('TweenService'), etc.).
3. Handle player joining/leaving cleanly: iterate through existing players with 'for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end' in addition to 'Players.PlayerAdded:Connect(onPlayerAdded)'.
4. Ensure RemoteEvents created in ReplicatedStorage are created before scripts that reference them.
5. All UI in StarterGui should use modern Layouts, UIGradients, UICorners, and responsive constraints.
`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.7-flash',
      contents: `Create a complete, autonomous Roblox Studio implementation for this request: "${prompt}". Generate all required Instances, Folders, RemoteEvents, Models, UI, and complete Luau scripts.`,
      config: {
        systemInstruction: systemPrompt,
        responseMimeType: 'application/json',
      }
    });

    const responseText = response.text || '{}';
    let parsedData: any;
    try {
      parsedData = JSON.parse(responseText);
    } catch (e) {
      // Clean up markdown code blocks if any
      const cleaned = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
      parsedData = JSON.parse(cleaned);
    }

    const createdActions: ActionItem[] = (parsedData.actions || []).map((act: any, idx: number) => ({
      id: `act-${Date.now()}-${idx}-${Math.random().toString(36).substring(2, 6)}`,
      type: act.type || 'create_instance',
      targetPath: act.targetPath,
      className: act.className || 'Script',
      name: act.name,
      parentPath: act.parentPath,
      properties: act.properties,
      sourceCode: act.sourceCode,
      status: 'pending',
      createdAt: Date.now(),
    }));

    for (const act of createdActions) {
      actionsQueue.push(act);
      addLog('info', `Queued action: [${act.type}] ${act.targetPath} (${act.className || 'Instance'})`, null, act.id);
    }

    addLog('ai', `🎯 Plan ready: "${parsedData.title || 'Roblox Implementation'}" with ${createdActions.length} executable actions.`);

    res.json({
      plan: {
        title: parsedData.title || 'Roblox Implementation Plan',
        summary: parsedData.summary || 'Generated autonomous execution plan for Roblox Studio.',
        actions: createdActions,
      }
    });

  } catch (err: any) {
    console.error('Gemini plan error:', err);
    addLog('error', `Gemini planning failed: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// Autonomous Auto-Fix helper
async function triggerAutonomousAutoFix(failedAction: ActionItem, errorLog: string): Promise<ActionItem | null> {
  const ai = getGeminiClient();
  if (!ai) return null;

  const fixPrompt = `You are a Roblox Engine & Luau debugging expert.
An automated action failed when executed inside Roblox Studio:

Action details:
Target: ${failedAction.targetPath}
Class: ${failedAction.className}
Type: ${failedAction.type}
Original Code/Properties:
${failedAction.sourceCode || JSON.stringify(failedAction.properties)}

Error Output from Roblox Studio:
${errorLog}

Fix the issue completely. Return a STRICT JSON object representing the corrected action:
{
  "type": "${failedAction.type}",
  "targetPath": "${failedAction.targetPath}",
  "className": "${failedAction.className || 'Script'}",
  "name": "${failedAction.name || ''}",
  "parentPath": "${failedAction.parentPath || ''}",
  "properties": ${JSON.stringify(failedAction.properties || {})},
  "sourceCode": "-- Corrected complete Luau source code"
}`;

  const response = await ai.models.generateContent({
    model: 'gemini-3.7-flash',
    contents: fixPrompt,
    config: {
      responseMimeType: 'application/json',
    }
  });

  const text = response.text || '{}';
  const parsed = JSON.parse(text.replace(/```json/g, '').replace(/```/g, '').trim());

  return {
    id: `fix-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
    type: parsed.type || failedAction.type,
    targetPath: parsed.targetPath || failedAction.targetPath,
    className: parsed.className || failedAction.className,
    name: parsed.name || failedAction.name,
    parentPath: parsed.parentPath || failedAction.parentPath,
    properties: parsed.properties || failedAction.properties,
    sourceCode: parsed.sourceCode || failedAction.sourceCode,
    status: 'pending',
    createdAt: Date.now(),
    retryCount: (failedAction.retryCount || 0) + 1,
  };
}

// Fallback plan generator if Gemini API key is missing
function generateFallbackRobloxPlan(prompt: string): ActionItem[] {
  const lower = prompt.toLowerCase();
  const timestamp = Date.now();

  if (lower.includes('coin') || lower.includes('leader') || lower.includes('stat')) {
    return [
      {
        id: `act-${timestamp}-1`,
        type: 'create_instance',
        targetPath: 'game.ReplicatedStorage.CoinCollectedEvent',
        className: 'RemoteEvent',
        name: 'CoinCollectedEvent',
        parentPath: 'game.ReplicatedStorage',
        status: 'pending',
        createdAt: timestamp,
      },
      {
        id: `act-${timestamp}-2`,
        type: 'set_script_source',
        targetPath: 'game.ServerScriptService.LeaderstatsManager',
        className: 'Script',
        name: 'LeaderstatsManager',
        parentPath: 'game.ServerScriptService',
        sourceCode: `-- LeaderstatsManager.server.luau
-- Manages Player Coins & Level with automatic saving & joining support

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local CoinStore = DataStoreService:GetDataStore("PlayerCoinStats_v1")
local CoinEvent = ReplicatedStorage:WaitForChild("CoinCollectedEvent")

local function onPlayerAdded(player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 1
    level.Parent = leaderstats

    -- Load Data
    local success, data = pcall(function()
        return CoinStore:GetAsync(tostring(player.UserId))
    end)

    if success and data then
        coins.Value = data.Coins or 0
        level.Value = data.Level or 1
    end
end

local function onPlayerRemoving(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local coins = leaderstats:FindFirstChild("Coins")
    local level = leaderstats:FindFirstChild("Level")

    pcall(function()
        CoinStore:SetAsync(tostring(player.UserId), {
            Coins = coins and coins.Value or 0,
            Level = level and level.Value or 1,
        })
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, p)
end

CoinEvent.OnServerEvent:Connect(function(player, coinAmount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    if coins then
        coins.Value = coins.Value + (coinAmount or 1)
    end
end)
`,
        status: 'pending',
        createdAt: timestamp,
      },
      {
        id: `act-${timestamp}-3`,
        type: 'create_instance',
        targetPath: 'game.Workspace.CoinSpawnerFolder',
        className: 'Folder',
        name: 'CoinSpawnerFolder',
        parentPath: 'game.Workspace',
        status: 'pending',
        createdAt: timestamp,
      },
      {
        id: `act-${timestamp}-4`,
        type: 'set_script_source',
        targetPath: 'game.ServerScriptService.CoinSpawner',
        className: 'Script',
        name: 'CoinSpawner',
        parentPath: 'game.ServerScriptService',
        sourceCode: `-- CoinSpawner.server.luau
-- Spawns rotating collectible coins in Workspace

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local coinFolder = workspace:WaitForChild("CoinSpawnerFolder")

local function spawnCoin(position: Vector3)
    local coin = Instance.new("Part")
    coin.Name = "GoldCoin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Size = Vector3.new(0.6, 2.5, 2.5)
    coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    coin.Color = Color3.fromRGB(255, 215, 0)
    coin.Material = Enum.Material.Neon
    coin.Anchored = true
    coin.CanCollide = false
    coin.Parent = coinFolder

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 230, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Parent = coin

    local collected = false
    coin.Touched:Connect(function(hit)
        if collected then return end
        local char = hit.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if player then
            collected = true
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local coins = leaderstats:FindFirstChild("Coins")
                if coins then
                    coins.Value = coins.Value + 10
                end
            end
            
            -- Pop effect
            local tween = TweenService:Create(coin, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1,
            })
            tween:Play()
            tween.Completed:Connect(function()
                coin:Destroy()
            end)
        end
    end)
end

-- Spawn initial coins
for i = 1, 8 do
    local angle = (i / 8) * math.pi * 2
    local radius = 25
    local pos = Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
    spawnCoin(pos)
end
`,
        status: 'pending',
        createdAt: timestamp,
      }
    ];
  }

  // Generic fallback
  return [
    {
      id: `act-${timestamp}-1`,
      type: 'create_instance',
      targetPath: 'game.ServerScriptService.MainGameController',
      className: 'Script',
      name: 'MainGameController',
      parentPath: 'game.ServerScriptService',
      sourceCode: `-- MainGameController.server.luau
-- Generated for prompt: ${prompt}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("[System] Initialized Autonomous Controller for: ${prompt.replace(/"/g, '')}")

Players.PlayerAdded:Connect(function(player)
    print("Welcome " .. player.DisplayName)
end)
`,
      status: 'pending',
      createdAt: timestamp,
    }
  ];
}

// 7. Get Ready-to-Run Bridge Scripts
app.get('/api/bridge/scripts', (req: Request, res: Response) => {
  const host = req.get('host') || 'localhost:3000';
  const protocol = req.protocol === 'https' || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
  const cloudUrl = `${protocol}://${host}`;

  const nodeBridgeScript = `/**
 * Roblox Studio <-> AI Studio MCP Autonomous Bridge Runner (Node.js)
 * 
 * Usage:
 *   1. npm install axios ws
 *   2. node roblox_mcp_bridge.js
 * 
 * How it works:
 *   - Polls AI Studio cloud mission control for Roblox actions.
 *   - Executes actions via local mcpsuperassistant (port 3001/8000) or Roblox Studio HTTP service plugin.
 *   - Streams errors & stdout back to Gemini for autonomous self-healing.
 */

const axios = require('axios');

const CLOUD_URL = '${cloudUrl}';
const LOCAL_ROBLOX_URL = process.env.ROBLOX_STUDIO_URL || 'http://127.0.0.1:3001';
const POLL_INTERVAL_MS = 1500;

console.log('🚀 Starting Roblox Studio MCP Autonomous Bridge...');
console.log('📡 Connected Cloud Control Hub:', CLOUD_URL);
console.log('🎮 Target Local Roblox MCP/Plugin:', LOCAL_ROBLOX_URL);

async function sendPing() {
  try {
    await axios.post(\`\${CLOUD_URL}/api/bridge/ping\`, {
      agentName: 'Local Node.js MCP Bridge Runner',
      type: 'node_runner',
      version: '1.0.0',
    });
  } catch (err) {
    console.error('Ping failed:', err.message);
  }
}

async function executeActionLocally(action) {
  console.log(\`⚡ Executing [\${action.type}] on \${action.targetPath}...\`);
  try {
    // Forward to mcpsuperassistant or Roblox Plugin HTTP endpoint
    const response = await axios.post(\`\${LOCAL_ROBLOX_URL}/execute\`, action, { timeout: 10000 });
    return {
      success: true,
      result: response.data?.result || 'Action executed successfully in Roblox Studio.',
      stdout: response.data?.stdout || '',
    };
  } catch (err) {
    // If local endpoint is unreachable, fallback report
    return {
      success: false,
      error: err.response?.data?.error || err.message,
      stdout: err.response?.data?.stdout || '',
    };
  }
}

async function pollQueue() {
  try {
    const res = await axios.get(\`\${CLOUD_URL}/api/bridge/poll\`);
    if (res.data && res.data.hasAction && res.data.action) {
      const action = res.data.action;
      console.log(\`📥 Received Action \${action.id}: \${action.type} -> \${action.targetPath}\`);
      
      const executionResult = await executeActionLocally(action);
      
      console.log(\`📤 Sending execution result to AI Studio...\`);
      await axios.post(\`\${CLOUD_URL}/api/bridge/result\`, {
        actionId: action.id,
        success: executionResult.success,
        result: executionResult.result,
        error: executionResult.error,
        stdout: executionResult.stdout,
        autoFix: true,
      });
    }
  } catch (err) {
    // Silent catch during idle poll
  }
}

// Start loop
sendPing();
setInterval(sendPing, 10000);
setInterval(pollQueue, POLL_INTERVAL_MS);
console.log('✅ Bridge active! Waiting for autonomous commands from AI Studio...');
`;

  const pythonBridgeScript = `# Roblox Studio <-> AI Studio MCP Autonomous Bridge Runner (Python)
# Usage:
#   pip install requests
#   python roblox_mcp_bridge.py

import requests
import time
import sys

CLOUD_URL = "${cloudUrl}"
LOCAL_ROBLOX_URL = "http://127.0.0.1:3001"
POLL_INTERVAL_SEC = 1.5

print(f"🚀 Starting Python Roblox MCP Bridge...")
print(f"📡 Cloud URL: {CLOUD_URL}")
print(f"🎮 Local Roblox MCP: {LOCAL_ROBLOX_URL}")

def send_ping():
    try:
        requests.post(f"{CLOUD_URL}/api/bridge/ping", json={
            "agentName": "Local Python MCP Bridge",
            "type": "python_runner",
            "version": "1.0.0"
        }, timeout=5)
    except Exception as e:
        pass

def execute_action(action):
    print(f"⚡ Executing [{action.get('type')}] on {action.get('targetPath')}...")
    try:
        r = requests.post(f"{LOCAL_ROBLOX_URL}/execute", json=action, timeout=10)
        data = r.json()
        return {
            "success": True,
            "result": data.get("result", "Success"),
            "stdout": data.get("stdout", "")
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "stdout": ""
        }

send_ping()
last_ping = time.time()

while True:
    try:
        if time.time() - last_ping > 10:
            send_ping()
            last_ping = time.time()

        r = requests.get(f"{CLOUD_URL}/api/bridge/poll", timeout=5)
        res_data = r.json()
        if res_data.get("hasAction") and res_data.get("action"):
            action = res_data["action"]
            print(f"📥 Received Action {action.get('id')}: {action.get('type')}")
            result = execute_action(action)
            requests.post(f"{CLOUD_URL}/api/bridge/result", json={
                "actionId": action.get("id"),
                "success": result["success"],
                "result": result.get("result"),
                "error": result.get("error"),
                "stdout": result.get("stdout"),
                "autoFix": True
            }, timeout=5)
    except Exception as e:
        pass
    time.sleep(POLL_INTERVAL_SEC)
`;

  const robloxStudioPluginLuau = `-- [[ 
  Roblox Studio Direct Autonomous Plugin (No external runner needed!)
  Paste this into a new Plugin in Roblox Studio or run in Studio Command Bar.
  Enable 'HttpService.HttpEnabled = true' in Game Settings.
]]

local HttpService = game:GetService("HttpService")
local CLOUD_URL = "${cloudUrl}"

print("🚀 Starting AI Studio Direct Autonomous Plugin...")

local function executeAction(action)
    local actionType = action.type
    local targetPath = action.targetPath
    local sourceCode = action.sourceCode
    local className = action.className or "Script"
    local properties = action.properties or {}
    
    print("⚡ Executing action: " .. actionType .. " on " .. targetPath)
    
    -- Navigate or create instance
    local parts = string.split(targetPath, ".")
    local current = game
    for i = 2, #parts - 1 do
        local segment = parts[i]
        local nextChild = current:FindFirstChild(segment)
        if not nextChild then
            nextChild = Instance.new("Folder")
            nextChild.Name = segment
            nextChild.Parent = current
        end
        current = nextChild
    end
    
    local itemName = parts[#parts]
    local target = current:FindFirstChild(itemName)
    
    if actionType == "create_instance" or actionType == "set_script_source" then
        if not target then
            target = Instance.new(className)
            target.Name = itemName
            target.Parent = current
        end
        if sourceCode and (target:IsA("LuaSourceContainer") or target:IsA("Script") or target:IsA("ModuleScript") or target:IsA("LocalScript")) then
            target.Source = sourceCode
        end
        return { success = true, result = "Successfully created/updated " .. targetPath }
    elseif actionType == "delete_instance" then
        if target then
            target:Destroy()
            return { success = true, result = "Deleted " .. targetPath }
        end
        return { success = true, result = "Target already absent: " .. targetPath }
    end
    
    return { success = true, result = "Completed " .. actionType }
end

task.spawn(function()
    while true do
        local success, response = pcall(function()
            return HttpService:GetAsync(CLOUD_URL .. "/api/bridge/poll")
        end)
        
        if success and response then
            local data = HttpService:JSONDecode(response)
            if data.hasAction and data.action then
                local execSuccess, execResult = pcall(function()
                    return executeAction(data.action)
                end)
                
                local payload = {
                    actionId = data.action.id,
                    success = execSuccess and execResult.success,
                    result = execSuccess and execResult.result or tostring(execResult),
                    error = not execSuccess and tostring(execResult) or nil,
                    autoFix = true
                }
                
                pcall(function()
                    HttpService:PostAsync(CLOUD_URL .. "/api/bridge/result", HttpService:JSONEncode(payload))
                end)
            end
        end
        task.wait(1.5)
    end
end)
`;

  res.json({
    cloudUrl,
    nodeBridgeScript,
    pythonBridgeScript,
    robloxStudioPluginLuau,
  });
});

// ----------------------------------------------------
// Vite Middleware / Production static serving
// ----------------------------------------------------
async function start() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Roblox Studio Autonomous Bridge Server running at http://0.0.0.0:${PORT}`);
  });
}

start();
