namespace :equipment do
  desc "Load real equipment inventory for Genixo org (idempotent — safe to re-run)"
  task load_inventory: :environment do
    org = Organization.find_by!(organization_type: "mitigation")

    # Ensure equipment types exist (deactivate old ones no longer in use)
    current_type_names = [ "Dehumidifier", "Air Mover", "Air Scrubber", "Extractor" ]
    types = {}
    current_type_names.each do |name|
      types[name] = EquipmentType.find_or_create_by!(organization: org, name: name) do |et|
        et.active = true
      end
      types[name].update!(active: true) unless types[name].active?
    end

    # Remove old types not in the real inventory
    EquipmentType.where(organization: org).where.not(name: current_type_names).find_each do |et|
      et.equipment_items.destroy_all
      et.equipment_entries.destroy_all
      et.destroy
      puts "  Removed old type: #{et.name}"
    end

    inventory = [
      # Dehumidifiers
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2284", tag: "1000" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2288", tag: "1001" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2443", tag: "1002" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2286", tag: "1003" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2291", tag: "1004" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2289", tag: "1005" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2287", tag: "1006" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2290", tag: "1007" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2440", tag: "1008" },
      { category: "Dehumidifier", make_model: "Drieaz LGR 5000 LI-127690", serial: "2249", tag: "1009" },

      # Air Movers — Aramsco Syclone
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108447", tag: "1010" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107762", tag: "1011" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108377", tag: "1012" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108369", tag: "1013" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108381", tag: "1014" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108435", tag: "1015" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108446", tag: "1016" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108376", tag: "1017" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108372", tag: "1018" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108375", tag: "1019" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108382", tag: "1020" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108437", tag: "1021" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108439", tag: "1022" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108444", tag: "1023" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108374", tag: "1024" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108442", tag: "1025" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108434", tag: "1026" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107763", tag: "1027" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107775", tag: "1028" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108383", tag: "1029" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108436", tag: "1030" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108378", tag: "1031" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108445", tag: "1032" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108368", tag: "1033" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107767", tag: "1034" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108380", tag: "1035" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107770", tag: "1036" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108370", tag: "1037" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108438", tag: "1038" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107774", tag: "1039" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108443", tag: "1040" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107766", tag: "1041" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108432", tag: "1042" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108379", tag: "1043" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108433", tag: "1044" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108441", tag: "1045" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "107771", tag: "1046" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108373", tag: "1047" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108371", tag: "1048" },
      { category: "Air Mover", make_model: "Aramsco Syclone CFM-1000-ARM-BLUE", serial: "108440", tag: "1049" },

      # Air Movers — B-Air Ventlo 25
      { category: "Air Mover", make_model: "B-Air Ventlo 25", serial: "VTLO-AB24045", tag: "1050" },
      { category: "Air Mover", make_model: "B-Air Ventlo 25", serial: "VTLO-AB24048", tag: "1051" },
      { category: "Air Mover", make_model: "B-Air Ventlo 25", serial: "VTLO-AB24104", tag: "1052" },
      { category: "Air Mover", make_model: "B-Air Ventlo 25", serial: "VTLO-AB25052", tag: "1053" },

      # Air Movers — Drieaz Stealth
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16979", tag: "1054" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16940", tag: "1056" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16916", tag: "1058" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16999", tag: "1059" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16980", tag: "1060" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16998", tag: "1061" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16941", tag: "1062" },
      { category: "Air Mover", make_model: "Drieaz Stealth AV3000-113164", serial: "16977", tag: "1063" },

      # Air Scrubbers (only ones with serial/tag numbers)
      { category: "Air Scrubber", make_model: "Drieaz HEPA 700-125105", serial: "40932", tag: "1064" },
      { category: "Air Scrubber", make_model: "Drieaz HEPA 700-125105", serial: "40807", tag: "1065" },

      # Extractor
      { category: "Extractor", make_model: "Kleenrite Mega3 Model 36303", serial: "13899", tag: "1066" }
    ]

    created = 0
    updated = 0

    inventory.each do |item|
      et = types[item[:category]]
      ei = EquipmentItem.find_or_initialize_by(organization: org, identifier: item[:serial])
      was_new = ei.new_record?
      ei.assign_attributes(
        equipment_type: et,
        equipment_model: item[:make_model],
        tag_number: item[:tag],
        active: true
      )
      ei.save!
      was_new ? created += 1 : updated += 1
    end

    # Remove old items not in the real inventory
    real_serials = inventory.map { |i| i[:serial] }
    old_items = EquipmentItem.where(organization: org).where.not(identifier: real_serials)
    removed = old_items.count
    old_items.destroy_all

    puts "Equipment inventory loaded for #{org.name}:"
    puts "  Types: #{types.values.map(&:name).join(', ')}"
    puts "  Created: #{created}"
    puts "  Updated: #{updated}"
    puts "  Removed old items: #{removed}"
    puts "  Total items: #{EquipmentItem.where(organization: org).count}"
  end
end
