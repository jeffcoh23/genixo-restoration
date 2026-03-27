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
    [key: string]: any;
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

  interface GanttProps {
    tasks?: GanttTask[];
    links?: GanttLink[];
    scales?: GanttScale[];
    columns?: GanttColumn[];
    cellWidth?: number;
    cellHeight?: number;
    scaleHeight?: number;
    readonly?: boolean;
    apiRef?: RefObject<any>;
    ref?: RefObject<any>;
    [key: string]: any;
  }

  export const Gantt: ComponentType<GanttProps>;
}

declare module "wx-react-gantt/dist/gantt.css" {}
