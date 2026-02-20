import { useForm, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";

const CATEGORIES = [
  { value: "photo", label: "Photo" },
  { value: "moisture_mapping", label: "Moisture Mapping" },
  { value: "moisture_readings", label: "Moisture Readings" },
  { value: "psychrometric_log", label: "Psychrometric Log" },
  { value: "signed_document", label: "Signed Document" },
  { value: "sign_in_sheet", label: "Sign-In Sheet" },
  { value: "general", label: "General" },
];

interface AttachmentFormProps {
  path: string;
  onClose: () => void;
}

export default function AttachmentForm({ path, onClose }: AttachmentFormProps) {
  const { today } = usePage<SharedProps>().props;
  const { data, setData, post, processing, errors } = useForm({
    file: null as File | null,
    category: "general",
    description: "",
    log_date: today,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post(path, {
      forceFormData: true,
      onSuccess: () => onClose(),
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-md p-4 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">Upload Document</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">File</label>
            <Input
              type="file"
              accept={data.category === "photo" ? "image/*" : undefined}
              capture={data.category === "photo" ? "environment" : undefined}
              onChange={(e) => setData("file", e.target.files?.[0] ?? null)}
              className="mt-1"
            />
            {errors.file && <p className="text-xs text-destructive mt-1">{errors.file}</p>}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Category</label>
              <select
                value={data.category}
                onChange={(e) => setData("category", e.target.value)}
                className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
              >
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>{c.label}</option>
                ))}
              </select>
              {errors.category && <p className="text-xs text-destructive mt-1">{errors.category}</p>}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Date</label>
              <Input
                type="date"
                value={data.log_date}
                onChange={(e) => setData("log_date", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">Description</label>
            <Input
              value={data.description}
              onChange={(e) => setData("description", e.target.value)}
              placeholder="Optional description"
              className="mt-1"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing || !data.file}>
              {processing ? "Uploading..." : "Upload"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
