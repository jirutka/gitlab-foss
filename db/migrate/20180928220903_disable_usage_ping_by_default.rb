# frozen_string_literal: true

class DisableUsagePingByDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :usage_ping_enabled, false
  end

  def down
    change_column_default :application_settings, :usage_ping_enabled, true
  end
end
