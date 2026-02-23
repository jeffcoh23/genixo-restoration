import { FormEvent } from "react";
import { useForm, usePage } from "@inertiajs/react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SharedProps } from "@/types";

interface NotificationPreferences {
  status_change: boolean;
  new_message: boolean;
  daily_digest: boolean;
  incident_creation: boolean;
  user_assignment: boolean;
}

interface UserProfile {
  first_name: string;
  last_name: string;
  email_address: string;
  timezone: string;
  role_label: string;
  organization_name: string;
  notification_preferences: NotificationPreferences;
}

interface TimezoneOption {
  value: string;
  label: string;
}

interface Props {
  user: UserProfile;
  timezone_options: TimezoneOption[];
  update_path: string;
  password_path: string;
  preferences_path: string;
}

function ProfileForm({ user, timezoneOptions, updatePath }: {
  user: UserProfile;
  timezoneOptions: TimezoneOption[];
  updatePath: string;
}) {
  const { data, setData, patch, processing, errors } = useForm({
    first_name: user.first_name,
    last_name: user.last_name,
    email_address: user.email_address,
    timezone: user.timezone,
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(updatePath);
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <FormField id="first_name" label="First Name" value={data.first_name} onChange={(v) => setData("first_name", v)} error={errors.first_name} required />
        <FormField id="last_name" label="Last Name" value={data.last_name} onChange={(v) => setData("last_name", v)} error={errors.last_name} required />
      </div>

      <FormField id="email_address" label="Email" type="email" value={data.email_address} onChange={(v) => setData("email_address", v)} error={errors.email_address} required />

      <div className="space-y-2">
        <Label>Timezone *</Label>
        <Select value={data.timezone} onValueChange={(v) => setData("timezone", v)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {timezoneOptions.map((tz) => (
              <SelectItem key={tz.value} value={tz.value}>{tz.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        {errors.timezone && <p className="text-sm text-destructive">{errors.timezone}</p>}
      </div>

      <div className="pt-2">
        <Button type="submit" disabled={processing}>
          {processing ? "Saving..." : "Save Profile"}
        </Button>
      </div>
    </form>
  );
}

function PasswordForm({ passwordPath }: { passwordPath: string }) {
  const { data, setData, patch, processing, errors, reset } = useForm({
    current_password: "",
    password: "",
    password_confirmation: "",
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(passwordPath, {
      onSuccess: () => reset(),
    });
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
      <div className="space-y-2">
        <Label htmlFor="current_password">Current Password *</Label>
        <Input
          id="current_password"
          type="password"
          value={data.current_password}
          onChange={(e) => setData("current_password", e.target.value)}
        />
        {errors.current_password && <p className="text-sm text-destructive">{errors.current_password}</p>}
      </div>

      <div className="space-y-2">
        <Label htmlFor="password">New Password *</Label>
        <Input
          id="password"
          type="password"
          value={data.password}
          onChange={(e) => setData("password", e.target.value)}
        />
        {errors.password && <p className="text-sm text-destructive">{errors.password}</p>}
      </div>

      <div className="space-y-2">
        <Label htmlFor="password_confirmation">Confirm New Password *</Label>
        <Input
          id="password_confirmation"
          type="password"
          value={data.password_confirmation}
          onChange={(e) => setData("password_confirmation", e.target.value)}
        />
        {errors.password_confirmation && <p className="text-sm text-destructive">{errors.password_confirmation}</p>}
      </div>

      <div className="pt-2">
        <Button type="submit" disabled={processing}>
          {processing ? "Updating..." : "Update Password"}
        </Button>
      </div>
    </form>
  );
}

function NotificationPreferencesForm({ preferences, preferencesPath }: {
  preferences: NotificationPreferences;
  preferencesPath: string;
}) {
  const { data, setData, patch, processing } = useForm({
    status_change: preferences.status_change,
    new_message: preferences.new_message,
    daily_digest: preferences.daily_digest,
    incident_creation: preferences.incident_creation,
    user_assignment: preferences.user_assignment,
  });

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    patch(preferencesPath);
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-lg space-y-4">
      {[
        { key: "status_change" as const, label: "Status changes", description: "Get notified when an incident status changes" },
        { key: "new_message" as const, label: "New messages", description: "Get notified when someone sends a message on your incidents" },
        { key: "incident_creation" as const, label: "Incident creation", description: "Get notified when a new incident is created that involves you" },
        { key: "user_assignment" as const, label: "Assignment alerts", description: "Get notified when you're assigned to an incident" },
        { key: "daily_digest" as const, label: "Daily digest email", description: "Receive a daily summary of activity across your incidents" },
      ].map((pref) => (
        <div key={pref.key} className="flex items-start gap-3">
          <Checkbox
            id={pref.key}
            checked={data[pref.key]}
            onCheckedChange={(checked) => setData(pref.key, checked === true)}
            className="mt-0.5"
          />
          <label htmlFor={pref.key} className="cursor-pointer">
            <div className="text-sm font-medium text-foreground">{pref.label}</div>
            <div className="text-xs text-muted-foreground">{pref.description}</div>
          </label>
        </div>
      ))}

      <div className="pt-2">
        <Button type="submit" disabled={processing}>
          {processing ? "Saving..." : "Save Preferences"}
        </Button>
      </div>
    </form>
  );
}

export default function SettingsProfile() {
  const { user, timezone_options, update_path, password_path, preferences_path } = usePage<SharedProps & Props>().props;

  return (
    <AppLayout>
      <PageHeader title="Settings" />

      <div className="space-y-6">
        {/* Read-only info */}
        <div className="rounded-lg border border-border bg-card shadow-sm px-5 py-3">
          <p className="text-sm text-muted-foreground">
            {user.role_label} at {user.organization_name}
          </p>
        </div>

        {/* Profile form */}
        <div className="bg-card rounded-lg border border-border shadow-sm p-5">
          <h2 className="text-sm font-semibold text-foreground mb-4">Profile</h2>
          <ProfileForm user={user} timezoneOptions={timezone_options} updatePath={update_path} />
        </div>

        {/* Notification preferences */}
        <div className="bg-card rounded-lg border border-border shadow-sm p-5">
          <h2 className="text-sm font-semibold text-foreground mb-4">Notifications</h2>
          <NotificationPreferencesForm preferences={user.notification_preferences} preferencesPath={preferences_path} />
        </div>

        {/* Password form */}
        <div className="bg-card rounded-lg border border-border shadow-sm p-5">
          <h2 className="text-sm font-semibold text-foreground mb-4">Change Password</h2>
          <PasswordForm passwordPath={password_path} />
        </div>
      </div>
    </AppLayout>
  );
}
