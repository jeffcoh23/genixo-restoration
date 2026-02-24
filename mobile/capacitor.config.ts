import type { CapacitorConfig } from "@capacitor/cli";

const remoteUrl =
  process.env.GENIXO_MOBILE_WEB_URL ||
  "https://genixo-restoration-eff44db79cc1.herokuapp.com";

// This wrapper intentionally loads the existing hosted Rails/Inertia app.
// We keep a local webDir placeholder (`www`) so native projects can be generated
// and still have an offline/error fallback file available.
const config: CapacitorConfig = {
  appId: "com.genixo.restoration",
  appName: "Genixo Restoration",
  webDir: "www",
  loggingBehavior: "debug",
  backgroundColor: "#eef2f5",
  server: {
    url: remoteUrl
  },
  ios: {
    contentInset: "automatic",
    allowsLinkPreview: false,
    preferredContentMode: "mobile"
  },
  android: {
    allowMixedContent: false
  }
};

export default config;
