import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import reactHooks from "eslint-plugin-react-hooks";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: {
      "react-hooks": reactHooks,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      // Allow underscore-prefixed unused vars (convention for intentionally unused)
      "@typescript-eslint/no-unused-vars": ["warn", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
      }],
      // Allow empty interfaces (common for extending)
      "@typescript-eslint/no-empty-object-type": "off",
      // Downgrade — setState in effect is fine for prop-driven visibility patterns
      "react-hooks/set-state-in-effect": "warn",
    },
  },
  {
    ignores: [
      "node_modules/",
      "public/",
      "vendor/",
      "tmp/",
      "app/frontend/components/ui/", // shadcn generated components
    ],
  }
);
