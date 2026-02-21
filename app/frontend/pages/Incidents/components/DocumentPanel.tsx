import { useMemo, useState } from "react";
import { FileText, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { IncidentAttachment } from "../types";
import AttachmentForm from "./AttachmentForm";

const PAGE_SIZE = 30;
const CATEGORY_ORDER = [ "moisture_mapping", "moisture_readings", "psychrometric_log", "signed_document", "sign_in_sheet", "general" ];

interface DocumentPanelProps {
  attachments: IncidentAttachment[];
  attachments_path: string;
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  const kb = bytes / 1024;
  if (kb < 1024) return `${kb.toFixed(1)} KB`;
  return `${(kb / 1024).toFixed(1)} MB`;
}

export default function DocumentPanel({ attachments, attachments_path }: DocumentPanelProps) {
  const [showUploadForm, setShowUploadForm] = useState(false);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("all");
  const [uploader, setUploader] = useState("all");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const categoryRank = useMemo(
    () => Object.fromEntries(CATEGORY_ORDER.map((category, index) => [ category, index ])),
    []
  );

  const documents = useMemo(
    () => attachments
      .filter((attachment) => attachment.category !== "photo")
      .sort((a, b) => {
        const rankA = categoryRank[a.category] ?? 999;
        const rankB = categoryRank[b.category] ?? 999;
        if (rankA !== rankB) return rankA - rankB;
        return b.created_at.localeCompare(a.created_at);
      }),
    [attachments, categoryRank]
  );

  const categoryOptions = useMemo(
    () =>
      [ ...new Map(documents.map((doc) => [ doc.category, doc.category_label ])).entries() ]
        .map(([value, label]) => ({ value, label }))
        .sort((a, b) => a.label.localeCompare(b.label)),
    [documents]
  );

  const uploaderOptions = useMemo(
    () => [ ...new Set(documents.map((doc) => doc.uploaded_by_name)) ].sort((a, b) => a.localeCompare(b)),
    [documents]
  );

  const filteredDocuments = useMemo(() => {
    const term = search.trim().toLowerCase();
    return documents.filter((doc) => {
      if (term) {
        const haystack = [ doc.filename, doc.description || "", doc.uploaded_by_name ].join(" ").toLowerCase();
        if (!haystack.includes(term)) return false;
      }
      if (category !== "all" && doc.category !== category) return false;
      if (uploader !== "all" && doc.uploaded_by_name !== uploader) return false;
      const docDate = doc.log_date || doc.created_at.slice(0, 10);
      if (fromDate && docDate < fromDate) return false;
      if (toDate && docDate > toDate) return false;
      return true;
    });
  }, [documents, search, category, uploader, fromDate, toDate]);

  const visibleDocuments = filteredDocuments.slice(0, visibleCount);
  const hasMore = visibleCount < filteredDocuments.length;
  const groupedVisibleDocuments = useMemo(() => {
    const groups: { category: string; categoryLabel: string; items: IncidentAttachment[] }[] = [];
    for (const doc of visibleDocuments) {
      const last = groups[groups.length - 1];
      if (last && last.category === doc.category) {
        last.items.push(doc);
      } else {
        groups.push({ category: doc.category, categoryLabel: doc.category_label, items: [ doc ] });
      }
    }
    return groups;
  }, [visibleDocuments]);

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center justify-between gap-2 p-3 border-b border-border bg-muted/15 shrink-0">
        <p className="text-xs text-muted-foreground">
          {filteredDocuments.length} of {documents.length} documents · grouped by type · batch size {PAGE_SIZE}
        </p>
        <Button
          variant="outline"
          size="sm"
          className="h-10 sm:h-8 text-sm sm:text-xs gap-1"
          onClick={() => setShowUploadForm(true)}
        >
          <Upload className="h-3 w-3" />
          Upload Document
        </Button>
      </div>

      <div className="border-b border-border bg-card/60 p-3 shrink-0">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-2">
          <Input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setVisibleCount(PAGE_SIZE);
            }}
            placeholder="Search documents..."
            className="h-9 text-sm md:col-span-2"
          />
          <select
            value={category}
            onChange={(e) => {
              setCategory(e.target.value);
              setVisibleCount(PAGE_SIZE);
            }}
            className="h-9 rounded-md border border-input bg-background px-3 text-sm"
          >
            <option value="all">All categories</option>
            {categoryOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
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
          <div className="grid grid-cols-2 gap-2">
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
      </div>

      <div className="flex-1 overflow-y-auto p-4 pb-10">
        {filteredDocuments.length === 0 ? (
          <div className="rounded-lg border border-dashed border-border bg-muted/10 p-6 text-center text-sm text-muted-foreground">
            No documents match the current filters.
          </div>
        ) : (
          <>
            <div className="space-y-4">
              {groupedVisibleDocuments.map((group) => (
                <section key={group.category} className="space-y-2">
                  <div className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                    {group.categoryLabel} ({group.items.length})
                  </div>
                  {group.items.map((doc) => (
                    <a
                      key={doc.id}
                      href={doc.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-start gap-3 rounded-lg border border-border bg-card p-3 hover:border-primary transition-colors"
                    >
                      <div className="h-9 w-9 rounded-md bg-muted flex items-center justify-center shrink-0">
                        <FileText className="h-4 w-4 text-muted-foreground" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-medium text-foreground truncate">{doc.filename}</p>
                        {doc.description && (
                          <p className="text-xs text-muted-foreground mt-0.5">{doc.description}</p>
                        )}
                        <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted-foreground">
                          <span>{doc.log_date_label || doc.created_at_label}</span>
                          <span>&middot;</span>
                          <span>{doc.uploaded_by_name}</span>
                          <span>&middot;</span>
                          <span>{formatBytes(doc.byte_size)}</span>
                        </div>
                      </div>
                    </a>
                  ))}
                </section>
              ))}
            </div>

            <div className="mt-4 flex items-center justify-between">
              <p className="text-xs text-muted-foreground">
                Showing {visibleDocuments.length} of {filteredDocuments.length}
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

      {showUploadForm && (
        <AttachmentForm
          path={attachments_path}
          onClose={() => setShowUploadForm(false)}
        />
      )}
    </div>
  );
}
