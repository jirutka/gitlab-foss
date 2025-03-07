# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupAccessTokenEntity do
  let_it_be(:group) { create(:group) }
  let_it_be(:bot) { create(:user, :project_bot) }
  let_it_be(:token) { create(:personal_access_token, user: bot) }

  subject(:json) {  described_class.new(token, group: group).as_json }

  context 'when bot is a member of the group' do
    before do
      group.add_developer(bot)
    end

    it 'has the correct attributes' do
      expected_revoke_path = Gitlab::Routing.url_helpers
                                            .revoke_group_settings_access_token_path(
                                              { id: token,
                                                group_id: group.path })

      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          access_level: ::Gitlab::Access::DEVELOPER
        ))

      expect(json).not_to include(:token)
    end
  end

  context 'when bot is unrelated to the group' do
    it 'has the correct attributes' do
      expected_revoke_path = Gitlab::Routing.url_helpers
                                            .revoke_group_settings_access_token_path(
                                              { id: token,
                                                group_id: group.path })

      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          access_level: nil
        ))

      expect(json).not_to include(:token)
    end
  end
end
