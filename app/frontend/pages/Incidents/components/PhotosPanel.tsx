import { useMemo, useRef, useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { Camera, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { IncidentAttachment, Message } from "../types";
import PhotoUploadDialog from "./PhotoUploadDialog";

const PAGE_SIZE = 40;

interface PhotosPanelProps {
  attachments: IncidentAttachment[];
  messages: Message[];
  upload_photo_path: string;
}

interface PhotoItem {
  id: string;
  source: "incident" | "message";
  filename: string;
  description: string | null;
  date_key: string;
  date_label: string;
  uploaded_by_name: string;
  url: string;
  thumbnail_url: string | null;
  created_at: string;
  search_context: string;
}

export default function PhotosPanel({ attachments, messages, upload_photo_path }: PhotosPanelProps) {
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

  const allPhotos = useMemo<PhotoItem[]>(() => {
    const incidentPhotos = attachments
      .filter((att) => att.category === "photo")
      .map((att) => ({
        id: `incident-${att.id}`,
        source: "incident" as const,
        filename: att.filename,
        description: att.description,
        date_key: att.log_date || att.created_at.slice(0, 10),
        date_label: att.log_date_label || att.created_at_label,
        uploaded_by_name: att.uploaded_by_name,
        url: att.url,
        thumbnail_url: att.thumbnail_url,
        created_at: att.created_at,
        search_context: [att.filename, att.description || "", att.uploaded_by_name].join(" ").toLowerCase(),
      }));

    const messagePhotos = messages.flatMap((message) =>
      (message.attachments || [])
        .filter((att) => att.content_type?.startsWith("image/"))
        .map((att) => ({
          id: `message-${message.id}-${att.id}`,
          source: "message" as const,
          filename: att.filename,
          description: message.body?.trim() ? message.body : null,
          date_key: att.created_at.slice(0, 10),
          date_label: att.created_at_label,
          uploaded_by_name: att.uploaded_by_name || message.sender.full_name,
          url: att.url,
          thumbnail_url: att.thumbnail_url,
          created_at: att.created_at,
          search_context: [att.filename, message.body || "", message.sender.full_name].join(" ").toLowerCase(),
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
      setUploadError(`Uploaded ${files.length - failedCount} of ${files.length} photos.`);
    } else {
      router.reload({ only: [ "attachments", "messages" ] });
    }

    if (failedCount > 0 && failedCount < files.length) {
      router.reload({ only: [ "attachments", "messages" ] });
    }

    setBulkUploading(false);
  };

  return (
    <div className="flex flex-col h-full">
      <div className="p-3 border-b border-border bg-muted/15 shrink-0">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <p className="text-xs text-muted-foreground">
            {filteredPhotos.length} of {allPhotos.length} photos
          </p>
          <div className="flex items-center gap-2">
            <Input
              ref={uploadInputRef}
              type="file"
              accept="image/*"
              multiple
              className="hidden"
              onChange={handleUploadPhotos}
            />
            <Button
              variant="outline"
              size="sm"
              className="h-10 sm:h-8 text-sm sm:text-xs gap-1"
              onClick={() => uploadInputRef.current?.click()}
              disabled={bulkUploading}
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
            >
              <Camera className="h-3 w-3" />
              Take Photos
            </Button>
          </div>
        </div>
        {uploadError && (
          <p className="mt-2 text-xs text-destructive">{uploadError}</p>
        )}
      </div>

      <div className="border-b border-border bg-card/60 p-3 shrink-0">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-2">
          <Input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setVisibleCount(PAGE_SIZE);
            }}
            placeholder="Search filename or note..."
            className="h-9 text-sm"
          />
          <select
            value={uploader}
            onChange={(e) => {
              setUploader(e.target.value);
              setVisibleCount(PAGE_SIZE);
            }}
            className="h-9 rounded-md border border-input bg-background px-3 text-sm"
          >
            <option value="all">All uploaders</option>
            {uploaderOptions.map((name) => (
              <option key={name} value={name}>
                {name}
              </option>
            ))}
          </select>
          <Input
            type="date"
            value={fromDate}
            onChange={(e) => {
              setFromDate(e.target.value);
              setVisibleCount(PAGE_SIZE);
            }}
            className="h-9 text-sm"
          />
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

      <div className="flex-1 overflow-y-auto p-4 pb-10">
        {filteredPhotos.length === 0 ? (
          <div className="rounded-lg border border-dashed border-border bg-muted/10 p-6 text-center text-sm text-muted-foreground">
            No photos match the current filters.
          </div>
        ) : (
          <>
            <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-5 gap-3">
              {visiblePhotos.map((photo) => (
                <a
                  key={photo.id}
                  href={photo.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="rounded-lg border border-border bg-card overflow-hidden hover:border-primary transition-colors"
                >
                  <div className="relative aspect-square bg-muted">
                    {photo.thumbnail_url ? (
                      <img
                        src={photo.thumbnail_url}
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
                      <span className="absolute top-1.5 right-1.5 rounded bg-black/65 px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide text-white">
                        Msg
                      </span>
                    )}
                  </div>
                  <div className="p-2">
                    <p className="text-xs font-medium text-foreground truncate">
                      {photo.description || photo.filename}
                    </p>
                    <p className="text-[11px] text-muted-foreground truncate mt-0.5">
                      {photo.date_label}
                    </p>
                    <p className="text-[11px] text-muted-foreground truncate">
                      {photo.uploaded_by_name}
                    </p>
                  </div>
                </a>
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
    </div>
  );
}
