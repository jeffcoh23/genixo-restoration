import { Link } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";

interface ErrorProps {
  status: number;
  message?: string;
}

const TITLES: Record<number, string> = {
  404: "Page not found",
  500: "Server error",
};

const DESCRIPTIONS: Record<number, string> = {
  404: "The page you're looking for doesn't exist or has been moved.",
  500: "Something went wrong on our end. Please try again later.",
};

export default function Error({ status, message }: ErrorProps) {
  const title = message || TITLES[status] || "Something went wrong";
  const description = DESCRIPTIONS[status] || "An unexpected error occurred.";

  return (
    <AppLayout>
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <span className="text-6xl font-bold text-muted-foreground/30 mb-4">{status}</span>
        <h1 className="text-2xl font-bold text-foreground mb-2">{title}</h1>
        <p className="text-muted-foreground mb-8 max-w-md">{description}</p>
        <div className="flex gap-3">
          <button
            onClick={() => window.history.back()}
            className="inline-flex items-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground hover:bg-accent transition-colors"
          >
            Go back
          </button>
          <Link
            href="/incidents"
            className="inline-flex items-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
          >
            Go to incidents
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}
