module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    false
  end

  def auto_devops_warning_message(project)
    missing_domain = !project.auto_devops&.has_domain?
    missing_service = !project.deployment_platform&.active?

    if missing_service
      params = {
        kubernetes: link_to('Kubernetes service', edit_project_service_path(project, 'kubernetes'))
      }

      if missing_domain
        _('Auto Review Apps and Auto Deploy need a domain name and the %{kubernetes} to work correctly.') % params
      else
        _('Auto Review Apps and Auto Deploy need the %{kubernetes} to work correctly.') % params
      end
    elsif missing_domain
      _('Auto Review Apps and Auto Deploy need a domain name to work correctly.')
    end
  end
end
