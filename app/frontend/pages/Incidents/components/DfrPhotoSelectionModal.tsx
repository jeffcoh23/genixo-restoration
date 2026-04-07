import { useCallback, useMemo, useState } from "react";
import { Check, ImageIcon, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { IncidentAttachment } from "../types";

interface DfrPhotoSelectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (photoIds: number[]) => void;
  dateLabel: string;
  photos: IncidentAttachment[];
  isLoading: boolean;
}

export default function DfrPhotoSelectionModal({
  isOpen,
  onClose,
  onSubmit,
  dateLabel,
  photos,
  isLoading,
}: DfrPhotoSelectionModalProps) {
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());

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

  const toggleAll = useCallback(() => {
    if (allSelected) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(photos.map((p) => p.id)));
    }
  }, [allSelected, photos]);

  const handleSubmit = useCallback(() => {
    onSubmit(Array.from(selectedIds));
  }, [onSubmit, selectedIds]);

  const handleOpenChange = useCallback(
    (open: boolean) => {
      if (!open) {
        onClose();
        setSelectedIds(new Set());
      }
    },
    [onClose]
  );

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-2xl max-h-[85vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Select Photos for DFR — {dateLabel}</DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : photos.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
            <ImageIcon className="h-8 w-8 mb-2" />
            <p className="text-sm">No photos for this date.</p>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between border-b border-border pb-3">
              <button
                type="button"
                onClick={toggleAll}
                className="flex items-center gap-2 text-sm text-foreground hover:text-primary transition-colors"
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
                Select all
              </button>
              <span className="text-sm text-muted-foreground">
                {selectedIds.size} of {photos.length} selected
              </span>
            </div>

            <div className="flex-1 overflow-y-auto min-h-0 -mx-1 px-1">
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-2 py-2">
                {photos.map((photo) => {
                  const isSelected = selectedIds.has(photo.id);
                  return (
                    <button
                      key={photo.id}
                      type="button"
                      onClick={() => togglePhoto(photo.id)}
                      className={`relative aspect-square rounded-md overflow-hidden border-2 transition-all ${
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
                        <span className="absolute bottom-0 inset-x-0 bg-black/50 text-white text-[10px] px-1.5 py-0.5 truncate">
                          {photo.description}
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          </>
        )}

        <div className="flex items-center justify-between border-t border-border pt-3">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <div className="flex items-center gap-3">
            {photos.length > 0 && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleSubmitWithoutPhotos()}
                className="text-muted-foreground"
              >
                Skip photos
              </Button>
            )}
            <Button
              onClick={handleSubmit}
              disabled={selectedIds.size === 0 || isLoading}
            >
              Generate DFR
              {selectedIds.size > 0 && (
                <span className="ml-1.5 text-xs opacity-80">
                  ({selectedIds.size} photo{selectedIds.size !== 1 ? "s" : ""})
                </span>
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );

  function handleSubmitWithoutPhotos() {
    onSubmit([]);
  }
}
