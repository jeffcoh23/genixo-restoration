import { useEffect, useRef, useState } from "react";
import { router } from "@inertiajs/react";
import { Send, Paperclip, FileText, ExternalLink, MessageCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { Message, MessageAttachment } from "../types";

interface MessagePanelProps {
  messages: Message[];
  messages_path: string;
}

export default function MessagePanel({ messages, messages_path }: MessagePanelProps) {
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages.length]);

  const handleSend = () => {
    const trimmed = body.trim();
    if (!trimmed || sending) return;
    setSending(true);
    router.post(messages_path, { message: { body: trimmed } }, {
      preserveScroll: true,
      onSuccess: () => {
        setBody("");
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

  return (
    <div className="flex flex-col h-full">
      <div ref={scrollRef} className="flex-1 overflow-y-auto px-3 py-4">
        {messages.length === 0 ? (
          <EmptyState />
        ) : (
          <MessageThread messages={messages} />
        )}
      </div>

      <div className="border-t border-border bg-background px-3 py-2.5">
        <div className="flex items-end gap-1.5">
          <button
            type="button"
            disabled
            className="shrink-0 p-1.5 text-muted-foreground/30 cursor-not-allowed"
            title="Attachments coming soon"
          >
            <Paperclip className="h-4 w-4" />
          </button>
          <textarea
            ref={textareaRef}
            value={body}
            onChange={handleBodyChange}
            onKeyDown={handleKeyDown}
            placeholder="Type a message..."
            rows={1}
            className="flex-1 resize-none rounded-lg border border-input bg-background px-3 py-2 text-sm leading-snug placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring min-h-[36px] max-h-[120px]"
          />
          <Button
            size="icon"
            onClick={handleSend}
            disabled={!body.trim() || sending}
            className="shrink-0 h-9 w-9 rounded-lg"
          >
            <Send className="h-4 w-4" />
          </Button>
        </div>
        <p className="text-[11px] text-muted-foreground/50 mt-1 text-right">
          Enter to send · Shift+Enter for new line
        </p>
      </div>
    </div>
  );
}

function EmptyState() {
  return (
    <div className="flex flex-col items-center justify-center h-full text-center px-6">
      <div className="h-12 w-12 rounded-full bg-muted/70 flex items-center justify-center mb-3">
        <MessageCircle className="h-6 w-6 text-muted-foreground/50" />
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
      {messages.map((msg, i) => {
        const prev = i > 0 ? messages[i - 1] : null;
        const showDate = !prev || msg.date_label !== prev.date_label;
        const sameSender = prev
          && !showDate
          && prev.is_current_user === msg.is_current_user
          && prev.sender.initials === msg.sender.initials;

        return (
          <div key={msg.id}>
            {showDate && <DateSeparator label={msg.date_label} />}
            {msg.is_current_user ? (
              <OwnMessage message={msg} grouped={!!sameSender} />
            ) : (
              <OtherMessage message={msg} grouped={!!sameSender} />
            )}
          </div>
        );
      })}
    </div>
  );
}

function DateSeparator({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3 py-3">
      <div className="flex-1 border-t border-border/50" />
      <span className="text-[11px] font-medium text-muted-foreground/60 uppercase tracking-wider select-none">
        {label}
      </span>
      <div className="flex-1 border-t border-border/50" />
    </div>
  );
}

function OwnMessage({ message, grouped }: { message: Message; grouped: boolean }) {
  return (
    <div className={`group flex flex-col items-end ${grouped ? "mt-0.5" : "mt-3"}`}>
      {!grouped && (
        <div className="flex items-center gap-2 mb-1 mr-1">
          <span className="text-xs font-medium text-foreground">You</span>
          <span className="text-[11px] text-muted-foreground">{message.timestamp_label}</span>
        </div>
      )}
      <div className="max-w-[85%] rounded-xl bg-[hsl(187_35%_92%)] px-3.5 py-2">
        <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">{message.body}</p>
        <AttachmentList attachments={message.attachments} />
      </div>
      {grouped && (
        <span className="text-[11px] text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity mr-1 mt-0.5 select-none">
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
          <span className="text-[10px] font-semibold text-muted-foreground leading-none">
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
              <span className="text-[11px] text-muted-foreground shrink-0">
                {message.timestamp_label}
              </span>
            </div>
            <span className="text-[11px] text-muted-foreground/70 leading-none">
              {message.sender.role_label} · {message.sender.org_name}
            </span>
          </div>
        )}
        <div className="rounded-xl bg-background border border-border/50 px-3.5 py-2 shadow-[0_1px_2px_hsl(0_0%_0%/0.04)]">
          <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">{message.body}</p>
          <AttachmentList attachments={message.attachments} />
        </div>
        {grouped && (
          <span className="text-[11px] text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity mt-0.5 block select-none">
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
    <div className="flex flex-wrap gap-1.5 mt-2 pt-2 border-t border-border/30">
      {attachments.map((att) => (
        <a
          key={att.id}
          href={att.url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 rounded-md bg-muted/40 hover:bg-muted border border-border/40 hover:border-border px-2 py-0.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          <FileText className="h-3 w-3 shrink-0" />
          <span className="truncate max-w-[120px]">{att.filename}</span>
          <ExternalLink className="h-2.5 w-2.5 shrink-0 opacity-40" />
        </a>
      ))}
    </div>
  );
}
