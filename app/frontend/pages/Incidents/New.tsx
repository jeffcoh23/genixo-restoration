import { Link, useForm, usePage } from "@inertiajs/react";
import { FormEvent, useRef, useState } from "react";
import { AlertTriangle, Building2, Check, Plus, Trash2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SharedProps } from "@/types";
import type { NewIncidentProps, NewIncidentAssignableUser } from "./types";

interface ContactRow {
  name: string;
  title: string;
  email: string;
  phone: string;
  onsite: boolean;
}

export default function NewIncident() {
  const { properties, project_types, damage_types, can_assign, can_manage_contacts, property_users = {}, routes } =
    usePage<SharedProps & NewIncidentProps>().props;

  const { data, setData, post, processing, errors, transform } = useForm({
    property_id: properties.length === 1 ? String(properties[0].id) : "",
    job_id: "",
    project_type: "",
    damage_type: "",
    description: "",
    cause: "",
    requested_next_steps: "",
    units_affected: "",
    affected_room_numbers: "",
    location_of_damage: "",
    do_not_exceed_limit: "",
    additional_user_ids: [] as number[],
  });

  const [contacts, setContacts] = useState<ContactRow[]>([]);
  const scrollLockRef = useRef(false);

  const isEmergency = data.project_type === "emergency_response";

  // Users for the currently selected property
  const currentUsers: NewIncidentAssignableUser[] = data.property_id ? (property_users[data.property_id] || []) : [];

  // Group by org for display
  const usersByOrg: Record<string, NewIncidentAssignableUser[]> = {};
  for (const user of currentUsers) {
    const org = user.organization_name;
    if (!usersByOrg[org]) usersByOrg[org] = [];
    usersByOrg[org].push(user);
  }

  const handlePropertyChange = (propertyId: string) => {
    const users = propertyId ? (property_users[propertyId] || []) : [];
    const autoIds = users.filter((u) => u.auto_assign).map((u) => u.id);
    const property = properties.find((p) => String(p.id) === propertyId);
    setData((prev) => ({
      ...prev,
      property_id: propertyId,
      additional_user_ids: autoIds,
      location_of_damage: property?.address || "",
    }));
  };

  const toggleUser = (userId: number) => {
    scrollLockRef.current = true;
    const scrollY = window.scrollY;
    const current = data.additional_user_ids;
    if (current.includes(userId)) {
      setData("additional_user_ids", current.filter((id) => id !== userId));
    } else {
      setData("additional_user_ids", [...current, userId]);
    }
    requestAnimationFrame(() => {
      window.scrollTo(0, scrollY);
      scrollLockRef.current = false;
    });
  };

  const addContactRow = () => {
    setContacts([...contacts, { name: "", title: "", email: "", phone: "", onsite: false }]);
  };

  const updateContact = (index: number, field: keyof ContactRow, value: string) => {
    const updated = [...contacts];
    updated[index] = { ...updated[index], [field]: value };
    setContacts(updated);
  };

  const removeContact = (index: number) => {
    setContacts(contacts.filter((_, i) => i !== index));
  };

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    transform((formData) => ({
      ...formData,
      contacts: contacts.filter((c) => c.name.trim() !== ""),
    }));
    post(routes.incidents);
  }

  return (
    <AppLayout>
      <PageHeader title="Create Request" backLink={{ href: routes.incidents, label: "Incidents" }} />

      <form onSubmit={handleSubmit} className="max-w-2xl mx-auto bg-card border border-border rounded shadow-sm p-6 space-y-5">
        {/* Property */}
        <div className="space-y-2">
          <Label htmlFor="property_id">Property *</Label>
          <select
            id="property_id"
            value={data.property_id}
            onChange={(e) => handlePropertyChange(e.target.value)}
            className="flex h-10 w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          >
            <option value="">Select a property...</option>
            {properties.map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
          {errors.property_id && <p className="text-sm text-destructive">{errors.property_id}</p>}
        </div>

        {/* Job ID */}
        <FormField
          id="job_id"
          label="Job ID"
          value={data.job_id}
          onChange={(v) => setData("job_id", v)}
          error={errors.job_id}
          hint="Optional reference number"
        />

        {/* Project Type — radio cards */}
        <fieldset className="space-y-2">
          <Label asChild><legend>Project Type *</legend></Label>
          <div className="grid grid-cols-2 gap-2">
            {project_types.map((pt) => (
              <label
                key={pt.value}
                className={`flex items-center gap-2 rounded border px-3 py-2.5 text-sm cursor-pointer transition-colors ${
                  data.project_type === pt.value
                    ? "border-primary bg-accent text-accent-foreground"
                    : "border-input bg-background text-foreground hover:bg-muted"
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
          <div className="flex items-start gap-3 rounded border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
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
            className="flex h-10 w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          >
            <option value="">Select damage type...</option>
            {damage_types.map((dt) => (
              <option key={dt.value} value={dt.value}>{dt.label}</option>
            ))}
          </select>
          {errors.damage_type && <p className="text-sm text-destructive">{errors.damage_type}</p>}
        </div>

        {/* Location of Damage */}
        <div className="space-y-2">
          <Label htmlFor="location_of_damage">Location of Damage</Label>
          <textarea
            id="location_of_damage"
            rows={2}
            value={data.location_of_damage}
            onChange={(e) => setData("location_of_damage", e.target.value)}
            placeholder="Address and area affected..."
            className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          />
          {errors.location_of_damage && <p className="text-sm text-destructive">{errors.location_of_damage}</p>}
        </div>

        {/* Emergency Do Not Exceed Limit */}
        <FormField
          id="do_not_exceed_limit"
          label="Emergency Do Not Exceed Limit"
          value={data.do_not_exceed_limit}
          onChange={(v) => setData("do_not_exceed_limit", v)}
          error={errors.do_not_exceed_limit}
          hint="Dollar amount, if applicable"
        />

        {/* Description */}
        <div className="space-y-2">
          <Label htmlFor="description">Description *</Label>
          <textarea
            id="description"
            rows={4}
            value={data.description}
            onChange={(e) => setData("description", e.target.value)}
            placeholder="Describe the damage and situation..."
            className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
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
            className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
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
            className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
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

        {/* Assign Team Members — only shown after property is selected */}
        {can_assign && data.property_id && currentUsers.length > 0 && (
          <fieldset className="space-y-2">
            <Label asChild><legend>Assign Team Members</legend></Label>
            <p className="text-xs text-muted-foreground">Checked members will be auto-assigned. Uncheck to remove, or check additional people.</p>
            <div className="rounded border border-input max-h-[280px] overflow-y-auto">
              {Object.entries(usersByOrg).map(([orgName, users]) => (
                <div key={orgName}>
                  <div className="flex items-center gap-1.5 px-3 py-1.5 bg-muted border-b border-input sticky top-0 z-10">
                    <Building2 className="h-3 w-3 text-muted-foreground" />
                    <span className="text-xs font-medium text-muted-foreground">{orgName}</span>
                  </div>
                  {users.map((u) => {
                    const selected = data.additional_user_ids.includes(u.id);
                    return (
                      <div
                        key={u.id}
                        role="checkbox"
                        aria-checked={selected}
                        tabIndex={0}
                        onClick={() => toggleUser(u.id)}
                        onKeyDown={(e) => { if (e.key === " " || e.key === "Enter") { e.preventDefault(); toggleUser(u.id); } }}
                        className={`flex items-center gap-2 px-3 py-1.5 text-sm cursor-pointer hover:bg-muted transition-colors border-b border-input last:border-b-0 select-none ${
                          selected ? "bg-accent" : ""
                        }`}
                      >
                        <div className={`h-4 w-4 rounded border flex items-center justify-center shrink-0 ${
                          selected ? "bg-primary border-primary" : "border-input"
                        }`}>
                          {selected && <Check className="h-3 w-3 text-primary-foreground" />}
                        </div>
                        <span className="text-foreground">{u.full_name}</span>
                        <span className="text-muted-foreground text-xs ml-auto">{u.role_label}</span>
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
            <p className="text-xs text-muted-foreground">{data.additional_user_ids.length} member{data.additional_user_ids.length !== 1 ? "s" : ""} selected</p>
          </fieldset>
        )}

        {/* Contacts */}
        {can_manage_contacts && (
          <fieldset className="space-y-2">
            <Label asChild><legend>Contacts</legend></Label>
            {contacts.map((contact, index) => (
              <div key={index} className="rounded border border-input p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-muted-foreground">Contact {index + 1}</span>
                  <Button type="button" variant="ghost" size="sm" className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive" onClick={() => removeContact(index)}>
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </div>
                <Input
                  type="text"
                  placeholder="Name *"
                  value={contact.name}
                  onChange={(e) => updateContact(index, "name", e.target.value)}
                  className="h-8 text-sm"
                />
                <Input
                  type="text"
                  placeholder="Title"
                  value={contact.title}
                  onChange={(e) => updateContact(index, "title", e.target.value)}
                  className="h-8 text-sm"
                />
                <div className="flex gap-2">
                  <Input
                    type="email"
                    placeholder="Email"
                    value={contact.email}
                    onChange={(e) => updateContact(index, "email", e.target.value)}
                    className="flex-1 h-8 text-sm"
                  />
                  <Input
                    type="tel"
                    placeholder="Phone"
                    value={contact.phone}
                    onChange={(e) => updateContact(index, "phone", e.target.value)}
                    className="flex-1 h-8 text-sm"
                  />
                </div>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <Checkbox
                    checked={contact.onsite}
                    onCheckedChange={(checked) => {
                      const updated = [...contacts];
                      updated[index] = { ...updated[index], onsite: checked === true };
                      setContacts(updated);
                    }}
                  />
                  Onsite contact
                </label>
              </div>
            ))}
            <Button type="button" variant="outline" size="sm" className="text-xs" onClick={addContactRow}>
              <Plus className="h-3 w-3 mr-1" />
              Add Contact
            </Button>
          </fieldset>
        )}

        {/* Actions */}
        <div className="flex gap-3 pt-2">
          <Button variant="outline" asChild>
            <Link href={routes.incidents}>Cancel</Link>
          </Button>
          <Button type="submit" disabled={processing}>
            {processing ? "Creating..." : "Create Request"}
          </Button>
        </div>
      </form>
    </AppLayout>
  );
}
