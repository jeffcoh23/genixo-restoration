export default function StatusBadge({ label }: { label: string }) {
  return (
    <span className="text-xs px-2 py-1 rounded-full bg-muted text-muted-foreground">
      {label}
    </span>
  );
}
