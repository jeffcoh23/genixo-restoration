declare module "@svar-ui/react-gantt" {
  import { ComponentType, RefObject } from "react";

  interface GanttProps {
    tasks?: Record<string, unknown>[];
    links?: Record<string, unknown>[];
    scales?: { unit: string; step: number; format?: string }[];
    columns?: {
      id: string;
      header?: string;
      width?: number;
      flexgrow?: number;
      align?: string;
      getter?: (task: Record<string, unknown>) => unknown;
      template?: (task: Record<string, unknown>) => string;
    }[];
    cellWidth?: number;
    cellHeight?: number;
    scaleHeight?: number;
    readonly?: boolean;
    apiRef?: RefObject<unknown>;
    [key: string]: unknown;
  }

  export const Gantt: ComponentType<GanttProps>;
}

declare module "@svar-ui/react-gantt/style.css" {}
declare module "@svar-ui/react-gantt/all.css" {}
