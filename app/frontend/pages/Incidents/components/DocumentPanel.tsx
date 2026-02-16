import { useState } from "react";
import { FileText, Image, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import type { IncidentAttachment } from "../types";
import AttachmentForm from "./AttachmentForm";

const CATEGORY_OPTIONS = [
  { value: "", label: "All" },
  { value: "photo", label: "Photo" },
  { value: "moisture_mapping", label: "Moisture Mapping" },
  { value: "moisture_readings", label: "Moisture Readings" },
  { value: "psychrometric_log", label: "Psychrometric Log" },
  { value: "signed_document", label: "Signed Document" },
  { value: "general", label: "General" },
];

interface DocumentPanelProps {
  attachments: IncidentAttachment[];
  attachments_path: string;
}

export default function DocumentPanel({ attachments, attachments_path }: DocumentPanelProps) {
  const [category, setCategory] = useState("");
  const [showUploadForm, setShowUploadForm] = useState(false);

  const filtered = category
    ? attachments.filter((a) => a.category === category)
    : attachments;

  const photos = filtered.filter((a) => a.content_type.startsWith("image/"));
  const documents = filtered.filter((a) => !a.content_type.startsWith("image/"));

  if (attachments.length === 0) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground text-sm py-12 px-4">
        <p>No documents uploaded yet.</p>
        <Button
          variant="outline"
          size="sm"
          className="mt-3 gap-1.5"
          onClick={() => setShowUploadForm(true)}
        >
          <Upload className="h-3.5 w-3.5" />
          Upload
        </Button>
        {showUploadForm && (
          <AttachmentForm path={attachments_path} onClose={() => setShowUploadForm(false)} />
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Filter bar */}
      <div className="flex items-center justify-between p-3 border-b border-border shrink-0">
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="rounded border border-input bg-background px-2 py-1.5 text-xs"
        >
          {CATEGORY_OPTIONS.map((c) => (
            <option key={c.value} value={c.value}>{c.label}</option>
          ))}
        </select>
        <Button
          variant="outline"
          size="sm"
          className="h-7 text-xs gap-1"
          onClick={() => setShowUploadForm(true)}
        >
          <Upload className="h-3 w-3" />
          Upload
        </Button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-3 pb-8 space-y-4">
        {/* Photo grid */}
        {photos.length > 0 && (
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
              Photos ({photos.length})
            </p>
            <div className="grid grid-cols-2 gap-2">
              {photos.map((att) => (
                <Button
                  key={att.id}
                  variant="ghost"
                  onClick={() => window.open(att.url, "_blank")}
                  className="h-auto p-0 text-left rounded border border-border overflow-hidden hover:border-primary"
                >
                  <div className="w-full">
                    <div className="aspect-square bg-muted flex items-center justify-center">
                      <Image className="h-8 w-8 text-muted-foreground" />
                    </div>
                    <div className="p-2">
                      <p className="text-xs font-medium truncate">{att.description || att.filename}</p>
                      <p className="text-xs text-muted-foreground">
                        {att.log_date_label ?? att.created_at_label}
                      </p>
                      <p className="text-xs text-muted-foreground">{att.uploaded_by_name}</p>
                    </div>
                  </div>
                </Button>
              ))}
            </div>
          </div>
        )}

        {/* Document list */}
        {documents.length > 0 && (
          <div>
            {photos.length > 0 && (
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
                Documents ({documents.length})
              </p>
            )}
            <div className="space-y-1.5">
              {documents.map((att) => (
                <Button
                  key={att.id}
                  variant="ghost"
                  onClick={() => window.open(att.url, "_blank")}
                  className="w-full justify-start text-left bg-muted rounded p-2.5 hover:bg-accent h-auto"
                >
                  <div className="flex items-start gap-2">
                    <FileText className="h-4 w-4 text-muted-foreground mt-0.5 shrink-0" />
                    <div className="min-w-0">
                      <p className="text-sm font-medium truncate">{att.filename}</p>
                      {att.description && (
                        <p className="text-xs text-muted-foreground">{att.description}</p>
                      )}
                      <div className="flex items-center gap-1.5 mt-1">
                        <Badge variant="secondary" className="text-xs px-1.5 py-0">
                          {att.category_label}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          {att.log_date_label ?? att.created_at_label}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          &middot; {att.uploaded_by_name}
                        </span>
                      </div>
                    </div>
                  </div>
                </Button>
              ))}
            </div>
          </div>
        )}

        {filtered.length === 0 && (
          <p className="text-sm text-muted-foreground text-center py-8">
            No documents in this category.
          </p>
        )}
      </div>

      {showUploadForm && (
        <AttachmentForm path={attachments_path} onClose={() => setShowUploadForm(false)} />
      )}
    </div>
  );
}
