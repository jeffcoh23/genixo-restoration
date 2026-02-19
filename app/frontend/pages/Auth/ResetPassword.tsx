import { FormEvent } from "react";
import { Link, useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";

interface Props extends Record<string, unknown> {
  token: string;
  update_path: string;
  login_path: string;
}

export default function ResetPassword() {
  const { update_path, login_path } = usePage<Props>().props;
  const { data, setData, patch, processing, errors } = useForm({
    password: "",
    password_confirmation: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(update_path);
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background px-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-xl font-bold">
            G
          </div>
          <h1 className="text-xl font-semibold text-foreground">
            Set New Password
          </h1>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="password">New Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="new-password"
                autoFocus
                value={data.password}
                onChange={(e) => setData("password", e.target.value)}
              />
              {errors.password && (
                <p className="text-sm text-destructive">{errors.password}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="password_confirmation">Confirm Password</Label>
              <Input
                id="password_confirmation"
                type="password"
                autoComplete="new-password"
                value={data.password_confirmation}
                onChange={(e) => setData("password_confirmation", e.target.value)}
              />
              {errors.password_confirmation && (
                <p className="text-sm text-destructive">{errors.password_confirmation}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? "Resetting..." : "Reset Password"}
            </Button>
          </form>

          <div className="mt-4 text-center">
            <Link href={login_path} className="text-sm text-muted-foreground hover:text-foreground">
              Back to sign in
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
