# frozen_string_literal: true

# Change from "All tiers" to "Current tier only".
class UpdateApplicationSettingsWhatsNewDefault < ActiveRecord::Migration[6.0]
  def up
    change_column :application_settings, :whats_new_variant, :integer, limit: 2, default: 1
  end

  def down
    change_column :application_settings, :whats_new_variant, :integer, limit: 2, default: 0
  end
end
