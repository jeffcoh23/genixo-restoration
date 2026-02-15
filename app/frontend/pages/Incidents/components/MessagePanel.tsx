import { useEffect, useRef, useState } from "react";
import { router } from "@inertiajs/react";
import { Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { Message } from "../types";

interface MessagePanelProps {
  messages: Message[];
  messages_path: string;
}

export default function MessagePanel({ messages, messages_path }: MessagePanelProps) {
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

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
      onSuccess: () => setBody(""),
      onFinish: () => setSending(false),
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="flex flex-col h-full">
      {/* Scrollable thread */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto px-4 py-3">
        {messages.length === 0 ? (
          <div className="flex items-center justify-center h-full text-muted-foreground text-sm">
            No messages yet. Start the conversation.
          </div>
        ) : (
          <MessageThread messages={messages} />
        )}
      </div>

      {/* Compose area */}
      <div className="border-t border-border px-4 py-3">
        <div className="flex gap-2">
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Type a message..."
            rows={1}
            className="flex-1 resize-none rounded-md border border-input bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          />
          <Button
            size="sm"
            onClick={handleSend}
            disabled={!body.trim() || sending}
            className="self-end"
          >
            <Send className="h-4 w-4" />
          </Button>
        </div>
        <p className="text-[11px] text-muted-foreground mt-1">
          Enter to send, Shift+Enter for new line
        </p>
      </div>
    </div>
  );
}

function MessageThread({ messages }: { messages: Message[] }) {
  let lastDateLabel = "";

  return (
    <div className="space-y-4">
      {messages.map((msg) => {
        const showDate = msg.date_label !== lastDateLabel;
        lastDateLabel = msg.date_label;

        return (
          <div key={msg.id}>
            {showDate && (
              <div className="flex items-center gap-3 my-4 first:mt-0">
                <div className="flex-1 border-t border-border" />
                <span className="text-xs text-muted-foreground">{msg.date_label}</span>
                <div className="flex-1 border-t border-border" />
              </div>
            )}
            <MessageBubble message={msg} />
          </div>
        );
      })}
    </div>
  );
}

function MessageBubble({ message }: { message: Message }) {
  return (
    <div className="flex gap-2.5 group">
      <div className="h-7 w-7 shrink-0 rounded-full bg-muted flex items-center justify-center text-[10px] font-medium text-muted-foreground mt-0.5">
        {message.sender.initials}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline gap-2">
          <span className="text-sm font-medium text-foreground">
            {message.is_current_user ? "You" : message.sender.full_name}
          </span>
          <span className="text-xs text-muted-foreground">
            {message.sender.role_label} &middot; {message.sender.org_name}
          </span>
          <span className="text-[11px] text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity ml-auto">
            {message.timestamp_label}
          </span>
        </div>
        <p className="text-sm text-foreground whitespace-pre-wrap mt-0.5">{message.body}</p>
      </div>
    </div>
  );
}
