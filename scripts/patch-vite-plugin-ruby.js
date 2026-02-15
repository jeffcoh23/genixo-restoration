// Patches vite-plugin-ruby to fix `this.meta` TypeError
// See: https://github.com/ElMassimo/vite_ruby/issues — this.meta is undefined in config hook
import { readFileSync, writeFileSync } from "fs";

const path = "./node_modules/vite-plugin-ruby/dist/index.js";
try {
  let code = readFileSync(path, "utf8");
  const search = "const isUsingRolldown = this.meta && this.meta.rolldownVersion;";
  if (code.includes(search)) {
    code = code.replace(search, "const isUsingRolldown = this?.meta?.rolldownVersion;");
    writeFileSync(path, code);
    console.log("Patched vite-plugin-ruby (this.meta fix)");
  }
} catch {
  // Skip if file doesn't exist yet (first install)
}
