import { FormEvent } from "react";
import { Link, useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";

interface FlashMessages {
  alert?: string;
  notice?: string;
}

interface Props extends Record<string, unknown> {
  flash: FlashMessages;
  create_path: string;
  login_path: string;
}

export default function ForgotPassword() {
  const { flash, create_path, login_path } = usePage<Props>().props;
  const { data, setData, post, processing } = useForm({
    email_address: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(create_path);
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background px-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-xl font-bold">
            G
          </div>
          <h1 className="text-xl font-semibold text-foreground">
            Reset Password
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Enter your email and we'll send you a reset link.
          </p>
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
            </div>

            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? "Sending..." : "Send Reset Link"}
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
