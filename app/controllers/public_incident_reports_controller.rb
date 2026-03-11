class PublicIncidentReportsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    mit_org = Organization.find_by(organization_type: "mitigation")

    render inertia: "PublicIncidentReport", props: {
      project_types: Incident::PROJECT_TYPES.map { |v| { value: v, label: Incident::PROJECT_TYPE_LABELS[v] } },
      damage_types: Incident::DAMAGE_TYPES.map { |v| { value: v, label: Incident::DAMAGE_LABELS[v] } },
      emergency_phone: format_phone(mit_org&.phone),
      submit_path: public_incident_reports_path
    }
  end

  def create
    service = PublicIncidentReportService.new(report_params)

    if service.call
      redirect_to new_public_incident_report_path,
        notice: "Your report has been submitted. Someone will be in touch shortly."
    else
      redirect_to new_public_incident_report_path,
        inertia: { errors: service.errors }
    end
  end

  private

  def report_params
    params.permit(
      :reporter_email, :reporter_name, :reporter_phone,
      :property_description, :project_type, :damage_type,
      :description, :emergency
    )
  end
end
