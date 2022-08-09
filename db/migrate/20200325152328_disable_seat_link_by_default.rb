# frozen_string_literal: true

class DisableSeatLinkByDefault < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column_default :application_settings, :seat_link_enabled, false
  end

  def down
    change_column_default :application_settings, :seat_link_enabled, true
  end
end
