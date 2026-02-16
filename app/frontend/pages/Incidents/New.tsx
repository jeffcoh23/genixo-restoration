import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent } from "react";
import { AlertTriangle } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { SharedProps } from "@/types";

interface SelectOption {
  id: number;
  name: string;
}

interface LabeledOption {
  value: string;
  label: string;
}

interface NewIncidentProps {
  properties: SelectOption[];
  project_types: LabeledOption[];
  damage_types: LabeledOption[];
}

export default function NewIncident() {
  const { properties, project_types, damage_types, routes } =
    usePage<SharedProps & NewIncidentProps>().props;

  const { data, setData, post, processing, errors } = useForm({
    property_id: properties.length === 1 ? String(properties[0].id) : "",
    project_type: "",
    damage_type: "",
    description: "",
    cause: "",
    requested_next_steps: "",
    units_affected: "",
    affected_room_numbers: "",
  });

  const isEmergency = data.project_type === "emergency_response";

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    post(routes.incidents);
  }

  return (
    <AppLayout>
      <PageHeader title="New Incident" backLink={{ href: routes.incidents, label: "Incidents" }} />

      <form onSubmit={handleSubmit} className="max-w-lg mx-auto bg-card border border-border rounded shadow-sm p-6 space-y-5">
        {/* Property */}
        <div className="space-y-2">
          <Label htmlFor="property_id">Property *</Label>
          <select
            id="property_id"
            value={data.property_id}
            onChange={(e) => setData("property_id", e.target.value)}
            className="flex h-10 w-full rounded-md border border-input bg-muted px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          >
            <option value="">Select a property...</option>
            {properties.map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
          {errors.property_id && <p className="text-sm text-destructive">{errors.property_id}</p>}
        </div>

        {/* Project Type — radio cards */}
        <fieldset className="space-y-2">
          <Label asChild><legend>Project Type *</legend></Label>
          <div className="grid grid-cols-2 gap-2">
            {project_types.map((pt) => (
              <label
                key={pt.value}
                className={`flex items-center gap-2 rounded-md border px-3 py-2.5 text-sm cursor-pointer transition-colors ${
                  data.project_type === pt.value
                    ? "border-primary bg-accent text-accent-foreground"
                    : "border-input bg-background text-foreground hover:bg-muted"
                }`}
              >
                <input
                  type="radio"
                  name="project_type"
                  value={pt.value}
                  checked={data.project_type === pt.value}
                  onChange={(e) => setData("project_type", e.target.value)}
                  className="sr-only"
                />
                <span className={`h-3.5 w-3.5 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                  data.project_type === pt.value ? "border-primary" : "border-muted-foreground"
                }`}>
                  {data.project_type === pt.value && (
                    <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                  )}
                </span>
                {pt.label}
              </label>
            ))}
          </div>
          {errors.project_type && <p className="text-sm text-destructive">{errors.project_type}</p>}
        </fieldset>

        {/* Emergency warning */}
        {isEmergency && (
          <div className="flex items-start gap-3 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
            <AlertTriangle className="h-5 w-5 flex-shrink-0 text-amber-600 mt-0.5" />
            <p>This will trigger the emergency escalation chain and notify the on-call team immediately.</p>
          </div>
        )}

        {/* Damage Type */}
        <div className="space-y-2">
          <Label htmlFor="damage_type">Damage Type *</Label>
          <select
            id="damage_type"
            value={data.damage_type}
            onChange={(e) => setData("damage_type", e.target.value)}
            className="flex h-10 w-full rounded-md border border-input bg-muted px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          >
            <option value="">Select damage type...</option>
            {damage_types.map((dt) => (
              <option key={dt.value} value={dt.value}>{dt.label}</option>
            ))}
          </select>
          {errors.damage_type && <p className="text-sm text-destructive">{errors.damage_type}</p>}
        </div>

        {/* Description */}
        <div className="space-y-2">
          <Label htmlFor="description">Description *</Label>
          <textarea
            id="description"
            rows={4}
            value={data.description}
            onChange={(e) => setData("description", e.target.value)}
            placeholder="Describe the damage and situation..."
            className="flex w-full rounded-md border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          />
          {errors.description && <p className="text-sm text-destructive">{errors.description}</p>}
        </div>

        {/* Cause */}
        <div className="space-y-2">
          <Label htmlFor="cause">Cause</Label>
          <textarea
            id="cause"
            rows={2}
            value={data.cause}
            onChange={(e) => setData("cause", e.target.value)}
            placeholder="Known cause of the damage, if any..."
            className="flex w-full rounded-md border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          />
          {errors.cause && <p className="text-sm text-destructive">{errors.cause}</p>}
        </div>

        {/* Requested Next Steps */}
        <div className="space-y-2">
          <Label htmlFor="requested_next_steps">Requested Next Steps</Label>
          <textarea
            id="requested_next_steps"
            rows={2}
            value={data.requested_next_steps}
            onChange={(e) => setData("requested_next_steps", e.target.value)}
            placeholder="What would you like us to do first?"
            className="flex w-full rounded-md border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          />
          {errors.requested_next_steps && <p className="text-sm text-destructive">{errors.requested_next_steps}</p>}
        </div>

        {/* Units + Room Numbers side by side */}
        <div className="grid grid-cols-2 gap-4">
          <FormField
            id="units_affected"
            label="Units Affected"
            type="number"
            value={data.units_affected}
            onChange={(v) => setData("units_affected", v)}
            error={errors.units_affected}
          />
          <FormField
            id="affected_room_numbers"
            label="Room Numbers"
            value={data.affected_room_numbers}
            onChange={(v) => setData("affected_room_numbers", v)}
            error={errors.affected_room_numbers}
            hint="e.g. 101, 102, 205"
          />
        </div>

        {/* Actions */}
        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={routes.incidents}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Creating..." : "Create Incident"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
