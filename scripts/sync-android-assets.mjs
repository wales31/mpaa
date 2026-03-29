import { cp, mkdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const distDir = path.join(projectRoot, 'dist');
const assetsDir = path.join(projectRoot, 'android', 'app', 'src', 'main', 'assets');

await rm(assetsDir, { recursive: true, force: true });
await mkdir(assetsDir, { recursive: true });
await cp(distDir, assetsDir, { recursive: true });

console.log(`Copied ${distDir} -> ${assetsDir}`);
