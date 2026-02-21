import { useForm, usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";

interface InvitationData {
  token: string;
  email: string;
  organization_name: string;
  role_label: string;
  first_name: string | null;
  last_name: string | null;
  phone: string | null;
}

export default function AcceptInvitation() {
  const { invitation, errors } = usePage<{
    invitation: InvitationData;
    errors?: Record<string, string[]>;
  }>().props;

  const form = useForm({
    first_name: invitation.first_name || "",
    last_name: invitation.last_name || "",
    phone: invitation.phone || "",
    password: "",
    password_confirmation: "",
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    form.post(`/invitations/${invitation.token}/accept`);
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-xl font-bold">
            G
          </div>
          <h1 className="text-xl font-semibold text-foreground mb-1">You've been invited!</h1>
          <p className="text-sm text-muted-foreground">
            Join <span className="font-medium text-foreground">{invitation.organization_name}</span> as a{" "}
            <span className="font-medium text-foreground">{invitation.role_label}</span>
          </p>
          <p className="text-xs text-muted-foreground mt-1">{invitation.email}</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField id="first_name" label="First Name" value={form.data.first_name}
                onChange={(v) => form.setData("first_name", v)}
                error={form.errors.first_name || errors?.first_name?.[0]} required />
              <FormField id="last_name" label="Last Name" value={form.data.last_name}
                onChange={(v) => form.setData("last_name", v)}
                error={form.errors.last_name || errors?.last_name?.[0]} required />
            </div>

            <FormField id="phone" label="Phone" type="tel" value={form.data.phone}
              onChange={(v) => form.setData("phone", v)}
              error={form.errors.phone || errors?.phone?.[0]} />

            <FormField id="password" label="Password" type="password" value={form.data.password}
              onChange={(v) => form.setData("password", v)}
              error={form.errors.password || errors?.password?.[0]} required />

            <FormField id="password_confirmation" label="Confirm Password" type="password"
              value={form.data.password_confirmation}
              onChange={(v) => form.setData("password_confirmation", v)}
              error={form.errors.password_confirmation || errors?.password_confirmation?.[0]} required />

            <Button type="submit" className="w-full" disabled={form.processing}>
              {form.processing ? "Creating Account..." : "Create Account"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
