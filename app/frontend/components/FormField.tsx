import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface FormFieldProps {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  type?: string;
  required?: boolean;
  hint?: string;
}

export default function FormField({ id, label, value, onChange, error, type = "text", required, hint }: FormFieldProps) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>
        {label}{required && " *"}
        {hint && <span className="text-muted-foreground text-xs ml-1">({hint})</span>}
      </Label>
      <Input
        id={id}
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
      {error && <p className="text-sm text-destructive">{error}</p>}
    </div>
  );
}
