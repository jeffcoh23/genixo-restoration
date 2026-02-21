import { useState } from "react";
import { Camera, FileText, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { IncidentAttachment } from "../types";
import AttachmentForm from "./AttachmentForm";
import PhotoUploadDialog from "./PhotoUploadDialog";
import PhotoGallery from "./PhotoGallery";

const DOCUMENT_CATEGORIES = [
  { value: "photo", label: "Photos" },
  { value: "moisture_mapping", label: "Moisture Mapping" },
  { value: "moisture_readings", label: "Moisture Readings" },
  { value: "psychrometric_log", label: "Psychrometric Log" },
  { value: "signed_document", label: "Signed Documents" },
  { value: "sign_in_sheet", label: "Sign-In Sheets" },
  { value: "general", label: "General" },
];

const MAX_PHOTO_STRIP = 8;

interface DocumentPanelProps {
  attachments: IncidentAttachment[];
  attachments_path: string;
  upload_photo_path: string;
}

export default function DocumentPanel({
  attachments,
  attachments_path,
  upload_photo_path,
}: DocumentPanelProps) {
  const [showUploadForm, setShowUploadForm] = useState(false);
  const [showPhotoDialog, setShowPhotoDialog] = useState(false);
  const [showGallery, setShowGallery] = useState(false);

  const photos = attachments.filter((a) => a.category === "photo");
  const nonPhotoCategories = DOCUMENT_CATEGORIES.filter(
    (c) => c.value !== "photo"
  );

  const attachmentsByCategory = (category: string) =>
    attachments.filter((a) => a.category === category);

  const visiblePhotos = photos.slice(0, MAX_PHOTO_STRIP);
  const overflowCount = photos.length - MAX_PHOTO_STRIP;

  return (
    <div className="flex flex-col h-full">
      {/* Upload bar — two entry points */}
      <div className="flex items-center justify-end gap-2 p-3 border-b border-border shrink-0">
        <Button
          variant="default"
          size="sm"
          className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5"
          onClick={() => setShowPhotoDialog(true)}
        >
          <Camera className="h-3.5 w-3.5 sm:h-3 sm:w-3" />
          Take Photos
        </Button>
        <Button
          variant="outline"
          size="sm"
          className="h-10 sm:h-8 text-sm sm:text-xs gap-1.5"
          onClick={() => setShowUploadForm(true)}
        >
          <Upload className="h-3.5 w-3.5 sm:h-3 sm:w-3" />
          Upload Document
        </Button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-3 pb-8 space-y-5">
        {/* Photos section with thumbnail strip */}
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
            Photos ({photos.length})
          </p>

          {photos.length === 0 ? (
            <p className="text-xs text-muted-foreground pl-1">
              No photos uploaded.
            </p>
          ) : (
            <>
              <div className="grid grid-cols-4 gap-2">
                {visiblePhotos.map((att) => (
                  <Button
                    key={att.id}
                    variant="ghost"
                    onClick={() => window.open(att.url, "_blank")}
                    className="h-auto p-0 rounded border border-border overflow-hidden hover:border-primary text-left"
                  >
                    <div className="w-full">
                      <div className="aspect-square bg-muted">
                        {att.thumbnail_url ? (
                          <img
                            src={att.thumbnail_url}
                            alt={att.description || att.filename}
                            className="w-full h-full object-cover"
                            loading="lazy"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-muted-foreground text-xs">
                            No preview
                          </div>
                        )}
                      </div>
                      <div className="p-1.5">
                        <p className="text-xs font-medium truncate">
                          {att.description || att.filename}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {att.log_date_label ?? att.created_at_label}
                        </p>
                      </div>
                    </div>
                  </Button>
                ))}
              </div>
              {overflowCount > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="mt-2 h-7 text-xs text-muted-foreground"
                  onClick={() => setShowGallery(true)}
                >
                  View all {photos.length} photos
                </Button>
              )}
            </>
          )}
        </div>

        {/* Non-photo document categories */}
        {nonPhotoCategories.map((cat) => {
          const items = attachmentsByCategory(cat.value);

          return (
            <div key={cat.value}>
              <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-2">
                {cat.label} ({items.length})
              </p>

              {items.length === 0 ? (
                <p className="text-xs text-muted-foreground pl-1">
                  No {cat.label.toLowerCase()} uploaded.
                </p>
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
                          <p className="text-sm font-medium truncate">
                            {att.filename}
                          </p>
                          {att.description && (
                            <p className="text-xs text-muted-foreground">
                              {att.description}
                            </p>
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
        <AttachmentForm
          path={attachments_path}
          onClose={() => setShowUploadForm(false)}
        />
      )}

      <PhotoUploadDialog
        upload_photo_path={upload_photo_path}
        open={showPhotoDialog}
        onClose={() => setShowPhotoDialog(false)}
      />

      <PhotoGallery
        photos={photos}
        open={showGallery}
        onClose={() => setShowGallery(false)}
      />
    </div>
  );
}
