import { Link } from "@inertiajs/react";
import { Button } from "@/components/ui/button";

interface PageHeaderProps {
  title: string;
  backLink?: { href: string; label: string };
  action?: { href?: string; label: string; onClick?: () => void };
}

export default function PageHeader({ title, backLink, action }: PageHeaderProps) {
  return (
    <>
      {backLink && (
        <div className="mb-6">
          <Link href={backLink.href} className="text-sm text-muted-foreground hover:text-foreground">
            &larr; {backLink.label}
          </Link>
        </div>
      )}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold text-foreground">{title}</h1>
        {action && (
          action.href ? (
            <Button asChild>
              <Link href={action.href}>{action.label}</Link>
            </Button>
          ) : (
            <Button onClick={action.onClick}>{action.label}</Button>
          )
        )}
      </div>
    </>
  );
}
