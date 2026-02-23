module PlannedSystemTestSupport
  private

  def pending_e2e(id, note = nil)
    suffix = note.present? ? ": #{note}" : ""
    skip "Planned E2E coverage from docs/TESTING.md (#{id})#{suffix}"
  end
end
