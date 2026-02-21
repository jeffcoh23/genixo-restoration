import { useEffect, useRef, useState } from "react";
import { router } from "@inertiajs/react";
import { Send, Paperclip, FileText, ExternalLink, MessageCircle, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import type { Message, MessageAttachment } from "../types";

interface MessagePanelProps {
  messages: Message[];
  messages_path: string;
}

export default function MessagePanel({ messages, messages_path }: MessagePanelProps) {
  const [body, setBody] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const [sending, setSending] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages.length]);

  const hasContent = body.trim().length > 0 || files.length > 0;

  const handleSend = () => {
    if (!hasContent || sending) return;
    setSending(true);

    router.post(messages_path, { message: { body: body.trim(), files } }, {
      forceFormData: files.length > 0,
      preserveScroll: true,
      onSuccess: () => {
        setBody("");
        setFiles([]);
        if (textareaRef.current) textareaRef.current.style.height = "auto";
      },
      onFinish: () => setSending(false),
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleBodyChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setBody(e.target.value);
    const ta = e.target;
    ta.style.height = "auto";
    ta.style.height = Math.min(ta.scrollHeight, 120) + "px";
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles((prev) => [...prev, ...Array.from(e.target.files!)]);
    }
    e.target.value = "";
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="flex flex-col h-full">
      <div ref={scrollRef} className="flex-1 overflow-y-auto px-3 py-4 pb-8">
        {messages.length === 0 ? (
          <EmptyState />
        ) : (
          <MessageThread messages={messages} />
        )}
      </div>

      <div className="border-t border-border bg-background px-3 py-2.5">
        {files.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-2">
            {files.map((file, i) => (
              <span key={i} className="inline-flex items-center gap-1 rounded bg-muted border border-border px-2 py-0.5 text-xs">
                <FileText className="h-3 w-3 shrink-0" />
                <span className="truncate max-w-[120px]">{file.name}</span>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-4 w-4 p-0 hover:text-destructive"
                  onClick={() => removeFile(i)}
                >
                  <X className="h-3 w-3" />
                </Button>
              </span>
            ))}
          </div>
        )}
        <div className="flex items-end gap-1.5">
          <Input
            ref={fileInputRef}
            type="file"
            multiple
            className="hidden"
            onChange={handleFileSelect}
          />
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="shrink-0 h-9 w-9"
            onClick={() => fileInputRef.current?.click()}
          >
            <Paperclip className="h-4 w-4" />
          </Button>
          <Textarea
            ref={textareaRef}
            value={body}
            onChange={handleBodyChange}
            onKeyDown={handleKeyDown}
            placeholder="Type a message..."
            rows={1}
            className="flex-1 resize-none min-h-9 max-h-[120px] leading-snug"
          />
          <Button
            size="icon"
            onClick={handleSend}
            disabled={!hasContent || sending}
            className="shrink-0 h-9 w-9"
          >
            <Send className="h-4 w-4" />
          </Button>
        </div>
        <p className="text-xs text-muted-foreground mt-1 text-right">
          Enter to send · Shift+Enter for new line
        </p>
      </div>
    </div>
  );
}

function EmptyState() {
  return (
    <div className="flex flex-col items-center justify-center h-full text-center px-6">
      <div className="h-12 w-12 rounded-full bg-muted flex items-center justify-center mb-3">
        <MessageCircle className="h-6 w-6 text-muted-foreground" />
      </div>
      <p className="text-sm font-medium text-foreground">No messages yet</p>
      <p className="text-xs text-muted-foreground mt-1 max-w-[220px]">
        Start the conversation — everyone assigned to this incident will see your messages.
      </p>
    </div>
  );
}

function MessageThread({ messages }: { messages: Message[] }) {
  return (
    <div>
      {messages.map((msg) => (
        <div key={msg.id}>
          {msg.show_date_separator && <DateSeparator label={msg.date_label} />}
          {msg.is_current_user ? (
            <OwnMessage message={msg} grouped={msg.grouped} />
          ) : (
            <OtherMessage message={msg} grouped={msg.grouped} />
          )}
        </div>
      ))}
    </div>
  );
}

function DateSeparator({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3 py-3">
      <div className="flex-1 border-t border-border" />
      <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider select-none">
        {label}
      </span>
      <div className="flex-1 border-t border-border" />
    </div>
  );
}

function OwnMessage({ message, grouped }: { message: Message; grouped: boolean }) {
  return (
    <div className={`group flex flex-col items-end ${grouped ? "mt-0.5" : "mt-3"}`}>
      {!grouped && (
        <div className="flex items-center gap-2 mb-1 mr-1">
          <span className="text-xs font-medium text-foreground">You</span>
          <span className="text-xs text-muted-foreground">{message.timestamp_label}</span>
        </div>
      )}
      <div className="max-w-[85%] rounded bg-accent px-3.5 py-2">
        <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">{message.body}</p>
        <AttachmentList attachments={message.attachments} />
      </div>
      {grouped && (
        <span className="text-xs text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity mr-1 mt-0.5 select-none">
          {message.timestamp_label}
        </span>
      )}
    </div>
  );
}

function OtherMessage({ message, grouped }: { message: Message; grouped: boolean }) {
  return (
    <div className={`group flex items-start gap-2 ${grouped ? "mt-0.5 pl-9" : "mt-3"}`}>
      {!grouped && (
        <div className="h-7 w-7 shrink-0 rounded-full bg-muted flex items-center justify-center">
          <span className="text-xs font-semibold text-muted-foreground leading-none">
            {message.sender.initials}
          </span>
        </div>
      )}
      <div className="max-w-[85%] min-w-0">
        {!grouped && (
          <div className="mb-1">
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium text-foreground truncate">
                {message.sender.full_name}
              </span>
              <span className="text-xs text-muted-foreground shrink-0">
                {message.timestamp_label}
              </span>
            </div>
            <span className="text-xs text-muted-foreground leading-none">
              {message.sender.role_label} · {message.sender.org_name}
            </span>
          </div>
        )}
        <div className="rounded bg-background border border-border px-3.5 py-2 shadow-sm">
          <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">{message.body}</p>
          <AttachmentList attachments={message.attachments} />
        </div>
        {grouped && (
          <span className="text-xs text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity mt-0.5 block select-none">
            {message.timestamp_label}
          </span>
        )}
      </div>
    </div>
  );
}

function AttachmentList({ attachments }: { attachments?: MessageAttachment[] }) {
  if (!attachments || attachments.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-1.5 mt-2 pt-2 border-t border-border">
      {attachments.map((att) => (
        <a
          key={att.id}
          href={att.url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 rounded bg-muted hover:bg-accent border border-border px-2 py-0.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          <FileText className="h-3 w-3 shrink-0" />
          <span className="truncate max-w-[120px]">{att.filename}</span>
          <ExternalLink className="h-3 w-3 shrink-0" />
        </a>
      ))}
    </div>
  );
}
