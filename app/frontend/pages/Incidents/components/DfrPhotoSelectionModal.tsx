import { useCallback, useMemo, useState } from "react";
import { AlertCircle, Check, FileText, ImageIcon, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { DfrSelectablePhoto, IncidentAttachment } from "../types";

interface DfrPhotoSelectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (photoIds: number[], documentIds: number[]) => void;
  dateLabel: string;
  photos: DfrSelectablePhoto[];
  documents: IncidentAttachment[];
  isLoading: boolean;
  loadError: boolean;
  onRetry: () => void;
}

function formatBytes(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  if (bytes >= 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${bytes} B`;
}

interface PhotoGroup {
  dateKey: string;
  dateLabel: string;
  isReportDate: boolean;
  photos: DfrSelectablePhoto[];
}

export default function DfrPhotoSelectionModal({
  isOpen,
  onClose,
  onSubmit,
  dateLabel,
  photos,
  documents,
  isLoading,
  loadError,
  onRetry,
}: DfrPhotoSelectionModalProps) {
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());
  const [selectedDocIds, setSelectedDocIds] = useState<Set<number>>(new Set());

  // The report date's photos are what today's behavior includes by default —
  // preselect them so "open modal, hit Generate" matches the old one-click flow.
  // State-adjustment-during-render (not an effect): reset the selection when a
  // new photo list arrives (documents arrive from the same fetch).
  const [prevPhotos, setPrevPhotos] = useState<DfrSelectablePhoto[]>(photos);
  if (photos !== prevPhotos) {
    setPrevPhotos(photos);
    setSelectedIds(new Set(photos.filter((p) => p.is_report_date).map((p) => p.id)));
    setSelectedDocIds(new Set());
  }

  // Report date group first, remaining days newest-first.
  const groups = useMemo<PhotoGroup[]>(() => {
    const byKey = new Map<string, PhotoGroup>();
    for (const photo of photos) {
      let group = byKey.get(photo.date_key);
      if (!group) {
        group = { dateKey: photo.date_key, dateLabel: photo.date_label, isReportDate: photo.is_report_date, photos: [] };
        byKey.set(photo.date_key, group);
      }
      group.photos.push(photo);
    }
    return Array.from(byKey.values()).sort((a, b) => {
      if (a.isReportDate !== b.isReportDate) return a.isReportDate ? -1 : 1;
      return b.dateKey.localeCompare(a.dateKey);
    });
  }, [photos]);

  const allSelected = useMemo(
    () => photos.length > 0 && selectedIds.size === photos.length,
    [photos.length, selectedIds.size]
  );

  const togglePhoto = useCallback((id: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleDocument = useCallback((id: number) => {
    setSelectedDocIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleAll = useCallback(() => {
    if (allSelected) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(photos.map((p) => p.id)));
    }
  }, [allSelected, photos]);

  const toggleGroup = useCallback((group: PhotoGroup) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      const groupIds = group.photos.map((p) => p.id);
      const groupAllSelected = groupIds.every((id) => next.has(id));
      if (groupAllSelected) {
        groupIds.forEach((id) => next.delete(id));
      } else {
        groupIds.forEach((id) => next.add(id));
      }
      return next;
    });
  }, []);

  const handleSubmit = useCallback(() => {
    onSubmit(Array.from(selectedIds), Array.from(selectedDocIds));
  }, [onSubmit, selectedIds, selectedDocIds]);

  const handleOpenChange = useCallback(
    (open: boolean) => {
      if (!open) {
        onClose();
        setSelectedIds(new Set());
        setSelectedDocIds(new Set());
      }
    },
    [onClose]
  );

  const totalSelected = selectedIds.size + selectedDocIds.size;
  const hasContent = photos.length > 0 || documents.length > 0;

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-2xl max-h-[85vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>
            Select {documents.length > 0 ? "Photos & Documents" : "Photos"} for DFR — {dateLabel}
          </DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : loadError ? (
          <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
            <AlertCircle className="h-8 w-8 mb-2 text-destructive" />
            <p className="text-sm mb-3">Could not load photos.</p>
            <Button variant="outline" size="sm" onClick={onRetry}>
              Try again
            </Button>
          </div>
        ) : !hasContent ? (
          <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
            <ImageIcon className="h-8 w-8 mb-2" />
            <p className="text-sm">No photos or documents on this incident.</p>
            <p className="text-xs mt-1">You can still generate the DFR without attachments.</p>
          </div>
        ) : (
          <>
            {photos.length > 0 && (
              <div className="flex items-center justify-between border-b border-border pb-3">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={toggleAll}
                  className="flex items-center gap-2 text-sm text-foreground hover:text-primary px-0"
                >
                  <span
                    className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-sm border ${
                      allSelected
                        ? "bg-primary border-primary text-primary-foreground"
                        : "border-muted-foreground/40"
                    }`}
                  >
                    {allSelected && <Check className="h-3 w-3" />}
                  </span>
                  Select all photos
                </Button>
                <span className="text-sm text-muted-foreground">
                  {totalSelected} of {photos.length + documents.length} selected
                </span>
              </div>
            )}

            <div className="flex-1 overflow-y-auto min-h-0 -mx-1 px-1">
              {documents.length > 0 && (
                <div className="py-2 mb-2 border-b border-border">
                  <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">
                    Documents
                  </p>
                  <div className="space-y-1">
                    {documents.map((doc) => {
                      const isSelected = selectedDocIds.has(doc.id);
                      return (
                        <Button
                          key={doc.id}
                          variant="ghost"
                          onClick={() => toggleDocument(doc.id)}
                          className={`w-full justify-start gap-2 h-auto py-2 px-2 rounded-md border ${
                            isSelected
                              ? "border-primary/60 bg-primary/5"
                              : "border-transparent hover:border-muted-foreground/30"
                          }`}
                        >
                          <span
                            className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-sm border ${
                              isSelected
                                ? "bg-primary border-primary text-primary-foreground"
                                : "border-muted-foreground/40"
                            }`}
                          >
                            {isSelected && <Check className="h-3 w-3" />}
                          </span>
                          <FileText className="h-4 w-4 shrink-0 text-muted-foreground" />
                          <span className="truncate text-sm">{doc.filename}</span>
                          <span className="ml-auto shrink-0 text-xs text-muted-foreground">
                            {doc.category_label} · {formatBytes(doc.byte_size)}
                          </span>
                        </Button>
                      );
                    })}
                  </div>
                </div>
              )}

              {groups.map((group) => {
                const groupAllSelected = group.photos.every((p) => selectedIds.has(p.id));
                return (
                  <div key={group.dateKey} className="py-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => toggleGroup(group)}
                      className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 hover:text-primary h-auto p-0"
                    >
                      <span
                        className={`flex h-3.5 w-3.5 shrink-0 items-center justify-center rounded-sm border ${
                          groupAllSelected
                            ? "bg-primary border-primary text-primary-foreground"
                            : "border-muted-foreground/40"
                        }`}
                      >
                        {groupAllSelected && <Check className="h-2.5 w-2.5" />}
                      </span>
                      {group.dateLabel}
                      {group.isReportDate && <span className="normal-case font-normal">(report date)</span>}
                    </Button>
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                      {group.photos.map((photo) => {
                        const isSelected = selectedIds.has(photo.id);
                        return (
                          <Button
                            key={photo.id}
                            variant="ghost"
                            onClick={() => togglePhoto(photo.id)}
                            className={`relative aspect-square rounded-md overflow-hidden border-2 transition-all h-auto p-0 ${
                              isSelected
                                ? "border-primary ring-1 ring-primary/30"
                                : "border-transparent hover:border-muted-foreground/30"
                            }`}
                          >
                            <img
                              src={photo.thumbnail_url || photo.url}
                              alt={photo.description || photo.filename}
                              loading="lazy"
                              className="w-full h-full object-cover"
                            />
                            <span
                              className={`absolute top-1.5 right-1.5 flex h-5 w-5 items-center justify-center rounded-sm border shadow-sm ${
                                isSelected
                                  ? "bg-primary border-primary text-primary-foreground"
                                  : "bg-background/80 border-muted-foreground/40"
                              }`}
                            >
                              {isSelected && <Check className="h-3.5 w-3.5" />}
                            </span>
                            {photo.description && (
                              <span className="absolute bottom-0 inset-x-0 bg-black/50 text-white text-xs px-1.5 py-0.5 truncate">
                                {photo.description}
                              </span>
                            )}
                          </Button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}

            </div>
          </>
        )}

        <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center justify-between gap-2 border-t border-border pt-3">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <div className="flex items-center justify-end gap-3">
            {hasContent && !loadError && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onSubmit([], [])}
                className="text-muted-foreground"
              >
                Skip attachments
              </Button>
            )}
            <Button
              onClick={handleSubmit}
              disabled={(hasContent && totalSelected === 0) || isLoading || loadError}
            >
              Generate DFR
              {totalSelected > 0 && (
                <span className="ml-1.5 text-xs opacity-80">
                  ({totalSelected} item{totalSelected !== 1 ? "s" : ""})
                </span>
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
