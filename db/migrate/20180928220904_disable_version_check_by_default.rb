# frozen_string_literal: true

class DisableVersionCheckByDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :version_check_enabled, false
  end

  def down
    change_column_default :application_settings, :version_check_enabled, true
  end
end
