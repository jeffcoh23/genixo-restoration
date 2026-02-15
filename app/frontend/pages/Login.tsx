import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { FormEvent } from "react";

interface FlashMessages {
  alert?: string;
  notice?: string;
}

export default function Login() {
  const { flash } = usePage<{ flash: FlashMessages }>().props;
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
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-xl font-bold">
            G
          </div>
          <h1 className="text-xl font-semibold text-foreground">
            Genixo Restoration
          </h1>
        </CardHeader>
        <CardContent>
          {flash.alert && (
            <div className="mb-4 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {flash.alert}
            </div>
          )}
          {flash.notice && (
            <div className="mb-4 rounded-md bg-primary/10 px-3 py-2 text-sm text-primary">
              {flash.notice}
            </div>
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
            <span className="text-sm text-muted-foreground">
              Forgot password?
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
