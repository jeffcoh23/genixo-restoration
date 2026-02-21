import { Link, usePage } from "@inertiajs/react";
import { AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { SharedProps } from "@/types";

export default function InvitationExpired() {
  const { routes } = usePage<SharedProps>().props;

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <Card className="w-full max-w-md">
        <CardContent className="text-center p-8">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-muted">
            <AlertCircle className="h-6 w-6 text-muted-foreground" />
          </div>
          <h1 className="text-2xl font-semibold text-foreground mb-2">Invitation Expired</h1>
          <p className="text-muted-foreground mb-6">
            This invitation is no longer valid. Please contact your administrator to request a new one.
          </p>
          <Button asChild>
            <Link href={routes.login}>Go to Login</Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
