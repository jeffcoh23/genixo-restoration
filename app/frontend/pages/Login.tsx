import { Link, useForm, usePage } from "@inertiajs/react";
import { Phone } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { FormEvent } from "react";

interface FlashMessages {
  alert?: string;
  notice?: string;
}

interface Props extends Record<string, unknown> {
  flash: FlashMessages;
  forgot_password_path: string;
  report_incident_path: string;
  emergency_phone: string | null;
}

export default function Login() {
  const { flash, forgot_password_path, report_incident_path, emergency_phone } = usePage<Props>().props;
  const { data, setData, post, processing, errors } = useForm({
    email_address: "",
    password: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post("/login");
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background px-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="pb-2">
          <div className="mx-auto mb-2">
            <img src="/brand/genixo-horizontal-dark.png" alt="Genixo Restoration" className="h-10" />
          </div>
        </CardHeader>
        <CardContent>
          {flash.alert && (
            <Alert variant="destructive" className="mb-4 p-3">
              <AlertDescription>{flash.alert}</AlertDescription>
            </Alert>
          )}
          {flash.notice && (
            <Alert className="mb-4 p-3 border-primary/30 bg-primary/10">
              <AlertDescription>{flash.notice}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email_address">Email</Label>
              <Input
                id="email_address"
                type="email"
                autoComplete="email"
                autoFocus
                value={data.email_address}
                onChange={(e) => setData("email_address", e.target.value)}
              />
              {errors.email_address && (
                <p className="text-sm text-destructive">{errors.email_address}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={data.password}
                onChange={(e) => setData("password", e.target.value)}
              />
              {errors.password && (
                <p className="text-sm text-destructive">{errors.password}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? "Signing in..." : "Sign In"}
            </Button>
          </form>

          <div className="mt-4 text-center">
            <Link href={forgot_password_path} className="text-sm text-muted-foreground hover:text-foreground">
              Forgot password?
            </Link>
          </div>

          <div className="mt-6 pt-4 border-t border-border text-center space-y-2">
            <Link
              href={report_incident_path}
              className="text-sm font-medium text-primary hover:text-primary/80"
            >
              Report an Incident
            </Link>
            {emergency_phone && (
              <div className="flex items-center justify-center gap-1.5 text-xs text-muted-foreground">
                <Phone className="h-3 w-3" />
                <span>Emergency: </span>
                <a
                  href={`tel:${emergency_phone.replace(/\D/g, "")}`}
                  className="font-semibold text-destructive hover:underline"
                >
                  {emergency_phone}
                </a>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
