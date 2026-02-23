import { useState, useRef, useCallback, useEffect } from "react";
import { router, usePage } from "@inertiajs/react";
import { Camera, ImagePlus, Check, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { SharedProps } from "@/types";
import imageCompression from "browser-image-compression";

interface PhotoUploadDialogProps {
  upload_photo_path: string;
  open: boolean;
  onClose: () => void;
}

interface PhotoStatus {
  id: string;
  name: string;
  state: "compressing" | "uploading" | "done" | "error";
}

const compressPhoto = async (file: File): Promise<File> => {
  return imageCompression(file, {
    maxSizeMB: 0.5,
    maxWidthOrHeight: 1600,
    useWebWorker: true,
    fileType: "image/jpeg",
  });
};

export default function PhotoUploadDialog({
  upload_photo_path,
  open,
  onClose,
}: PhotoUploadDialogProps) {
  const { today } = usePage<SharedProps>().props;
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const galleryInputRef = useRef<HTMLInputElement>(null);

  const [cameraActive, setCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [photos, setPhotos] = useState<PhotoStatus[]>([]);
  const [logDate, setLogDate] = useState(today);
  const [description, setDescription] = useState("");
  const [closeBlocked, setCloseBlocked] = useState(false);

  const doneCount = photos.filter((p) => p.state === "done").length;
  const activeCount = photos.filter(
    (p) => p.state === "compressing" || p.state === "uploading"
  ).length;
  const errorCount = photos.filter((p) => p.state === "error").length;

  const startCamera = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "environment",
          width: { ideal: 1920 },
          height: { ideal: 1080 },
        },
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
      setCameraActive(true);
      setCameraError(null);
    } catch {
      setCameraError(
        "Could not access camera. Please allow camera permissions or use the gallery."
      );
    }
  }, []);

  const stopCamera = useCallback(() => {
    streamRef.current?.getTracks().forEach((track) => track.stop());
    streamRef.current = null;
    setCameraActive(false);
  }, []);

  // Start camera when dialog opens
  useEffect(() => {
    if (open) {
      startCamera();
      setCloseBlocked(false);
    }
    return () => {
      stopCamera();
    };
  }, [open, startCamera, stopCamera]);

  const uploadFile = useCallback(
    async (file: File) => {
      const photoId = `photo-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;

      setPhotos((prev) => [...prev, { id: photoId, name: file.name, state: "compressing" }]);

      try {
        const compressed = await compressPhoto(file);

        setPhotos((prev) =>
          prev.map((p) =>
            p.id === photoId ? { ...p, state: "uploading" } : p
          )
        );

        const formData = new FormData();
        formData.append("file", compressed);
        formData.append("log_date", logDate);
        if (description) formData.append("description", description);

        const csrfToken = document
          .querySelector('meta[name="csrf-token"]')
          ?.getAttribute("content");

        const response = await fetch(upload_photo_path, {
          method: "POST",
          headers: { "X-CSRF-Token": csrfToken || "" },
          body: formData,
        });

        if (!response.ok) throw new Error("Upload failed");

        setPhotos((prev) =>
          prev.map((p) => (p.id === photoId ? { ...p, state: "done" } : p))
        );
      } catch {
        setPhotos((prev) =>
          prev.map((p) => (p.id === photoId ? { ...p, state: "error" } : p))
        );
      }
    },
    [upload_photo_path, logDate, description]
  );

  const handleSnap = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext("2d")!.drawImage(video, 0, 0);
    canvas.toBlob(
      (blob) => {
        if (!blob) return;
        const file = new File([blob], `photo-${Date.now()}.jpg`, {
          type: "image/jpeg",
        });
        uploadFile(file);
      },
      "image/jpeg",
      0.92
    );
  }, [uploadFile]);

  const handleGallerySelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = e.target.files;
      if (!files) return;
      Array.from(files).forEach((file) => uploadFile(file));
      // Reset input so the same files can be re-selected
      e.target.value = "";
    },
    [uploadFile]
  );

  const handleDone = useCallback(() => {
    if (activeCount > 0) {
      setCloseBlocked(true);
      return;
    }
    stopCamera();
    router.reload({ only: [ "attachments", "messages" ] });
    onClose();
  }, [activeCount, stopCamera, onClose]);

  return (
    <Dialog open={open} onOpenChange={(isOpen) => !isOpen && handleDone()}>
      <DialogContent className="max-w-2xl h-[90vh] flex flex-col p-0 gap-0">
        <DialogHeader className="px-4 pt-4 pb-3 border-b border-border shrink-0">
          <DialogTitle className="text-base">Take Photos</DialogTitle>
          <DialogDescription className="sr-only">
            Capture photos using your camera or select from gallery
          </DialogDescription>
          <div className="flex items-center gap-3 mt-2">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Date
              </label>
              <Input
                type="date"
                value={logDate}
                onChange={(e) => setLogDate(e.target.value)}
                className="h-8 text-xs w-36 mt-0.5"
                data-testid="photo-dialog-date"
              />
            </div>
            <div className="flex-1">
              <label className="text-xs font-medium text-muted-foreground">
                Description
              </label>
              <Input
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Optional — applies to all photos"
                className="h-8 text-xs mt-0.5"
                data-testid="photo-dialog-description"
              />
            </div>
          </div>
        </DialogHeader>

        {/* Camera preview */}
        <div className="flex-1 relative bg-black overflow-hidden">
          {cameraError ? (
            <div className="absolute inset-0 flex items-center justify-center p-6">
              <div className="text-center text-white/80">
                <Camera className="h-12 w-12 mx-auto mb-3 opacity-40" />
                <p className="text-sm">{cameraError}</p>
                <Button
                  variant="outline"
                  size="sm"
                  className="mt-4"
                  onClick={() => galleryInputRef.current?.click()}
                >
                  <ImagePlus className="h-4 w-4 mr-1.5" />
                  Select from Gallery
                </Button>
              </div>
            </div>
          ) : (
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted
              className="w-full h-full object-cover"
            />
          )}
        </div>

        {/* Bottom bar */}
        <div className="flex items-center justify-between px-4 py-3 border-t border-border bg-background shrink-0">
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              className="h-8 text-xs gap-1.5"
              onClick={() => galleryInputRef.current?.click()}
              data-testid="photo-dialog-gallery-button"
            >
              <ImagePlus className="h-3.5 w-3.5" />
              Gallery
            </Button>
            <Input
              ref={galleryInputRef}
              type="file"
              accept="image/*"
              multiple
              className="hidden"
              onChange={handleGallerySelect}
              data-testid="photo-dialog-gallery-input"
            />
          </div>

          {/* Photo counter */}
          <div className="flex flex-col items-center text-xs text-muted-foreground">
            {closeBlocked && (
              <span className="mb-1 text-destructive font-medium">Uploads still running. Please wait before closing.</span>
            )}
            {errorCount > 0 && (
              <span className="mb-1 text-destructive font-medium">{errorCount} photo upload{errorCount !== 1 ? "s" : ""} failed.</span>
            )}
            <div className="flex items-center gap-1.5">
            {photos.map((p) => (
              <span key={p.id}>
                {p.state === "done" && (
                  <Check className="h-3.5 w-3.5 text-green-600 inline" />
                )}
                {(p.state === "compressing" || p.state === "uploading") && (
                  <Loader2 className="h-3.5 w-3.5 text-muted-foreground animate-spin inline" />
                )}
                {p.state === "error" && (
                  <span className="text-destructive font-bold">!</span>
                )}
              </span>
            ))}
            {photos.length > 0 && (
              <span className="ml-1">
                {photos.length} photo{photos.length !== 1 ? "s" : ""}
                {activeCount > 0 && ` (${doneCount} uploaded, ${activeCount} in progress)`}
              </span>
            )}
            </div>
            {photos.length > 0 && (
              <div className="mt-1 max-w-[280px] truncate text-center">
                Latest: {photos[photos.length - 1].name}
              </div>
            )}
          </div>

          <div className="flex items-center gap-2">
            {cameraActive && (
              <Button
                size="sm"
                onClick={handleSnap}
                className="gap-1.5 h-10 sm:h-9"
                disabled={activeCount > 0}
                data-testid="photo-dialog-snap"
              >
                <Camera className="h-4 w-4" />
                Snap
              </Button>
            )}
            <Button
              variant="outline"
              size="sm"
              className="h-10 sm:h-9"
              onClick={handleDone}
              disabled={activeCount > 0}
              data-testid="photo-dialog-done"
            >
              {activeCount > 0 ? "Uploading..." : "Done"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
