import { useForm, usePage } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { SharedProps } from "@/types";

const CATEGORIES = [
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
    <Dialog open onOpenChange={(isOpen) => !isOpen && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-sm">Upload Document</DialogTitle>
          <DialogDescription className="sr-only">
            Upload a document to this incident
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="text-xs font-medium text-muted-foreground">
              File
            </label>
            <Input
              type="file"
              onChange={(e) => setData("file", e.target.files?.[0] ?? null)}
              className="mt-1"
            />
            {errors.file && (
              <p className="text-xs text-destructive mt-1">{errors.file}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Category
              </label>
              <Select value={data.category} onValueChange={(v) => setData("category", v)}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map((c) => (
                    <SelectItem key={c.value} value={c.value}>
                      {c.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.category && (
                <p className="text-xs text-destructive mt-1">
                  {errors.category}
                </p>
              )}
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Date
              </label>
              <Input
                type="date"
                value={data.log_date}
                onChange={(e) => setData("log_date", e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Description
            </label>
            <Input
              value={data.description}
              onChange={(e) => setData("description", e.target.value)}
              placeholder="Optional description"
              className="mt-1"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={onClose}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              size="sm"
              disabled={processing || !data.file}
            >
              {processing ? "Uploading..." : "Upload"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
