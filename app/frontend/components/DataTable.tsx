import { Link } from "@inertiajs/react";

export interface Column<T> {
  header: string;
  align?: "left" | "right";
  render: (row: T) => React.ReactNode;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  rows: T[];
  keyFn: (row: T) => string | number;
  emptyMessage?: string;
}

export default function DataTable<T>({ columns, rows, keyFn, emptyMessage }: DataTableProps<T>) {
  if (rows.length === 0) {
    return <p className="text-muted-foreground">{emptyMessage || "No data."}</p>;
  }

  return (
    <div className="rounded-md border">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b bg-muted/50">
            {columns.map((col, i) => (
              <th
                key={i}
                className={`px-4 py-3 font-medium ${col.align === "right" ? "text-right" : "text-left"}`}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={keyFn(row)} className="border-b last:border-0 hover:bg-muted/30">
              {columns.map((col, i) => (
                <td key={i} className={`px-4 py-3 ${col.align === "right" ? "text-right" : ""}`}>
                  {col.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Helper: a cell that links somewhere
export function LinkCell({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link href={href} className="font-medium text-primary hover:underline">
      {children}
    </Link>
  );
}

// Helper: a muted text cell
export function MutedCell({ children }: { children: React.ReactNode }) {
  return <span className="text-muted-foreground">{children}</span>;
}
