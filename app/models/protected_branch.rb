# frozen_string_literal: true

class ProtectedBranch < ApplicationRecord
  include ProtectedRef
  include Gitlab::SQL::Pattern

  scope :requiring_code_owner_approval,
        -> { where(code_owner_approval_required: true) }

  scope :allowing_force_push,
        -> { where(allow_force_push: true) }

  scope :get_ids_by_name, -> (name) { where(name: name).pluck(:id) }

  protected_ref_access_levels :merge, :push

  def self.protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
    # Maintainers, owners and admins are allowed to create the default branch

    if project.empty_repo? && project.default_branch_protected?
      return true if user.admin? || project.team.max_member_access(user.id) > Gitlab::Access::DEVELOPER
    end

    super
  end

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name, dry_run: true)
    return true if project.empty_repo? && project.default_branch_protected?
    return false if ref_name.blank?

    new_cache_result = new_cache(project, ref_name, dry_run: dry_run)

    return new_cache_result unless new_cache_result.nil?

    deprecated_cache(project, ref_name)
  end

  def self.new_cache(project, ref_name, dry_run: true)
    if Feature.enabled?(:hash_based_cache_for_protected_branches, project)
      ProtectedBranches::CacheService.new(project).fetch(ref_name, dry_run: dry_run) do # rubocop: disable CodeReuse/ServiceClass
        self.matching(ref_name, protected_refs: protected_refs(project)).present?
      end
    end
  end

  # Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/368279
  # ----------------------------------------------------------------
  CACHE_EXPIRE_IN = 1.hour

  def self.deprecated_cache(project, ref_name)
    Rails.cache.fetch(protected_ref_cache_key(project, ref_name), expires_in: CACHE_EXPIRE_IN) do
      self.matching(ref_name, protected_refs: protected_refs(project)).present?
    end
  end

  def self.protected_ref_cache_key(project, ref_name)
    "protected_ref-#{project.cache_key}-#{Digest::SHA1.hexdigest(ref_name)}"
  end
  # End of deprecation --------------------------------------------

  def self.allow_force_push?(project, ref_name)
    project.protected_branches.allowing_force_push.matching(ref_name).any?
  end

  def self.any_protected?(project, ref_names)
    protected_refs(project).any? do |protected_ref|
      ref_names.any? do |ref_name|
        protected_ref.matches?(ref_name)
      end
    end
  end

  def self.protected_refs(project)
    project.protected_branches
  end

  # overridden in EE
  def self.branch_requires_code_owner_approval?(project, branch_name)
    false
  end

  def self.by_name(query)
    return none if query.blank?

    where(fuzzy_arel_match(:name, query.downcase))
  end

  def allow_multiple?(type)
    type == :push
  end

  def self.downcase_humanized_name
    name.underscore.humanize.downcase
  end
end

ProtectedBranch.prepend_mod_with('ProtectedBranch')
