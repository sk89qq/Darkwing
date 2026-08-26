export interface RobloxAction {
  id: string;
  type: 'create_instance' | 'set_script_source' | 'set_properties' | 'delete_instance' | string;
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

export interface RobloxInstanceNode {
  id: string;
  name: string;
  className: string;
  path: string;
  properties?: Record<string, any>;
  sourceCode?: string;
  children?: RobloxInstanceNode[];
}

export interface LogEntry {
  id: string;
  timestamp: number;
  level: 'info' | 'warn' | 'error' | 'ai' | 'bridge';
  message: string;
  details?: any;
  actionId?: string;
}

export interface BridgeStatus {
  connected: boolean;
  lastPing: number;
  bridgeType: string;
  agentName?: string;
  totalExecuted: number;
  pendingCount: number;
}

export interface GenerationPlan {
  title: string;
  summary: string;
  actions: RobloxAction[];
}
