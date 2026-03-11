import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import { AlertTriangle, Phone } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

interface FlashMessages {
  alert?: string;
  notice?: string;
}

interface Props extends Record<string, unknown> {
  flash: FlashMessages;
  project_types: { value: string; label: string }[];
  damage_types: { value: string; label: string }[];
  emergency_phone: string | null;
  submit_path: string;
}

export default function PublicIncidentReport() {
  const { flash, project_types, damage_types, emergency_phone, submit_path } = usePage<Props>().props;

  const { data, setData, post, processing, errors } = useForm({
    reporter_email: "",
    reporter_name: "",
    reporter_phone: "",
    property_description: "",
    project_type: "",
    damage_type: "",
    description: "",
    emergency: false,
  });

  const errorEntries = Object.entries(errors);

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(submit_path);
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background px-4 py-8">
      <div className="w-full max-w-xl">
        <div className="text-center mb-6">
          <img src="/brand/genixo-horizontal-dark.png" alt="Genixo Restoration" className="h-10 mx-auto mb-3" />
          <h1 className="text-lg font-semibold text-foreground">Report an Incident</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Don't have an account? Use this form to report an incident and we'll get back to you.
          </p>
        </div>

        {flash.notice && (
          <Alert className="mb-4 p-3 border-primary/30 bg-primary/10">
            <AlertDescription>{flash.notice}</AlertDescription>
          </Alert>
        )}
        {flash.alert && (
          <Alert variant="destructive" className="mb-4 p-3">
            <AlertDescription>{flash.alert}</AlertDescription>
          </Alert>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {errorEntries.length > 0 && (
            <div className="rounded-md border border-destructive/40 bg-destructive/10 px-4 py-3">
              <p className="text-sm font-semibold text-destructive">Please fix the highlighted fields.</p>
              <ul className="mt-1 text-sm text-destructive/90">
                {errorEntries.slice(0, 4).map(([field, message]) => (
                  <li key={field}>{message}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Contact Info */}
          <Card>
            <CardContent className="pt-5 space-y-4">
              <h2 className="text-base font-semibold text-foreground">Your Contact Info</h2>

              <div className="space-y-2">
                <Label htmlFor="reporter_email">Work Email *</Label>
                <Input
                  id="reporter_email"
                  type="email"
                  autoComplete="email"
                  autoFocus
                  placeholder="you@company.com"
                  value={data.reporter_email}
                  onChange={(e) => setData("reporter_email", e.target.value)}
                />
                {errors.reporter_email && <p className="text-sm text-destructive">{errors.reporter_email}</p>}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label htmlFor="reporter_name">Name *</Label>
                  <Input
                    id="reporter_name"
                    autoComplete="name"
                    placeholder="Your name"
                    value={data.reporter_name}
                    onChange={(e) => setData("reporter_name", e.target.value)}
                  />
                  {errors.reporter_name && <p className="text-sm text-destructive">{errors.reporter_name}</p>}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reporter_phone">Phone *</Label>
                  <Input
                    id="reporter_phone"
                    type="tel"
                    autoComplete="tel"
                    placeholder="(555) 555-5555"
                    value={data.reporter_phone}
                    onChange={(e) => setData("reporter_phone", e.target.value)}
                  />
                  {errors.reporter_phone && <p className="text-sm text-destructive">{errors.reporter_phone}</p>}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Incident Details */}
          <Card>
            <CardContent className="pt-5 space-y-4">
              <h2 className="text-base font-semibold text-foreground">Incident Details</h2>

              <div className="space-y-2">
                <Label htmlFor="property_description">Property Name / Address *</Label>
                <Input
                  id="property_description"
                  placeholder="e.g. Sunset Apartments, 123 Main St"
                  value={data.property_description}
                  onChange={(e) => setData("property_description", e.target.value)}
                />
                {errors.property_description && <p className="text-sm text-destructive">{errors.property_description}</p>}
              </div>

              <fieldset className="space-y-2">
                <Label asChild><legend>Project Type *</legend></Label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {project_types.map((pt) => (
                    <label
                      key={pt.value}
                      className={`flex items-center gap-2 rounded border px-3 py-3 text-sm cursor-pointer transition-colors ${
                        data.project_type === pt.value
                          ? "border-primary bg-accent text-accent-foreground"
                          : "border-input bg-background text-foreground hover:bg-muted/50"
                      }`}
                    >
                      <Input
                        type="radio"
                        name="project_type"
                        value={pt.value}
                        checked={data.project_type === pt.value}
                        onChange={(e) => setData("project_type", e.target.value)}
                        className="sr-only"
                      />
                      <span className={`h-4 w-4 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                        data.project_type === pt.value ? "border-primary" : "border-muted-foreground"
                      }`}>
                        {data.project_type === pt.value && (
                          <span className="h-2 w-2 rounded-full bg-primary" />
                        )}
                      </span>
                      {pt.label}
                    </label>
                  ))}
                </div>
                {errors.project_type && <p className="text-sm text-destructive">{errors.project_type}</p>}
              </fieldset>

              <div className="space-y-2">
                <Label>Damage Type *</Label>
                <Select value={data.damage_type} onValueChange={(v) => setData("damage_type", v)}>
                  <SelectTrigger className="h-11 sm:h-10">
                    <SelectValue placeholder="Select damage type..." />
                  </SelectTrigger>
                  <SelectContent>
                    {damage_types.map((dt) => (
                      <SelectItem key={dt.value} value={dt.value}>{dt.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.damage_type && <p className="text-sm text-destructive">{errors.damage_type}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Description *</Label>
                <Textarea
                  id="description"
                  rows={5}
                  value={data.description}
                  onChange={(e) => setData("description", e.target.value)}
                  placeholder="Describe the damage and situation..."
                />
                {errors.description && <p className="text-sm text-destructive">{errors.description}</p>}
              </div>

              {/* Emergency toggle */}
              <div className="space-y-3">
                <label className="flex items-center gap-2.5 cursor-pointer">
                  <Checkbox
                    checked={data.emergency}
                    onCheckedChange={(checked) => setData("emergency", checked === true)}
                  />
                  <span className="text-sm font-medium text-foreground">This is an emergency</span>
                </label>

                {data.emergency && (
                  <div className="rounded-md border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-900">
                    <div className="flex items-start gap-2">
                      <AlertTriangle className="h-4 w-4 mt-0.5 flex-shrink-0 text-amber-700" />
                      <div>
                        <p className="font-semibold">Emergency escalation will be triggered.</p>
                        <p className="mt-0.5">Our on-call team will be notified immediately via SMS.</p>
                      </div>
                    </div>
                    {emergency_phone && (
                      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-amber-300/50">
                        <Phone className="h-4 w-4 flex-shrink-0 text-amber-700" />
                        <p>For immediate assistance, call{" "}
                          <a href={`tel:${emergency_phone.replace(/\D/g, "")}`} className="font-semibold underline">
                            {emergency_phone}
                          </a>
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Submit */}
          <div className="flex items-center justify-between gap-3">
            <Link href="/login" className="text-sm text-muted-foreground hover:text-foreground">
              Back to login
            </Link>
            <Button type="submit" className="h-11 sm:h-10" disabled={processing}>
              {processing ? "Submitting..." : "Submit Report"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
