import { Link, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import AppLayout from "@/layout/AppLayout";
import { SharedProps } from "@/types";

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
  const { routes } = usePage<SharedProps>().props;
  const title = message || TITLES[status] || "Something went wrong";
  const description = DESCRIPTIONS[status] || "An unexpected error occurred.";

  return (
    <AppLayout>
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <span className="text-6xl font-bold text-muted-foreground/30 mb-4">{status}</span>
        <h1 className="text-2xl font-bold text-foreground mb-2">{title}</h1>
        <p className="text-muted-foreground mb-8 max-w-md">{description}</p>
        <div className="flex gap-3">
          <Button variant="outline" onClick={() => window.history.back()}>
            Go back
          </Button>
          <Button asChild>
            <Link href={routes.incidents}>Go to incidents</Link>
          </Button>
        </div>
      </div>
    </AppLayout>
  );
}
