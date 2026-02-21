import FormField from "@/components/FormField";

interface AddressFieldsProps {
  data: { street_address: string; city: string; state: string; zip: string };
  setData: (key: string, value: string) => void;
}

export default function AddressFields({ data, setData }: AddressFieldsProps) {
  return (
    <>
      <FormField
        id="street_address"
        label="Street Address"
        value={data.street_address}
        onChange={(v) => setData("street_address", v)}
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <FormField id="city" label="City" value={data.city} onChange={(v) => setData("city", v)} />
        <FormField id="state" label="State" value={data.state} onChange={(v) => setData("state", v)} />
        <FormField id="zip" label="Zip" value={data.zip} onChange={(v) => setData("zip", v)} />
      </div>
    </>
  );
}
