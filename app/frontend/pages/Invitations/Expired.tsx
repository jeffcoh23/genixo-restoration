import { usePage } from "@inertiajs/react";
import { SharedProps } from "@/types";

export default function InvitationExpired() {
  const { routes } = usePage<SharedProps>().props;

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-md text-center">
        <h1 className="text-2xl font-semibold text-foreground mb-2">Invitation Expired</h1>
        <p className="text-muted-foreground mb-6">
          This invitation is no longer valid. Please contact your administrator to request a new one.
        </p>
        <a
          href={routes.login}
          className="text-primary hover:underline text-sm"
        >
          Go to Login
        </a>
      </div>
    </div>
  );
}
