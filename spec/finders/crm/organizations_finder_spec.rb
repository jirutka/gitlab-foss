# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crm::OrganizationsFinder do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(user, group: group).execute }

    context 'when customer relations feature is enabled for the group' do
      let_it_be(:root_group) { create(:group, :crm_enabled) }
      let_it_be(:group) { create(:group, parent: root_group) }

      let_it_be(:organization_1) { create(:organization, group: root_group) }
      let_it_be(:organization_2) { create(:organization, group: root_group) }

      context 'when user does not have permissions to see organizations in the group' do
        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when user is member of the root group' do
        before do
          root_group.add_developer(user)
        end

        context 'when feature flag is enabled' do
          it 'returns all group organizations' do
            expect(subject).to match_array([organization_1, organization_2])
          end
        end
      end

      context 'when user is member of the sub group' do
        before do
          group.add_developer(user)
        end

        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when customer relations feature is disabled for the group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:organization) { create(:organization, group: group) }

      before do
        group.add_developer(user)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'with search informations' do
      let_it_be(:search_test_group) { create(:group, :crm_enabled) }

      let_it_be(:search_test_a) do
        create(
          :organization,
          group: search_test_group,
          name: "DEF",
          description: "ghi_st",
          state: "inactive"
        )
      end

      let_it_be(:search_test_b) do
        create(
          :organization,
          group: search_test_group,
          name: "ABC_st",
          description: "JKL",
          state: "active"
        )
      end

      before do
        search_test_group.add_developer(user)
      end

      context 'when search term is empty' do
        it 'returns all group organizations alphabetically ordered' do
          finder = described_class.new(user, group: search_test_group, search: "")
          expect(finder.execute).to eq([search_test_b, search_test_a])
        end
      end

      context 'when search term is not empty' do
        it 'searches for name' do
          finder = described_class.new(user, group: search_test_group, search: "aBc")
          expect(finder.execute).to match_array([search_test_b])
        end

        it 'searches for description' do
          finder = described_class.new(user, group: search_test_group, search: "ghI")
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'searches for name and description' do
          finder = described_class.new(user, group: search_test_group, search: "_st")
          expect(finder.execute).to eq([search_test_b, search_test_a])
        end
      end

      context 'when searching for organizations state' do
        it 'returns only inactive organizations' do
          finder = described_class.new(user, group: search_test_group, state: :inactive)
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'returns only active organizations' do
          finder = described_class.new(user, group: search_test_group, state: :active)
          expect(finder.execute).to match_array([search_test_b])
        end
      end

      context 'when searching for organizations ids' do
        it 'returns the expected organizations' do
          finder = described_class.new(user, group: search_test_group, ids: [search_test_a.id])

          expect(finder.execute).to match_array([search_test_a])
        end
      end
    end
  end
end
