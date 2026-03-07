import React from "react";
import { Button } from "@/components/ui/button";

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
}

export default class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <h1 className="text-2xl font-bold text-foreground mb-2">Something went wrong</h1>
          <p className="text-muted-foreground mb-6">An unexpected error occurred while rendering this page.</p>
          <Button onClick={() => window.location.reload()}>
            Reload page
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}
