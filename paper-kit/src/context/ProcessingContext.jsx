/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useCallback } from 'react';
import { execute, determineRoute, DEFAULT_ROUTER_CONFIG } from '../services/processingRouter';
import './ProcessingOverlay.css';

const ProcessingContext = createContext(null);

export function useProcessing() {
  const context = useContext(ProcessingContext);
  if (!context) {
    throw new Error('useProcessing must be used within a ProcessingProvider');
  }
  return context;
}

export function ProcessingProvider({ children }) {
  // Load configuration from localStorage
  const [config, setConfig] = useState(() => {
    try {
      const saved = localStorage.getItem('pk_router_settings');
      return saved ? JSON.parse(saved) : DEFAULT_ROUTER_CONFIG;
    } catch {
      return DEFAULT_ROUTER_CONFIG;
    }
  });

  // Active execution state
  const [activeTask, setActiveTask] = useState(null); 
  /* 
    activeTask = {
      operationId: string,
      status: 'idle' | 'routing' | 'running' | 'completed' | 'failed',
      route: 'LOCAL' | 'BACKEND' | 'CLOUD' | null,
      reason: string | null,
      progress: number,
      statusText: string,
      error: string | null,
      result: any | null,
      logs: Array<{ time: string, msg: string }>,
      fileCount: number,
      totalSize: number
    }
  */

  const updateConfig = useCallback((newConfig) => {
    setConfig(prev => {
      const updated = { ...prev, ...newConfig };
      localStorage.setItem('pk_router_settings', JSON.stringify(updated));
      return updated;
    });
  }, []);

  const _addLog = useCallback((msg) => {
    const time = new Date().toLocaleTimeString();
    setActiveTask(prev => prev ? { ...prev, logs: [...prev.logs, { time, msg }] } : null);
  }, []);

  const runProcessing = useCallback(async (opOrConfig, inputs = {}, options = {}) => {
    // Dynamic task callback format: { jobType, title, task }
    if (typeof opOrConfig === 'object' && opOrConfig.task) {
      const { jobType = 'task', title = 'Processing Document...', task } = opOrConfig;
      const initialTask = {
        operationId: jobType,
        status: 'running',
        route: 'LOCAL',
        reason: 'Direct Engine Execution',
        progress: 15,
        statusText: title,
        error: null,
        result: null,
        logs: [{ time: new Date().toLocaleTimeString(), msg: `Initiating ${title}` }],
        fileCount: 1,
        totalSize: 0
      };
      setActiveTask(initialTask);

      const updateProgress = (pct, text) => {
        setActiveTask(prev => {
          if (!prev) return null;
          const logTime = new Date().toLocaleTimeString();
          return {
            ...prev,
            progress: pct,
            statusText: text || prev.statusText,
            logs: text ? [...prev.logs, { time: logTime, msg: text }] : prev.logs
          };
        });
      };

      try {
        const res = await task(updateProgress);
        setActiveTask(prev => prev ? {
          ...prev,
          status: 'completed',
          progress: 100,
          statusText: 'Operation completed successfully!',
          result: res,
          logs: [...prev.logs, { time: new Date().toLocaleTimeString(), msg: 'Job executed successfully.' }]
        } : null);
        return res;
      } catch (err) {
        const errMsg = err?.message || 'Processing failed';
        setActiveTask(prev => prev ? {
          ...prev,
          status: 'failed',
          error: errMsg,
          statusText: 'Processing failed.',
          logs: [...prev.logs, { time: new Date().toLocaleTimeString(), msg: `Error: ${errMsg}` }]
        } : null);
        throw err;
      }
    }

    const operationId = typeof opOrConfig === 'string' ? opOrConfig : (opOrConfig?.operationId || 'process');

    // Collect stats on inputs
    const filesList = [];
    for (const val of Object.values(inputs)) {
      if (val instanceof File) {
        filesList.push(val);
      } else if (Array.isArray(val)) {
        val.forEach(item => {
          if (item instanceof File) filesList.push(item);
        });
      }
    }
    const fileCount = filesList.length;
    const totalSize = filesList.reduce((sum, f) => sum + (f?.size || 0), 0);

    // Initial state
    const initialTask = {
      operationId,
      status: 'routing',
      route: null,
      reason: null,
      progress: 10,
      statusText: 'Connecting to processing service...',
      error: null,
      result: null,
      logs: [{ time: new Date().toLocaleTimeString(), msg: 'Dispatching service request...' }],
      fileCount,
      totalSize
    };

    setActiveTask(initialTask);


    try {
      // 1. Determine routing details
      const routeInfo = determineRoute(operationId, filesList, config);
      setActiveTask(prev => ({
        ...prev,
        route: routeInfo.route,
        reason: routeInfo.reason,
        statusText: `Routed to ${routeInfo.route} engine.`
      }));

      const time = new Date().toLocaleTimeString();
      initialTask.logs.push({ time, msg: `Routed to ${routeInfo.route} Engine. Reason: ${routeInfo.reason}` });

      if (routeInfo.route === 'LOCAL' && !routeInfo.allowed) {
        throw new Error(routeInfo.reason);
      }

      // 2. Execute
      const result = await execute(
        operationId,
        inputs,
        options,
        (progress) => {
          setActiveTask(prev => prev ? { ...prev, progress } : null);
        },
        (statusText) => {
          setActiveTask(prev => {
            if (!prev) return null;
            const logTime = new Date().toLocaleTimeString();
            return {
              ...prev,
              statusText,
              logs: [...prev.logs, { time: logTime, msg: statusText }]
            };
          });
        },
        config
      );

      // Auto-sync local output file to cloud storage & history database
      if (result) {
        const syncAsset = async (asset) => {
          try {
            let blobToUpload = asset.blob;
            if (!blobToUpload && asset.download_url && asset.download_url.startsWith('blob:')) {
              const res = await fetch(asset.download_url);
              blobToUpload = await res.blob();
            }
            if (blobToUpload) {
              const filename = asset.filename || `${operationId}_${Date.now()}.pdf`;
              const fileObj = new File([blobToUpload], filename, { type: blobToUpload.type || 'application/pdf' });
              const { uploadFile } = await import('../services/files');
              await uploadFile(fileObj);
            }
          } catch (err) {
            console.warn('Auto-syncing output to history failed:', err);
          }
        };

        if (Array.isArray(result)) {
          result.forEach(syncAsset);
        } else if (result.download_url) {
          syncAsset(result);
        }
      }

      // Auto-clear activeTask on successful completion
      setActiveTask(null);
      return result;
    } catch (err) {
      setActiveTask(null);
      throw err;
    }
  }, [config]);

  const clearActiveTask = useCallback(() => {
    setActiveTask(null);
  }, []);

  return (
    <ProcessingContext.Provider value={{ config, updateConfig, activeTask, runProcessing, clearActiveTask }}>
      {children}
      {activeTask && (
        <ProcessingOverlay task={activeTask} />
      )}
    </ProcessingContext.Provider>
  );
}

function ProcessingOverlay({ task }) {
  if (!task) return null;

  return (
    <div className="processing-overlay" role="status" aria-live="polite">
      <div className="processing-tag-pill">
        <span className="processing-tag-dot" />
        <span className="processing-tag-text">MASKERV Processing....</span>
      </div>
    </div>
  );
}
