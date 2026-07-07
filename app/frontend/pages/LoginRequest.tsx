import { Link, useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { FormEvent } from "react";

interface FlashMessages {
  alert?: string;
  notice?: string;
}

interface Props extends Record<string, unknown> {
  flash: FlashMessages;
  submit_path: string;
  login_path: string;
}

// Rails sends errors.to_hash — an array per field. Inertia's types say
// string; joining keeps multi-error fields readable.
function errorText(error: string | string[] | undefined): string | undefined {
  if (!error) return undefined;
  return Array.isArray(error) ? error.join(", ") : error;
}

export default function LoginRequest() {
  const { flash, submit_path, login_path } = usePage<Props>().props;
  const { data, setData, post, processing, errors } = useForm({
    first_name: "",
    last_name: "",
    email: "",
    company_name: "",
    phone: "",
    message: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(submit_path);
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background px-4 py-8">
      <Card className="w-full max-w-md">
        <CardHeader className="pb-2">
          <div className="mx-auto mb-2">
            <img src="/brand/genixo-horizontal-dark.png" alt="Genixo Restoration" className="h-10" />
          </div>
          <h1 className="text-center text-lg font-semibold">Request Access</h1>
          <p className="text-center text-sm text-muted-foreground">
            Tell us who you are and we&apos;ll email you an invitation once your request is reviewed.
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
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2">
                <Label htmlFor="first_name">First name</Label>
                <Input
                  id="first_name"
                  autoComplete="given-name"
                  autoFocus
                  value={data.first_name}
                  onChange={(e) => setData("first_name", e.target.value)}
                />
                {errors.first_name && <p className="text-sm text-destructive">{errorText(errors.first_name)}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="last_name">Last name</Label>
                <Input
                  id="last_name"
                  autoComplete="family-name"
                  value={data.last_name}
                  onChange={(e) => setData("last_name", e.target.value)}
                />
                {errors.last_name && <p className="text-sm text-destructive">{errorText(errors.last_name)}</p>}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                value={data.email}
                onChange={(e) => setData("email", e.target.value)}
              />
              {errors.email && <p className="text-sm text-destructive">{errorText(errors.email)}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="company_name">Company</Label>
              <Input
                id="company_name"
                autoComplete="organization"
                value={data.company_name}
                onChange={(e) => setData("company_name", e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="phone">Phone</Label>
              <Input
                id="phone"
                type="tel"
                autoComplete="tel"
                value={data.phone}
                onChange={(e) => setData("phone", e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="message">Anything we should know? (optional)</Label>
              <Textarea
                id="message"
                rows={3}
                placeholder="e.g. which properties you work with"
                value={data.message}
                onChange={(e) => setData("message", e.target.value)}
              />
            </div>

            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? "Submitting..." : "Request Access"}
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
