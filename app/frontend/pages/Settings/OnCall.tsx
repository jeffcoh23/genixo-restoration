import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { ArrowDown, ArrowUp, Plus, Trash2 } from "lucide-react";
import AppLayout from "@/layout/AppLayout";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
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
              <label className="text-sm font-medium text-foreground">
                Primary On-Call <span className="text-destructive">*</span>
              </label>
              <Select value={String(primaryUserId)} onValueChange={(v) => setPrimaryUserId(v)}>
                <SelectTrigger className="mt-1 h-11 sm:h-10">
                  <SelectValue placeholder="Select a manager..." />
                </SelectTrigger>
                <SelectContent>
                  {managers.map((m) => (
                    <SelectItem key={m.id} value={String(m.id)}>
                      {m.full_name} ({m.role_label})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-medium text-foreground">
                Escalation Timeout (minutes)
              </label>
              <Input
                type="number"
                min={1}
                max={60}
                value={timeoutMinutes}
                onChange={(e) => setTimeoutMinutes(Number(e.target.value))}
                className="mt-1 max-w-[140px] h-11 sm:h-10"
              />
              <p className="mt-1 text-sm text-muted-foreground">
                Time to wait before contacting the next person in the escalation chain.
              </p>
            </div>

            <Button type="submit" size="sm" className="h-11 sm:h-10" disabled={saving}>
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
                  <div key={contact.id} className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3 px-3 py-3 hover:bg-muted/30 transition-colors">
                    <span className="text-sm font-semibold text-muted-foreground w-6 tabular-nums">{idx + 1}.</span>
                    <span className="text-sm text-foreground">{contact.full_name}</span>
                    <span className="text-sm text-muted-foreground">{contact.role_label}</span>
                    <div className="sm:ml-auto flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-10 sm:h-8 gap-1 text-sm sm:text-xs"
                        onClick={() => handleMoveContact(idx, "up")}
                        disabled={idx === 0}
                      >
                        <ArrowUp className="h-3.5 w-3.5" />
                        Up
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-10 sm:h-8 gap-1 text-sm sm:text-xs"
                        onClick={() => handleMoveContact(idx, "down")}
                        disabled={idx === config.contacts.length - 1}
                      >
                        <ArrowDown className="h-3.5 w-3.5" />
                        Down
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        className="h-10 sm:h-8 gap-1 text-sm sm:text-xs"
                        onClick={() => handleRemoveContact(contact.remove_path)}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                        Remove
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
                  <label className="text-sm font-medium text-foreground">Add Contact</label>
                  <Select value={newContactUserId} onValueChange={setNewContactUserId}>
                    <SelectTrigger className="mt-1 h-11 sm:h-10">
                      <SelectValue placeholder="Select..." />
                    </SelectTrigger>
                    <SelectContent>
                      {availableForEscalation.map((m) => (
                        <SelectItem key={m.id} value={String(m.id)}>
                          {m.full_name} ({m.role_label})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <Button type="submit" size="sm" variant="outline" disabled={addingContact || !newContactUserId} className="gap-1 h-11 sm:h-10">
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
