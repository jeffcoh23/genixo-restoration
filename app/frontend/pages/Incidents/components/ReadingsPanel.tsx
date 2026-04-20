import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import MoisturePanel from "./MoisturePanel";
import PsychrometricPanel from "./PsychrometricPanel";
import type { MoistureData, PsychrometricData } from "../types";

export type ReadingsView = "moisture" | "psychrometric";

interface ReadingsPanelProps {
  moisture_data: MoistureData;
  psychrometric_data: PsychrometricData;
  can_manage_moisture: boolean;
  can_manage_psychrometric: boolean;
  view: ReadingsView;
  onViewChange: (view: ReadingsView) => void;
}

export default function ReadingsPanel({
  moisture_data,
  psychrometric_data,
  can_manage_moisture,
  can_manage_psychrometric,
  view,
  onViewChange,
}: ReadingsPanelProps) {
  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center px-4 py-3 shrink-0">
        <Tabs value={view} onValueChange={(v) => onViewChange(v as ReadingsView)}>
          <TabsList>
            <TabsTrigger value="moisture">Moisture</TabsTrigger>
            <TabsTrigger value="psychrometric">Psychrometric</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      <div className="flex-1 overflow-hidden">
        <div className={view === "moisture" ? "h-full" : "hidden"}>
          <MoisturePanel
            moisture_data={moisture_data}
            can_manage_moisture={can_manage_moisture}
          />
        </div>
        <div className={view === "psychrometric" ? "h-full" : "hidden"}>
          <PsychrometricPanel
            psychrometric_data={psychrometric_data}
            can_manage_psychrometric={can_manage_psychrometric}
          />
        </div>
      </div>
    </div>
  );
}
