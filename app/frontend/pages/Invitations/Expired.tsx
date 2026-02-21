import { Link, usePage } from "@inertiajs/react";
import { AlertCircle } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";

export default function InvitationExpired() {
  const { routes } = usePage<SharedProps>().props;

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <Card className="w-full max-w-md">
        <CardContent className="pt-8 pb-6 px-6 text-center">
          <AlertCircle className="h-10 w-10 text-muted-foreground mx-auto mb-4" />
          <h1 className="text-xl font-semibold text-foreground mb-2">Invitation Expired</h1>
          <p className="text-sm text-muted-foreground mb-6">
            This invitation is no longer valid. Please contact your administrator to request a new one.
          </p>
          <Button variant="outline" asChild>
            <Link href={routes.login}>Go to Login</Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
