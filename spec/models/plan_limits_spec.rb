# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlanLimits do
  let_it_be(:project) { create(:project) }
  let_it_be(:plan_limits) { create(:plan_limits) }
  let(:project_hooks_count) { 2 }

  before do
    create_list(:project_hook, project_hooks_count, project: project)
  end

  describe '#exceeded?' do
    let(:alternate_limit) { double('an alternate limit value') }

    subject(:exceeded_limit) { plan_limits.exceeded?(:project_hooks, limit_subject, alternate_limit: alternate_limit) }

    before do
      allow(plan_limits).to receive(:limit_for).with(:project_hooks, alternate_limit: alternate_limit).and_return(limit)
    end

    shared_examples_for 'comparing limits' do
      context 'when limit for given name results to a disabled value' do
        let(:limit) { nil }

        it { is_expected.to eq(false) }
      end

      context 'when limit for given name results to a non-disabled value' do
        context 'and given count is smaller than limit' do
          let(:limit) { project_hooks_count + 1 }

          it { is_expected.to eq(false) }
        end

        context 'and given count is equal to the limit' do
          let(:limit) { project_hooks_count }

          it { is_expected.to eq(true) }
        end

        context 'and given count is greater than the limit' do
          let(:limit) { project_hooks_count - 1 }

          it { is_expected.to eq(true) }
        end
      end
    end

    context 'when given limit subject is an integer' do
      let(:limit_subject) { project.hooks.count }

      it_behaves_like 'comparing limits'
    end

    context 'when given limit subject is an ActiveRecord::Relation' do
      let(:limit_subject) { project.hooks }

      it_behaves_like 'comparing limits'
    end

    context 'when given limit subject is something else' do
      let(:limit_subject) { ProjectHook }
      let(:limit) { 100 }

      it 'raises an error' do
        expect { exceeded_limit }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#limit_for' do
    let(:alternate_limit) { nil }

    subject(:limit) { plan_limits.limit_for(:project_hooks, alternate_limit: alternate_limit) }

    context 'when given limit name does not exist' do
      it 'raises an error' do
        expect { plan_limits.limit_for(:project_foo) }.to raise_error(described_class::LimitUndefinedError)
      end
    end

    context 'when given limit name is disabled' do
      before do
        plan_limits.update!(project_hooks: 0)
      end

      it { is_expected.to eq(nil) }

      context 'and alternate_limit is a non-zero integer' do
        let(:alternate_limit) { 1 }

        it { is_expected.to eq(1) }
      end

      context 'and alternate_limit is zero' do
        let(:alternate_limit) { 0 }

        it { is_expected.to eq(nil) }
      end

      context 'and alternate_limit is a proc that returns non-zero integer' do
        let(:alternate_limit) { -> { 1 } }

        it { is_expected.to eq(1) }
      end

      context 'and alternate_limit is a proc that returns zero' do
        let(:alternate_limit) { -> { 0 } }

        it { is_expected.to eq(nil) }
      end

      context 'and alternate_limit is a proc that returns nil' do
        let(:alternate_limit) { -> { nil } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'when given limit name is enabled' do
      let(:plan_limit_value) { 2 }

      before do
        plan_limits.update!(project_hooks: plan_limit_value)
      end

      context 'and alternate_limit is a non-zero integer that is bigger than the plan limit' do
        let(:alternate_limit) { plan_limit_value + 1 }

        it { is_expected.to eq(plan_limit_value) }
      end

      context 'and alternate_limit is a non-zero integer that is smaller than the plan limit' do
        let(:alternate_limit) { plan_limit_value - 1 }

        it { is_expected.to eq(alternate_limit) }
      end

      context 'and alternate_limit is zero' do
        let(:alternate_limit) { 0 }

        it { is_expected.to eq(plan_limit_value) }
      end

      context 'and alternate_limit is a proc that returns non-zero integer that is bigger than the plan limit' do
        let(:alternate_limit) { -> { plan_limit_value + 1 } }

        it { is_expected.to eq(plan_limit_value) }
      end

      context 'and alternate_limit is a proc that returns non-zero integer that is smaller than the plan limit' do
        let(:alternate_limit) { -> { plan_limit_value - 1 } }

        it { is_expected.to eq(alternate_limit.call) }
      end

      context 'and alternate_limit is a proc that returns zero' do
        let(:alternate_limit) { -> { 0 } }

        it { is_expected.to eq(plan_limit_value) }
      end

      context 'and alternate_limit is a proc that returns nil' do
        let(:alternate_limit) { -> { nil } }

        it { is_expected.to eq(plan_limit_value) }
      end
    end
  end

  context 'validates default values' do
    # TODO: For now, these columns have default values set to 0.
    # Each artifact type listed here have their own matching issues to determine
    # the actual limit value. In each of those issues, the default value should also be updated to
    # a non-zero value. Also update existing values of zero to whatever the default value will be.
    # For a list of the issues, see: https://gitlab.com/gitlab-org/gitlab/-/issues/211378#note_355619970
    let(:disabled_max_artifact_size_columns) do
      %w[
        ci_max_artifact_size_archive
        ci_max_artifact_size_metadata
        ci_max_artifact_size_trace
        ci_max_artifact_size_junit
        ci_max_artifact_size_sast
        ci_max_artifact_size_dast
        ci_max_artifact_size_codequality
        ci_max_artifact_size_license_management
        ci_max_artifact_size_performance
        ci_max_artifact_size_browser_performance
        ci_max_artifact_size_load_performance
        ci_max_artifact_size_metrics
        ci_max_artifact_size_metrics_referee
        ci_max_artifact_size_network_referee
        ci_max_artifact_size_dotenv
        ci_max_artifact_size_cobertura
        ci_max_artifact_size_accessibility
        ci_max_artifact_size_cluster_applications
        ci_max_artifact_size_secret_detection
        ci_max_artifact_size_requirements
        ci_max_artifact_size_coverage_fuzzing
        ci_max_artifact_size_api_fuzzing
      ]
    end

    let(:columns_with_zero) do
      %w[
        ci_active_pipelines
        ci_pipeline_size
        ci_active_jobs
        storage_size_limit
        daily_invites
      ] + disabled_max_artifact_size_columns
    end

    it "has positive values for enabled limits" do
      attributes = plan_limits.attributes
      attributes = attributes.except(described_class.primary_key)
      attributes = attributes.except(described_class.reflections.values.map(&:foreign_key))
      attributes = attributes.except(*columns_with_zero)

      expect(attributes).to all(include(be_positive))
    end

    it "has zero values for disabled limits" do
      attributes = plan_limits.attributes
      attributes = attributes.slice(*columns_with_zero)

      expect(attributes).to all(include(be_zero))
    end
  end
end
