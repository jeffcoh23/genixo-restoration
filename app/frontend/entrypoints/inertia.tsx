import { createInertiaApp } from "@inertiajs/react";
import { createRoot } from "react-dom/client";

function applyMobileShellClass() {
  const win = window as Window & { Capacitor?: unknown };
  const root = document.documentElement;

  if (win.Capacitor) {
    root.classList.add("capacitor-shell");
  } else {
    root.classList.remove("capacitor-shell");
  }
}

createInertiaApp({
  resolve: (name: string) => {
    const pages = import.meta.glob("../pages/**/*.tsx", { eager: true }) as Record<
      string,
      { default: React.ComponentType }
    >;
    const page = pages[`../pages/${name}.tsx`];
    if (!page) {
      return pages["../pages/Error.tsx"];
    }
    return page;
  },
  setup({ el, App, props }) {
    applyMobileShellClass();
    createRoot(el).render(<App {...props} />);
  },
});
