declare module "wx-react-gantt" {
  import { ComponentType, RefObject } from "react";

  interface GanttTask {
    id: string | number;
    text?: string;
    start?: Date;
    end?: Date;
    duration?: number;
    progress?: number;
    type?: "task" | "summary" | "milestone";
    parent?: string | number;
    open?: boolean;
    lazy?: boolean;
    [key: string]: unknown;
  }

  interface GanttLink {
    id: string | number;
    source: string | number;
    target: string | number;
    type?: string;
  }

  interface GanttScale {
    unit: "year" | "quarter" | "month" | "week" | "day" | "hour";
    step: number;
    format?: string;
  }

  interface GanttColumn {
    id: string;
    header?: string;
    width?: number;
    flexgrow?: number;
    align?: "left" | "center" | "right";
  }

  interface GanttApi {
    on: (event: string, callback: (ev: Record<string, unknown>) => void) => void;
    getTask: (id: string | number) => GanttTask | null;
    getState: () => { tasks: GanttTask[] };
    exec: (action: string, params: Record<string, unknown>) => void;
  }

  interface GanttProps {
    tasks?: GanttTask[];
    links?: GanttLink[];
    scales?: GanttScale[];
    columns?: GanttColumn[];
    cellWidth?: number;
    cellHeight?: number;
    scaleHeight?: number;
    readonly?: boolean;
    apiRef?: RefObject<GanttApi | null>;
    ref?: RefObject<GanttApi | null>;
    [key: string]: unknown;
  }

  export const Gantt: ComponentType<GanttProps>;
  export type { GanttTask, GanttLink, GanttScale, GanttColumn, GanttApi, GanttProps };
}

declare module "wx-react-gantt/dist/gantt.css" {}
