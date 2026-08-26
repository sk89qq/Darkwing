import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { 
  Box, 
  Layers, 
  Maximize2, 
  RotateCcw, 
  Sun, 
  Moon, 
  Eye, 
  Sparkles, 
  Sliders,
  Play
} from 'lucide-react';
import { RobloxInstanceNode } from '../types';

interface Workspace3DViewportProps {
  rootNode: RobloxInstanceNode;
  onSelectInstance?: (node: RobloxInstanceNode) => void;
  selectedPath?: string;
}

export const Workspace3DViewport: React.FC<Workspace3DViewportProps> = ({
  rootNode,
  onSelectInstance,
  selectedPath,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null);
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const meshMapRef = useRef<Map<string, THREE.Object3D>>(new Map());

  const [timeOfDay, setTimeOfDay] = useState<'day' | 'night'>('day');
  const [cameraMode, setCameraMode] = useState<'orbit' | 'isometric'>('orbit');
  const [partCount, setPartCount] = useState<number>(0);

  // Orbit controls state
  const isDraggingRef = useRef(false);
  const isPanningRef = useRef(false);
  const previousMousePositionRef = useRef({ x: 0, y: 0 });
  const cameraTargetRef = useRef(new THREE.Vector3(0, 2, 0));
  const sphericalRef = useRef({ radius: 45, phi: Math.PI / 4, theta: Math.PI / 4 });

  // Initialize Three.js scene
  useEffect(() => {
    if (!containerRef.current) return;
    const container = containerRef.current;
    const width = container.clientWidth || 600;
    const height = container.clientHeight || 380;

    // 1. Scene
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0f172a);
    scene.fog = new THREE.FogExp2(0x0f172a, 0.012);
    sceneRef.current = scene;

    // 2. Camera
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.5, 500);
    updateCameraPosition(camera, sphericalRef.current, cameraTargetRef.current);
    cameraRef.current = camera;

    // 3. Renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: 'high-performance' });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.1;
    container.innerHTML = '';
    container.appendChild(renderer.domElement);
    rendererRef.current = renderer;

    // 4. Studio Lighting & Grid
    setupEnvironmentLighting(scene, timeOfDay);

    // 5. Studio Grid Floor (Roblox Baseplate Grid)
    const grid = new THREE.GridHelper(200, 50, 0xe11d48, 0x334155);
    grid.position.y = -0.01;
    scene.add(grid);

    // 6. Raycaster for clicking 3D parts
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    const handlePointerDown = (e: PointerEvent) => {
      if (e.button === 0) isDraggingRef.current = true;
      if (e.button === 2) isPanningRef.current = true;
      previousMousePositionRef.current = { x: e.clientX, y: e.clientY };
    };

    const handlePointerMove = (e: PointerEvent) => {
      const deltaX = e.clientX - previousMousePositionRef.current.x;
      const deltaY = e.clientY - previousMousePositionRef.current.y;
      previousMousePositionRef.current = { x: e.clientX, y: e.clientY };

      if (isDraggingRef.current) {
        sphericalRef.current.theta -= deltaX * 0.008;
        sphericalRef.current.phi = Math.max(0.1, Math.min(Math.PI / 2 - 0.05, sphericalRef.current.phi - deltaY * 0.008));
        if (cameraRef.current) {
          updateCameraPosition(cameraRef.current, sphericalRef.current, cameraTargetRef.current);
        }
      } else if (isPanningRef.current) {
        const panSpeed = 0.05;
        cameraTargetRef.current.x -= deltaX * panSpeed;
        cameraTargetRef.current.z -= deltaY * panSpeed;
        if (cameraRef.current) {
          updateCameraPosition(cameraRef.current, sphericalRef.current, cameraTargetRef.current);
        }
      }
    };

    const handlePointerUp = (e: PointerEvent) => {
      // If was a quick click without much drag, raycast to select instance
      const dist = Math.hypot(
        e.clientX - previousMousePositionRef.current.x,
        e.clientY - previousMousePositionRef.current.y
      );

      if (isDraggingRef.current && dist < 5 && containerRef.current && onSelectInstance) {
        const rect = containerRef.current.getBoundingClientRect();
        mouse.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
        if (cameraRef.current && sceneRef.current) {
          raycaster.setFromCamera(mouse, cameraRef.current);
          const intersects = raycaster.intersectObjects(sceneRef.current.children, true);
          if (intersects.length > 0) {
            let hit = intersects[0].object;
            while (hit && !hit.userData?.instanceNode && hit.parent) {
              hit = hit.parent as THREE.Mesh;
            }
            if (hit && hit.userData?.instanceNode) {
              onSelectInstance(hit.userData.instanceNode);
            }
          }
        }
      }

      isDraggingRef.current = false;
      isPanningRef.current = false;
    };

    const handleWheel = (e: WheelEvent) => {
      e.preventDefault();
      sphericalRef.current.radius = Math.max(10, Math.min(150, sphericalRef.current.radius + e.deltaY * 0.05));
      if (cameraRef.current) {
        updateCameraPosition(cameraRef.current, sphericalRef.current, cameraTargetRef.current);
      }
    };

    const handleContextMenu = (e: MouseEvent) => e.preventDefault();

    container.addEventListener('pointerdown', handlePointerDown);
    window.addEventListener('pointermove', handlePointerMove);
    window.addEventListener('pointerup', handlePointerUp);
    container.addEventListener('wheel', handleWheel, { passive: false });
    container.addEventListener('contextmenu', handleContextMenu);

    // Resize observer
    const resizeObserver = new ResizeObserver(() => {
      if (!containerRef.current || !rendererRef.current || !cameraRef.current) return;
      const w = containerRef.current.clientWidth;
      const h = containerRef.current.clientHeight;
      cameraRef.current.aspect = w / h;
      cameraRef.current.updateProjectionMatrix();
      rendererRef.current.setSize(w, h);
    });
    resizeObserver.observe(container);

    // Animation Loop
    let clock = new THREE.Clock();
    const animate = () => {
      animationFrameRef.current = requestAnimationFrame(animate);
      const elapsedTime = clock.getElapsedTime();

      // Animate rotating coins and glowing items
      meshMapRef.current.forEach((obj, key) => {
        if (key.toLowerCase().includes('coin')) {
          obj.rotation.z = elapsedTime * 2;
          obj.position.y += Math.sin(elapsedTime * 3 + obj.position.x) * 0.005;
        }
      });

      if (rendererRef.current && sceneRef.current && cameraRef.current) {
        rendererRef.current.render(sceneRef.current, cameraRef.current);
      }
    };
    animate();

    return () => {
      if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current);
      container.removeEventListener('pointerdown', handlePointerDown);
      window.removeEventListener('pointermove', handlePointerMove);
      window.removeEventListener('pointerup', handlePointerUp);
      container.removeEventListener('wheel', handleWheel);
      container.removeEventListener('contextmenu', handleContextMenu);
      resizeObserver.disconnect();
      renderer.dispose();
    };
  }, []);

  // Update Environment Lighting when timeOfDay changes
  useEffect(() => {
    if (!sceneRef.current) return;
    setupEnvironmentLighting(sceneRef.current, timeOfDay);
  }, [timeOfDay]);

  // Sync Roblox DataModel Instances into 3D Mesh representations
  useEffect(() => {
    if (!sceneRef.current) return;
    const scene = sceneRef.current;

    // Remove old instance meshes (keep lights and grid)
    meshMapRef.current.forEach((obj) => {
      scene.remove(obj);
    });
    meshMapRef.current.clear();

    // Find Workspace in tree
    const workspaceNode = findNodeByPath(rootNode, 'game.Workspace');
    if (!workspaceNode) return;

    let count = 0;
    const spawnMeshes = (node: RobloxInstanceNode) => {
      if (node.className === 'Part' || node.className === 'SpawnLocation' || node.className === 'Model') {
        const mesh = createMeshForRobloxInstance(node);
        if (mesh) {
          scene.add(mesh);
          meshMapRef.current.set(node.path, mesh);
          count++;
        }
      }
      if (node.children) {
        node.children.forEach(spawnMeshes);
      }
    };

    if (workspaceNode.children) {
      workspaceNode.children.forEach(spawnMeshes);
    }
    setPartCount(count);
  }, [rootNode, selectedPath]);

  // Helper to setup realistic Roblox Studio lighting
  const setupEnvironmentLighting = (scene: THREE.Scene, mode: 'day' | 'night') => {
    // Remove existing lights
    const existingLights = scene.children.filter(c => c instanceof THREE.Light);
    existingLights.forEach(l => scene.remove(l));

    if (mode === 'day') {
      scene.background = new THREE.Color(0x0f172a);
      scene.fog = new THREE.FogExp2(0x0f172a, 0.008);

      const ambient = new THREE.AmbientLight(0xdbeafe, 0.8);
      scene.add(ambient);

      const sun = new THREE.DirectionalLight(0xffedd5, 1.6);
      sun.position.set(35, 60, 25);
      sun.castShadow = true;
      sun.shadow.mapSize.width = 2048;
      sun.shadow.mapSize.height = 2048;
      sun.shadow.camera.near = 0.5;
      sun.shadow.camera.far = 150;
      sun.shadow.camera.left = -50;
      sun.shadow.camera.right = 50;
      sun.shadow.camera.top = 50;
      sun.shadow.camera.bottom = -50;
      scene.add(sun);

      const hemisphere = new THREE.HemisphereLight(0x38bdf8, 0x1e293b, 0.4);
      scene.add(hemisphere);
    } else {
      scene.background = new THREE.Color(0x030712);
      scene.fog = new THREE.FogExp2(0x030712, 0.015);

      const ambient = new THREE.AmbientLight(0x38bdf8, 0.25);
      scene.add(ambient);

      const moon = new THREE.DirectionalLight(0x818cf8, 0.6);
      moon.position.set(-25, 45, -20);
      moon.castShadow = true;
      scene.add(moon);
    }
  };

  const handleResetCamera = () => {
    sphericalRef.current = { radius: 45, phi: Math.PI / 4, theta: Math.PI / 4 };
    cameraTargetRef.current.set(0, 2, 0);
    if (cameraRef.current) {
      updateCameraPosition(cameraRef.current, sphericalRef.current, cameraTargetRef.current);
    }
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 shadow-xl shadow-black/40 flex flex-col">
      {/* Header Controls */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Box className="w-4 h-4 text-rose-400" />
          <h3 className="text-sm font-semibold text-white">
            Roblox Studio 3D Live Viewport
          </h3>
          <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-rose-300 font-mono border border-slate-700">
            {partCount} 3D Instances
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          {/* Day / Night Toggle */}
          <button
            onClick={() => setTimeOfDay(timeOfDay === 'day' ? 'night' : 'day')}
            title="Toggle Day/Night Lighting"
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 transition-colors text-xs flex items-center gap-1"
          >
            {timeOfDay === 'day' ? (
              <>
                <Sun className="w-3.5 h-3.5 text-amber-400" />
                <span className="hidden sm:inline text-[11px]">Day</span>
              </>
            ) : (
              <>
                <Moon className="w-3.5 h-3.5 text-indigo-400" />
                <span className="hidden sm:inline text-[11px]">Night</span>
              </>
            )}
          </button>

          {/* Reset Camera */}
          <button
            onClick={handleResetCamera}
            title="Reset Camera View"
            className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 transition-colors"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* 3D Canvas Container */}
      <div 
        ref={containerRef} 
        className="w-full h-[320px] sm:h-[380px] bg-slate-950 rounded-xl overflow-hidden relative cursor-grab active:cursor-grabbing border border-slate-800"
      >
        {/* Floating Overlay Info */}
        <div className="absolute top-3 left-3 pointer-events-none bg-slate-900/80 backdrop-blur-md px-3 py-1.5 rounded-lg border border-slate-800 text-[11px] font-mono text-slate-300 flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>Left-Drag: Rotate &bull; Right-Drag: Pan &bull; Scroll: Zoom</span>
        </div>
      </div>
    </div>
  );
};

// Helper Functions
function updateCameraPosition(
  camera: THREE.PerspectiveCamera,
  spherical: { radius: number; phi: number; theta: number },
  target: THREE.Vector3
) {
  const x = target.x + spherical.radius * Math.sin(spherical.phi) * Math.sin(spherical.theta);
  const y = target.y + spherical.radius * Math.cos(spherical.phi);
  const z = target.z + spherical.radius * Math.sin(spherical.phi) * Math.cos(spherical.theta);
  camera.position.set(x, y, z);
  camera.lookAt(target);
}

function findNodeByPath(node: RobloxInstanceNode, path: string): RobloxInstanceNode | null {
  if (node.path === path) return node;
  if (node.children) {
    for (const child of node.children) {
      const res = findNodeByPath(child, path);
      if (res) return res;
    }
  }
  return null;
}

function createMeshForRobloxInstance(node: RobloxInstanceNode): THREE.Object3D | null {
  const name = node.name.toLowerCase();
  const group = new THREE.Group();
  group.userData = { instanceNode: node };

  // Baseplate
  if (name.includes('baseplate')) {
    const geo = new THREE.BoxGeometry(60, 0.8, 60);
    const mat = new THREE.MeshStandardMaterial({
      color: 0x334155,
      roughness: 0.8,
      metalness: 0.1,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(0, -0.4, 0);
    mesh.receiveShadow = true;
    group.add(mesh);
    return group;
  }

  // SpawnLocation
  if (name.includes('spawn') || node.className === 'SpawnLocation') {
    const geo = new THREE.BoxGeometry(6, 0.4, 6);
    const mat = new THREE.MeshStandardMaterial({
      color: 0x0284c7,
      roughness: 0.3,
      metalness: 0.2,
      emissive: 0x0369a1,
      emissiveIntensity: 0.3,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(0, 0.2, 0);
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    group.add(mesh);

    // Spawn symbol decal on top
    const decalGeo = new THREE.PlaneGeometry(3, 3);
    const decalMat = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.85,
      side: THREE.DoubleSide
    });
    const decalMesh = new THREE.Mesh(decalGeo, decalMat);
    decalMesh.rotation.x = -Math.PI / 2;
    decalMesh.position.set(0, 0.41, 0);
    group.add(decalMesh);
    return group;
  }

  // Gold Collectible Coins
  if (name.includes('coin') || name.includes('gold')) {
    const geo = new THREE.CylinderGeometry(0.9, 0.9, 0.25, 24);
    const mat = new THREE.MeshStandardMaterial({
      color: 0xf59e0b,
      metalness: 0.9,
      roughness: 0.2,
      emissive: 0xd97706,
      emissiveIntensity: 0.5,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = Math.PI / 2;
    mesh.castShadow = true;
    group.add(mesh);

    // Glowing halo
    const glowGeo = new THREE.SphereGeometry(1.2, 16, 16);
    const glowMat = new THREE.MeshBasicMaterial({
      color: 0xfbbf24,
      transparent: true,
      opacity: 0.15,
      wireframe: true,
    });
    const glow = new THREE.Mesh(glowGeo, glowMat);
    group.add(glow);

    // Position around baseplate
    const idx = Math.abs(hashString(node.path)) % 10;
    const angle = (idx / 10) * Math.PI * 2;
    const radius = 14;
    group.position.set(Math.cos(angle) * radius, 1.8, Math.sin(angle) * radius);
    return group;
  }

  // Generic Part or Model
  const geo = new THREE.BoxGeometry(3, 3, 3);
  const mat = new THREE.MeshStandardMaterial({
    color: 0xe11d48,
    metalness: 0.3,
    roughness: 0.4,
  });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.set(5, 1.5, -5);
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  group.add(mesh);
  return group;
}

function hashString(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
  }
  return hash;
}
