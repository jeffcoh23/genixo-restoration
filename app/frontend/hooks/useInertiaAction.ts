import { router } from "@inertiajs/react";
import { useState } from "react";

type ErrorBag = Record<string, unknown>;

type ActionOptions = {
  preserveScroll?: boolean;
  preserveState?: boolean;
  forceFormData?: boolean;
  async?: boolean;
  errorMessage?: string;
  successMessage?: string | null;
  onSuccess?: () => void;
  onError?: (errors: ErrorBag) => void;
  onFinish?: () => void;
};

function extractFirstString(value: unknown): string | null {
  if (!value) return null;
  if (typeof value === "string") return value;
  if (Array.isArray(value)) {
    for (const item of value) {
      const message = extractFirstString(item);
      if (message) return message;
    }
    return null;
  }
  if (typeof value === "object") {
    for (const item of Object.values(value as Record<string, unknown>)) {
      const message = extractFirstString(item);
      if (message) return message;
    }
  }
  return null;
}

export function extractInertiaErrorMessage(errors: unknown, fallback = "Something went wrong. Please try again."): string {
  return extractFirstString(errors) ?? fallback;
}

export default function useInertiaAction() {
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const clearFeedback = () => {
    setError(null);
    setNotice(null);
  };

  const buildVisitOptions = (options: ActionOptions = {}) => {
    const {
      errorMessage,
      successMessage,
      onSuccess,
      onError,
      onFinish,
      preserveScroll = true,
      preserveState,
      forceFormData,
      async,
    } = options;

    return {
      preserveScroll,
      ...(preserveState === undefined ? {} : { preserveState }),
      ...(forceFormData === undefined ? {} : { forceFormData }),
      ...(async === undefined ? {} : { async }),
      onSuccess: () => {
        setError(null);
        setNotice(successMessage ?? null);
        onSuccess?.();
      },
      onError: (errors: ErrorBag) => {
        setError(extractInertiaErrorMessage(errors, errorMessage));
        setNotice(null);
        onError?.(errors);
      },
      onFinish: () => {
        setProcessing(false);
        onFinish?.();
      },
    };
  };

  const runPost = (url: string, data: unknown, options?: ActionOptions) => {
    setProcessing(true);
    clearFeedback();
    router.post(url, data as never, buildVisitOptions(options) as never);
  };

  const runPatch = (url: string, data: unknown, options?: ActionOptions) => {
    setProcessing(true);
    clearFeedback();
    router.patch(url, data as never, buildVisitOptions(options) as never);
  };

  const runDelete = (url: string, data?: unknown, options?: ActionOptions) => {
    setProcessing(true);
    clearFeedback();
    const visitOptions = buildVisitOptions(options);
    router.delete(url, (data ? { ...visitOptions, data } : visitOptions) as never);
  };

  return {
    processing,
    error,
    notice,
    setError,
    setNotice,
    clearFeedback,
    runPost,
    runPatch,
    runDelete,
  };
}
