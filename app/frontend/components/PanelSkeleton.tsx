export default function PanelSkeleton() {
  return (
    <div className="flex-1 p-6 space-y-4 animate-pulse">
      <div className="h-4 bg-muted rounded w-2/3" />
      <div className="h-4 bg-muted rounded w-1/2" />
      <div className="h-4 bg-muted rounded w-3/4" />
      <div className="h-4 bg-muted rounded w-1/3" />
      <div className="h-4 bg-muted rounded w-2/3" />
    </div>
  );
}
