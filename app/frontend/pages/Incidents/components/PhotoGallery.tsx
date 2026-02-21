import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import type { IncidentAttachment } from "../types";

interface PhotoGalleryProps {
  photos: IncidentAttachment[];
  open: boolean;
  onClose: () => void;
}

export default function PhotoGallery({
  photos,
  open,
  onClose,
}: PhotoGalleryProps) {
  return (
    <Dialog open={open} onOpenChange={(isOpen) => !isOpen && onClose()}>
      <DialogContent className="max-w-2xl max-h-[85vh] flex flex-col p-0 gap-0">
        <DialogHeader className="px-4 pt-4 pb-3 border-b border-border shrink-0">
          <DialogTitle className="text-base">
            All Photos ({photos.length})
          </DialogTitle>
          <DialogDescription className="sr-only">
            Browse all uploaded photos for this incident
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto p-4">
          <div className="grid grid-cols-4 gap-2">
            {photos.map((photo) => (
              <Button
                key={photo.id}
                variant="ghost"
                onClick={() => window.open(photo.url, "_blank")}
                className="h-auto p-0 rounded border border-border overflow-hidden hover:border-primary text-left"
              >
                <div className="w-full">
                  <div className="aspect-square bg-muted">
                    {photo.thumbnail_url ? (
                      <img
                        src={photo.thumbnail_url}
                        alt={photo.description || photo.filename}
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
                      {photo.description || photo.filename}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {photo.log_date_label ?? photo.created_at_label}
                    </p>
                  </div>
                </div>
              </Button>
            ))}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
