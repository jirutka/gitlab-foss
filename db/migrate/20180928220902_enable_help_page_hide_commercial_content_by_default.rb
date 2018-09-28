# frozen_string_literal: true

class EnableHelpPageHideCommercialContentByDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :help_page_hide_commercial_content, true
  end

  def down
    change_column_default :application_settings, :help_page_hide_commercial_content, false
  end
end
