# frozen_string_literal: true

class EnableHideThirdPartyOffersByDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :hide_third_party_offers, true
  end

  def down
    change_column_default :application_settings, :hide_third_party_offers, false
  end
end
