import { useMemo, useRef, useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { Camera, Pencil, Trash2, Upload } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { IncidentAttachment, Message } from "../types";
import PhotoUploadDialog from "./PhotoUploadDialog";

const PAGE_SIZE = 40;

interface PhotosPanelProps {
  attachments: IncidentAttachment[];
  messages: Message[];
  upload_photo_path: string;
  can_manage_attachments: boolean;
}

interface PhotoItem {
  id: string;
  source: "incident" | "message";
  attachment_id: number | null;
  filename: string;
  description: string | null;
  date_key: string;
  date_label: string;
  uploaded_by_name: string;
  url: string;
  thumbnail_url: string | null;
  created_at: string;
  search_context: string;
  update_path: string | null;
  destroy_path: string | null;
  log_date: string | null;
}

export default function PhotosPanel({ attachments, messages, upload_photo_path, can_manage_attachments }: PhotosPanelProps) {
  const { today } = usePage<SharedProps>().props;
  const uploadInputRef = useRef<HTMLInputElement>(null);
  const [showPhotoDialog, setShowPhotoDialog] = useState(false);
  const [search, setSearch] = useState("");
  const [uploader, setUploader] = useState("all");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [bulkUploading, setBulkUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [editingPhoto, setEditingPhoto] = useState<PhotoItem | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<PhotoItem | null>(null);

  const allPhotos = useMemo<PhotoItem[]>(() => {
    const incidentPhotos = attachments
      .filter((att) => att.category === "photo")
      .map((att) => ({
        id: `incident-${att.id}`,
        source: "incident" as const,
        attachment_id: att.id,
        filename: att.filename,
        description: att.description,
        date_key: att.log_date || att.created_at.slice(0, 10),
        date_label: att.log_date_label || att.created_at_label,
        uploaded_by_name: att.uploaded_by_name,
        url: att.url,
        thumbnail_url: att.thumbnail_url,
        created_at: att.created_at,
        search_context: [att.filename, att.description || "", att.uploaded_by_name].join(" ").toLowerCase(),
        update_path: att.update_path || null,
        destroy_path: att.destroy_path || null,
        log_date: att.log_date,
      }));

    const messagePhotos = messages.flatMap((message) =>
      (message.attachments || [])
        .filter((att) => att.content_type?.startsWith("image/"))
        .map((att) => ({
          id: `message-${message.id}-${att.id}`,
          source: "message" as const,
          attachment_id: null,
          filename: att.filename,
          description: message.body?.trim() ? message.body : null,
          date_key: att.created_at.slice(0, 10),
          date_label: att.created_at_label,
          uploaded_by_name: att.uploaded_by_name || message.sender.full_name,
          url: att.url,
          thumbnail_url: att.thumbnail_url,
          created_at: att.created_at,
          search_context: [att.filename, message.body || "", message.sender.full_name].join(" ").toLowerCase(),
          update_path: null,
          destroy_path: null,
          log_date: null,
        }))
    );

    return [ ...incidentPhotos, ...messagePhotos ].sort((a, b) => b.created_at.localeCompare(a.created_at));
  }, [attachments, messages]);

  const uploaderOptions = useMemo(
    () => [ ...new Set(allPhotos.map((photo) => photo.uploaded_by_name)) ].sort((a, b) => a.localeCompare(b)),
    [allPhotos]
  );

  const filteredPhotos = useMemo(() => {
    const term = search.trim().toLowerCase();
    return allPhotos.filter((photo) => {
      if (term && !photo.search_context.includes(term)) return false;
      if (uploader !== "all" && photo.uploaded_by_name !== uploader) return false;
      if (fromDate && photo.date_key < fromDate) return false;
      if (toDate && photo.date_key > toDate) return false;
      return true;
    });
  }, [allPhotos, search, uploader, fromDate, toDate]);

  const visiblePhotos = filteredPhotos.slice(0, visibleCount);
  const hasMore = visibleCount < filteredPhotos.length;

  const handleUploadPhotos = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files ? Array.from(e.target.files) : [];
    e.target.value = "";
    if (files.length === 0 || bulkUploading) return;

    setBulkUploading(true);
    setUploadError(null);

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content");

    const uploadOne = async (file: File) => {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("log_date", today);

      const response = await fetch(upload_photo_path, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken || "" },
        body: formData,
      });

      if (!response.ok) throw new Error("Upload failed");
    };

    const results = await Promise.allSettled(files.map((file) => uploadOne(file)));
    const failedCount = results.filter((result) => result.status === "rejected").length;

    if (failedCount > 0) {
      if (failedCount === files.length) {
        setUploadError(`No photos were uploaded (${failedCount} failed). Please try again or upload fewer files at once.`);
      } else {
        setUploadError(`Uploaded ${files.length - failedCount} of ${files.length} photos. You can retry the failed photos with Upload Photos or Take Photos.`);
      }
    } else {
      router.reload({ only: [ "attachments", "messages" ] });
    }

    if (failedCount > 0 && failedCount < files.length) {
      router.reload({ only: [ "attachments", "messages" ] });
    }

    setBulkUploading(false);
  };

  const handleDelete = (photo: PhotoItem) => {
    if (!photo.destroy_path) return;
    router.delete(photo.destroy_path, {
      preserveScroll: true,
      onSuccess: () => setConfirmDelete(null),
    });
  };

  return (
    <div className="flex flex-col h-full">
      <div className="p-3 border-b border-border bg-muted/15 shrink-0">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <p className="text-xs text-muted-foreground">
            {filteredPhotos.length} of {allPhotos.length} photos
          </p>
          {can_manage_attachments && (
            <div className="flex items-center gap-2">
              <Input
                ref={uploadInputRef}
                type="file"
                accept="image/*"
                multiple
                className="hidden"
                onChange={handleUploadPhotos}
                data-testid="photos-panel-upload-input"
              />
              <Button
                variant="outline"
                size="sm"
                className="h-10 sm:h-8 text-sm sm:text-xs gap-1"
                onClick={() => uploadInputRef.current?.click()}
                disabled={bulkUploading}
                data-testid="photos-panel-upload-button"
              >
                <Upload className="h-3 w-3" />
                {bulkUploading ? "Uploading..." : "Upload Photos"}
              </Button>
              <Button
                variant="default"
                size="sm"
                className="h-10 sm:h-8 text-sm sm:text-xs gap-1"
                onClick={() => setShowPhotoDialog(true)}
                disabled={bulkUploading}
                data-testid="photos-panel-take-photos-button"
              >
                <Camera className="h-3 w-3" />
                Take Photos
              </Button>
            </div>
          )}
        </div>
        <InlineActionFeedback error={uploadError} onDismiss={() => setUploadError(null)} className="mt-2" />
      </div>

      <div className="border-b border-border bg-card/60 p-3 shrink-0">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-2">
          <div>
            <label className="text-xs text-muted-foreground mb-1 block">Search</label>
            <Input
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setVisibleCount(PAGE_SIZE);
              }}
              placeholder="Filename or note..."
              className="h-9 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-muted-foreground mb-1 block">Uploader</label>
            <select
              value={uploader}
              onChange={(e) => {
                setUploader(e.target.value);
                setVisibleCount(PAGE_SIZE);
              }}
              className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm"
            >
              <option value="all">All uploaders</option>
              {uploaderOptions.map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="text-xs text-muted-foreground mb-1 block">Start date</label>
            <Input
              type="date"
              value={fromDate}
              onChange={(e) => {
                setFromDate(e.target.value);
                setVisibleCount(PAGE_SIZE);
              }}
              className="h-9 text-sm"
            />
          </div>
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs text-muted-foreground">End date</label>
              <button
                type="button"
                className="text-xs text-primary hover:underline"
                onClick={() => { setToDate(today); setVisibleCount(PAGE_SIZE); }}
              >
                Today
              </button>
            </div>
            <Input
              type="date"
              value={toDate}
              onChange={(e) => {
                setToDate(e.target.value);
                setVisibleCount(PAGE_SIZE);
              }}
              className="h-9 text-sm"
            />
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 pb-10">
        {filteredPhotos.length === 0 ? (
          <div className="rounded-lg border border-dashed border-border bg-muted/10 p-6 text-center text-sm text-muted-foreground">
            No photos match the current filters.
          </div>
        ) : (
          <>
            <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-5 gap-3">
              {visiblePhotos.map((photo) => (
                <div
                  key={photo.id}
                  className="rounded-lg border border-border bg-card overflow-hidden hover:border-primary transition-colors group relative"
                >
                  <a
                    href={photo.url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <div className="relative aspect-square bg-muted">
                      {(photo.thumbnail_url || photo.url) ? (
                        <img
                          src={photo.thumbnail_url || photo.url}
                          alt={photo.description || photo.filename}
                          className="w-full h-full object-cover"
                          loading="lazy"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-xs text-muted-foreground">
                          No preview
                        </div>
                      )}
                      {photo.source === "message" && (
                        <span className="absolute top-1.5 right-1.5 rounded bg-black/65 px-1.5 py-0.5 text-xs font-medium uppercase tracking-wide text-white">
                          Msg
                        </span>
                      )}
                    </div>
                  </a>
                  <div className="p-2">
                    <p className="text-xs font-medium text-foreground truncate">
                      {photo.description || photo.filename}
                    </p>
                    <p className="text-xs text-muted-foreground truncate mt-0.5">
                      {photo.date_label}
                    </p>
                    <div className="flex items-center justify-between mt-0.5">
                      <p className="text-xs text-muted-foreground truncate">
                        {photo.uploaded_by_name}
                      </p>
                      {can_manage_attachments && photo.source === "incident" && (
                        <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                          {photo.update_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                              onClick={(e) => { e.preventDefault(); setEditingPhoto(photo); }}
                              title="Edit photo"
                            >
                              <Pencil className="h-3 w-3" />
                            </Button>
                          )}
                          {photo.destroy_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                              onClick={(e) => { e.preventDefault(); setConfirmDelete(photo); }}
                              title="Delete photo"
                            >
                              <Trash2 className="h-3 w-3" />
                            </Button>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-4 flex items-center justify-between">
              <p className="text-xs text-muted-foreground">
                Showing {visiblePhotos.length} of {filteredPhotos.length}
              </p>
              {hasMore && (
                <Button
                  variant="outline"
                  size="sm"
                  className="h-9 sm:h-8 text-sm sm:text-xs"
                  onClick={() => setVisibleCount((prev) => prev + PAGE_SIZE)}
                >
                  Load more
                </Button>
              )}
            </div>
          </>
        )}
      </div>

      <PhotoUploadDialog
        upload_photo_path={upload_photo_path}
        open={showPhotoDialog}
        onClose={() => setShowPhotoDialog(false)}
      />

      {/* Edit photo dialog */}
      {editingPhoto && editingPhoto.update_path && (
        <PhotoEditDialog
          photo={editingPhoto}
          onClose={() => setEditingPhoto(null)}
        />
      )}

      {/* Confirm delete dialog */}
      <Dialog open={!!confirmDelete} onOpenChange={(open) => !open && setConfirmDelete(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Photo</DialogTitle>
          </DialogHeader>
          <p className="text-sm">
            Delete <span className="font-medium">{confirmDelete?.filename}</span>? This cannot be undone.
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="ghost" size="sm" onClick={() => setConfirmDelete(null)}>Cancel</Button>
            <Button variant="destructive" size="sm" onClick={() => confirmDelete && handleDelete(confirmDelete)}>
              Delete
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function PhotoEditDialog({ photo, onClose }: { photo: PhotoItem; onClose: () => void }) {
  const [description, setDescription] = useState(photo.description || "");
  const [logDate, setLogDate] = useState(photo.log_date || "");
  const [saving, setSaving] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!photo.update_path || saving) return;
    setSaving(true);
    router.patch(photo.update_path, {
      attachment: { description, log_date: logDate || null },
    }, {
      preserveScroll: true,
      onSuccess: onClose,
      onFinish: () => setSaving(false),
    });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Edit Photo</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSave} className="space-y-3">
          <div>
            <label htmlFor="photo-description" className="text-xs font-medium text-muted-foreground">Description</label>
            <Input
              id="photo-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add a description..."
              className="mt-1"
            />
          </div>
          <div>
            <label htmlFor="photo-date" className="text-xs font-medium text-muted-foreground">Date</label>
            <Input
              id="photo-date"
              type="date"
              value={logDate}
              onChange={(e) => setLogDate(e.target.value)}
              className="mt-1"
            />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose} disabled={saving}>Cancel</Button>
            <Button type="submit" size="sm" disabled={saving}>
              {saving ? "Saving..." : "Save"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
