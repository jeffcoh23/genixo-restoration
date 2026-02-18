import { useState } from "react";
import { FileText, Image, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { IncidentAttachment } from "../types";
import AttachmentForm from "./AttachmentForm";

const DOCUMENT_CATEGORIES = [
  { value: "photo", label: "Photos" },
  { value: "moisture_mapping", label: "Moisture Mapping" },
  { value: "moisture_readings", label: "Moisture Readings" },
  { value: "psychrometric_log", label: "Psychrometric Log" },
  { value: "signed_document", label: "Signed Documents" },
  { value: "sign_in_sheet", label: "Sign-In Sheets" },
  { value: "general", label: "General" },
];

interface DocumentPanelProps {
  attachments: IncidentAttachment[];
  attachments_path: string;
}

export default function DocumentPanel({ attachments, attachments_path }: DocumentPanelProps) {
  const [showUploadForm, setShowUploadForm] = useState(false);

  const attachmentsByCategory = (category: string) =>
    attachments.filter((a) => a.category === category);

  return (
    <div className="flex flex-col h-full">
      {/* Upload bar */}
      <div className="flex items-center justify-end p-3 border-b border-border shrink-0">
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

      {/* Content — all categories shown */}
      <div className="flex-1 overflow-y-auto p-3 pb-8 space-y-5">
        {DOCUMENT_CATEGORIES.map((cat) => {
          const items = attachmentsByCategory(cat.value);
          const isPhoto = cat.value === "photo";

          return (
            <div key={cat.value}>
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
                {cat.label} ({items.length})
              </p>

              {items.length === 0 ? (
                <p className="text-xs text-muted-foreground pl-1">
                  No {cat.label.toLowerCase()} uploaded.
                </p>
              ) : isPhoto ? (
                <div className="grid grid-cols-2 gap-2">
                  {items.map((att) => (
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
              ) : (
                <div className="space-y-1.5">
                  {items.map((att) => (
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
              )}
            </div>
          );
        })}
      </div>

      {showUploadForm && (
        <AttachmentForm path={attachments_path} onClose={() => setShowUploadForm(false)} />
      )}
    </div>
  );
}
