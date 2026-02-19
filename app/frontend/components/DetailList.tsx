interface DetailListProps {
  children: React.ReactNode;
  emptyMessage?: string;
  isEmpty?: boolean;
}

export default function DetailList({ children, emptyMessage, isEmpty }: DetailListProps) {
  if (isEmpty) {
    return <p className="text-sm text-muted-foreground">{emptyMessage || "None."}</p>;
  }

  return <div className="rounded-lg border shadow-sm divide-y">{children}</div>;
}

export function DetailRow({ children }: { children: React.ReactNode }) {
  return (
    <div className="px-4 py-3 flex items-center justify-between hover:bg-muted/30">
      {children}
    </div>
  );
}
