import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { ArrowDown, ArrowUp, Plus, Trash2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { SharedProps } from "@/types";

interface Manager {
  id: number;
  full_name: string;
  role_label: string;
}

interface EscalationContact {
  id: number;
  user_id: number;
  full_name: string;
  role_label: string;
  position: number;
  remove_path: string;
}

interface OnCallConfig {
  primary_user_id: number;
  escalation_timeout_minutes: number;
  contacts: EscalationContact[];
}

interface OnCallProps {
  config: OnCallConfig | null;
  managers: Manager[];
  available_escalation_managers: Manager[];
  update_path: string;
  contacts_path: string;
  reorder_path: string;
}

export default function OnCallSettings() {
  const { config, managers, available_escalation_managers, update_path, contacts_path, reorder_path } = usePage<SharedProps & OnCallProps>().props;

  const [primaryUserId, setPrimaryUserId] = useState(config?.primary_user_id ?? "");
  const [timeoutMinutes, setTimeoutMinutes] = useState(config?.escalation_timeout_minutes ?? 10);
  const [saving, setSaving] = useState(false);
  const [addingContact, setAddingContact] = useState(false);
  const [newContactUserId, setNewContactUserId] = useState("");

  const handleSaveConfig = (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    router.patch(update_path, {
      primary_user_id: primaryUserId,
      escalation_timeout_minutes: timeoutMinutes,
    }, {
      preserveScroll: true,
      onFinish: () => setSaving(false),
    });
  };

  const handleAddContact = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newContactUserId) return;
    setAddingContact(true);
    router.post(contacts_path, {
      user_id: newContactUserId,
    }, {
      preserveScroll: true,
      onFinish: () => {
        setAddingContact(false);
        setNewContactUserId("");
      },
    });
  };

  const handleRemoveContact = (removePath: string) => {
    router.delete(removePath, { preserveScroll: true });
  };

  const handleMoveContact = (index: number, direction: "up" | "down") => {
    if (!config) return;
    const contacts = [...config.contacts];
    const swapIdx = direction === "up" ? index - 1 : index + 1;
    if (swapIdx < 0 || swapIdx >= contacts.length) return;

    [contacts[index], contacts[swapIdx]] = [contacts[swapIdx], contacts[index]];
    const contactIds = contacts.map((c) => c.id);

    router.patch(reorder_path, { contact_ids: contactIds }, { preserveScroll: true });
  };

  // Server pre-filters managers not already in escalation contacts; only exclude current primary selection
  const availableForEscalation = available_escalation_managers.filter(m => m.id !== Number(primaryUserId));

  return (
    <AppLayout>
      <PageHeader title="On-Call Configuration" />
      <p className="-mt-4 mb-6 text-sm text-muted-foreground">
        Set the primary on-call contact and escalation chain for emergency incidents.
      </p>

      <div className="space-y-6">
        {/* Primary on-call + timeout */}
        <div className="bg-card rounded-lg border border-border shadow-sm p-5">
          <h2 className="text-sm font-semibold text-foreground mb-4">Primary Contact</h2>
          <form onSubmit={handleSaveConfig} className="space-y-4 max-w-md">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Primary On-Call <span className="text-destructive">*</span>
              </label>
              <select
                value={primaryUserId}
                onChange={(e) => setPrimaryUserId(e.target.value)}
                className="mt-1 w-full h-9 rounded-md border border-input bg-background px-3 text-sm"
                required
              >
                <option value="">Select a manager...</option>
                {managers.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.full_name} ({m.role_label})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Escalation Timeout (minutes)
              </label>
              <Input
                type="number"
                min={1}
                max={60}
                value={timeoutMinutes}
                onChange={(e) => setTimeoutMinutes(Number(e.target.value))}
                className="mt-1 max-w-[120px]"
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Time to wait before contacting the next person in the escalation chain.
              </p>
            </div>

            <Button type="submit" size="sm" disabled={saving}>
              {saving ? "Saving..." : "Save Configuration"}
            </Button>
          </form>
        </div>

        {/* Escalation chain */}
        {config && (
          <div className="bg-card rounded-lg border border-border shadow-sm p-5">
            <h2 className="text-sm font-semibold text-foreground">Escalation Chain</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              If the primary on-call doesn't respond within the timeout, these contacts are tried in order.
            </p>

            {config.contacts.length === 0 ? (
              <p className="mt-4 text-sm text-muted-foreground">No escalation contacts configured.</p>
            ) : (
              <div className="mt-3 divide-y divide-border">
                {config.contacts.map((contact, idx) => (
                  <div key={contact.id} className="flex items-center gap-3 px-3 py-2.5 hover:bg-muted/30 transition-colors">
                    <span className="text-xs font-medium text-muted-foreground w-5 tabular-nums">{idx + 1}.</span>
                    <span className="text-sm text-foreground">{contact.full_name}</span>
                    <span className="text-xs text-muted-foreground">{contact.role_label}</span>
                    <div className="ml-auto flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                        onClick={() => handleMoveContact(idx, "up")}
                        disabled={idx === 0}
                        title="Move up"
                      >
                        <ArrowUp className="h-3.5 w-3.5" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                        onClick={() => handleMoveContact(idx, "down")}
                        disabled={idx === config.contacts.length - 1}
                        title="Move down"
                      >
                        <ArrowDown className="h-3.5 w-3.5" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                        onClick={() => handleRemoveContact(contact.remove_path)}
                        title={`Remove ${contact.full_name}`}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Add escalation contact */}
            {availableForEscalation.length > 0 && (
              <form onSubmit={handleAddContact} className="mt-4 flex items-end gap-2 border-t border-border pt-4">
                <div className="flex-1 max-w-[280px]">
                  <label className="text-xs font-medium text-muted-foreground">Add Contact</label>
                  <select
                    value={newContactUserId}
                    onChange={(e) => setNewContactUserId(e.target.value)}
                    className="mt-1 w-full h-9 rounded-md border border-input bg-background px-3 text-sm"
                  >
                    <option value="">Select...</option>
                    {availableForEscalation.map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.full_name} ({m.role_label})
                      </option>
                    ))}
                  </select>
                </div>
                <Button type="submit" size="sm" variant="ghost" disabled={addingContact || !newContactUserId} className="gap-1">
                  <Plus className="h-3.5 w-3.5" />
                  Add
                </Button>
              </form>
            )}
          </div>
        )}
      </div>
    </AppLayout>
  );
}
