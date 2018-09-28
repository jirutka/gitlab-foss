# frozen_string_literal: true

module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    false
  end

  def badge_for_auto_devops_scope(auto_devops_receiver)
    return unless auto_devops_receiver.auto_devops_enabled?

    case auto_devops_receiver.first_auto_devops_config[:scope]
    when :project
      nil
    when :group
      s_('CICD|group enabled')
    when :instance
      s_('CICD|instance enabled')
    end
  end
end
