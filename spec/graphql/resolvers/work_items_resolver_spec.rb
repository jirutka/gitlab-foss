# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItemsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let_it_be(:group)         { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  let_it_be(:item1) do
    create(:work_item, project: project, state: :opened, created_at:
           3.hours.ago, updated_at: 3.hours.ago)
  end

  let_it_be(:item2) do
    create(:work_item, project: project, state: :closed, title: 'foo',
           created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at:
           1.hour.ago)
  end

  let_it_be(:item3) do
    create(:work_item, project: other_project, state: :closed, title: 'foo',
           created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at:
           1.hour.ago)
  end

  let_it_be(:item4) { create(:work_item) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WorkItemType.connection_type)
  end

  context "with a project" do
    before_all do
      project.add_developer(current_user)
      project.add_reporter(reporter)
    end

    describe '#resolve' do
      it 'finds all items' do
        expect(resolve_items).to contain_exactly(item1, item2)
      end

      it 'filters by state' do
        expect(resolve_items(state: 'opened')).to contain_exactly(item1)
        expect(resolve_items(state: 'closed')).to contain_exactly(item2)
      end

      context 'when searching items' do
        it 'returns correct items' do
          expect(resolve_items(search: 'foo')).to contain_exactly(item2)
        end

        it 'uses project search optimization' do
          expected_arguments = a_hash_including(
            search: 'foo',
            attempt_project_search_optimizations: true
          )
          expect(::WorkItems::WorkItemsFinder).to receive(:new).with(anything, expected_arguments).and_call_original

          resolve_items(search: 'foo')
        end

        context 'with anonymous user' do
          let_it_be(:public_project) { create(:project, :public) }
          let_it_be(:public_item) { create(:work_item, project: public_project, title: 'Test item') }

          context 'with disable_anonymous_search enabled' do
            before do
              stub_feature_flags(disable_anonymous_search: true)
            end

            it 'generates an error' do
              error_message = "User must be authenticated to include the `search` argument."

              expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) do
                resolve(described_class, obj: public_project, args: { search: 'test' }, ctx: { current_user: nil })
              end
            end
          end

          context 'with disable_anonymous_search disabled' do
            before do
              stub_feature_flags(disable_anonymous_search: false)
            end

            it 'returns correct items' do
              expect(
                resolve(described_class, obj: public_project, args: { search: 'test' }, ctx: { current_user: nil })
              ).to contain_exactly(public_item)
            end
          end
        end
      end

      describe 'sorting' do
        context 'when sorting by created' do
          it 'sorts items ascending' do
            expect(resolve_items(sort: 'created_asc').to_a).to eq [item1, item2]
          end

          it 'sorts items descending' do
            expect(resolve_items(sort: 'created_desc').to_a).to eq [item2, item1]
          end
        end

        context 'when sorting by title' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:item1) { create(:work_item, project: project, title: 'foo') }
          let_it_be(:item2) { create(:work_item, project: project, title: 'bar') }
          let_it_be(:item3) { create(:work_item, project: project, title: 'baz') }
          let_it_be(:item4) { create(:work_item, project: project, title: 'Baz 2') }

          it 'sorts items ascending' do
            expect(resolve_items(sort: :title_asc).to_a).to eq [item2, item3, item4, item1]
          end

          it 'sorts items descending' do
            expect(resolve_items(sort: :title_desc).to_a).to eq [item1, item4, item3, item2]
          end
        end
      end

      it 'returns items user can see' do
        project.add_guest(current_user)

        create(:work_item, confidential: true)

        expect(resolve_items).to contain_exactly(item1, item2)
      end

      it 'batches queries that only include IIDs', :request_store do
        result = batch_sync(max_queries: 7) do
          [item1, item2]
            .map { |item| resolve_items(iid: item.iid.to_s) }
            .flat_map(&:to_a)
        end

        expect(result).to contain_exactly(item1, item2)
      end

      it 'finds a specific item with iids', :request_store do
        result = batch_sync(max_queries: 7) do
          resolve_items(iids: [item1.iid]).to_a
        end

        expect(result).to contain_exactly(item1)
      end

      it 'finds multiple items with iids' do
        create(:work_item, project: project, author: current_user)

        expect(batch_sync { resolve_items(iids: [item1.iid, item2.iid]).to_a })
          .to contain_exactly(item1, item2)
      end

      it 'finds only the items within the project we are looking at' do
        another_project = create(:project)
        iids = [item1, item2].map(&:iid)

        iids.each do |iid|
          create(:work_item, project: another_project, iid: iid)
        end

        expect(batch_sync { resolve_items(iids: iids).to_a }).to contain_exactly(item1, item2)
      end
    end
  end

  context "when passing a non existent, batch loaded project" do
    let!(:project) do
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_items(iids: ["don't", "break"])).to be_empty
    end
  end

  def resolve_items(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context, arg_style: :internal)
  end
end
