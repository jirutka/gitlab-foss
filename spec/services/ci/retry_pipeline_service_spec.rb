# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryPipelineService, '#execute' do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:service) { described_class.new(project, user) }

  context 'when user has full ability to modify pipeline' do
    before do
      project.add_developer(user)

      create(:protected_branch, :developers_can_merge,
             name: pipeline.ref, project: project)
    end

    context 'when there are already retried jobs present' do
      before do
        create_build('rspec', :canceled, 0, retried: true)
        create_build('rspec', :failed, 0)
      end

      it 'does not retry jobs that has already been retried' do
        expect(statuses.first).to be_retried
        expect { service.execute(pipeline) }
          .to change { CommitStatus.count }.by(1)
      end
    end

    context 'when there are failed builds in the last stage' do
      before do
        create_build('rspec 1', :success, 0)
        create_build('rspec 2', :failed, 1)
        create_build('rspec 3', :canceled, 1)
      end

      it 'enqueues all builds in the last stage' do
        service.execute(pipeline)

        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_pending
        expect(pipeline.reload).to be_running
      end
    end

    context 'when there are failed or canceled builds in the first stage' do
      before do
        create_build('rspec 1', :failed, 0)
        create_build('rspec 2', :canceled, 0)
        create_build('rspec 3', :canceled, 1)
        create_build('spinach 1', :canceled, 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('spinach 1')).to be_created
        expect(pipeline.reload).to be_running
      end

      it 'changes ownership of subsequent builds' do
        expect(build('rspec 2').user).not_to eq(user)
        expect(build('rspec 3').user).not_to eq(user)
        expect(build('spinach 1').user).not_to eq(user)

        service.execute(pipeline)

        expect(build('rspec 2').user).to eq(user)
        expect(build('rspec 3').user).to eq(user)
        expect(build('spinach 1').user).to eq(user)
      end
    end

    context 'when there is failed build present which was run on failure' do
      before do
        create_build('rspec 1', :failed, 0)
        create_build('rspec 2', :canceled, 0)
        create_build('rspec 3', :canceled, 1)
        create_build('report 1', :failed, 2)
      end

      it 'retries builds only in the first stage' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('report 1')).to be_created
        expect(pipeline.reload).to be_running
      end

      it 'creates a new job for report job in this case' do
        service.execute(pipeline)

        expect(statuses.find_by(name: 'report 1', status: 'failed')).to be_retried
      end
    end

    context 'when there is a failed test in a DAG' do
      before do
        create_build('build', :success, 0)
        create_build('build2', :success, 0)
        test_build = create_build('test', :failed, 1, scheduling_type: :dag)
        create(:ci_build_need, build: test_build, name: 'build')
        create(:ci_build_need, build: test_build, name: 'build2')
      end

      it 'retries the test' do
        service.execute(pipeline)

        expect(build('build')).to be_success
        expect(build('build2')).to be_success
        expect(build('test')).to be_pending
        expect(build('test').needs.map(&:name)).to match_array(%w(build build2))
      end

      context 'when there is a failed DAG test without needs' do
        before do
          create_build('deploy', :failed, 2, scheduling_type: :dag)
        end

        it 'retries the test' do
          service.execute(pipeline)

          expect(build('build')).to be_success
          expect(build('build2')).to be_success
          expect(build('test')).to be_pending
          expect(build('deploy')).to be_pending
        end
      end
    end

    context 'when the last stage was skipped' do
      before do
        create_build('build 1', :success, 0)
        create_build('test 2', :failed, 1)
        create_build('report 3', :skipped, 2)
        create_build('report 4', :skipped, 2)
      end

      it 'retries builds only in the first stage' do
        service.execute(pipeline)

        expect(build('build 1')).to be_success
        expect(build('test 2')).to be_pending
        expect(build('report 3')).to be_created
        expect(build('report 4')).to be_created
        expect(pipeline.reload).to be_running
      end
    end

    context 'when pipeline contains manual actions' do
      context 'when there are optional manual actions only' do
        context 'when there is a canceled manual action in first stage' do
          before do
            create_build('rspec 1', :failed, 0)
            create_build('staging', :canceled, 0, when: :manual, allow_failure: true)
            create_build('rspec 2', :canceled, 1)
          end

          it 'retries failed builds and marks subsequent for processing' do
            service.execute(pipeline)

            expect(build('rspec 1')).to be_pending
            expect(build('staging')).to be_manual
            expect(build('rspec 2')).to be_created
            expect(pipeline.reload).to be_running
          end

          it 'changes ownership of subsequent builds' do
            expect(build('staging').user).not_to eq(user)
            expect(build('rspec 2').user).not_to eq(user)

            service.execute(pipeline)

            expect(build('staging').user).to eq(user)
            expect(build('rspec 2').user).to eq(user)
          end
        end
      end

      context 'when pipeline has blocking manual actions defined' do
        context 'when pipeline retry should enqueue builds' do
          before do
            create_build('test', :failed, 0)
            create_build('deploy', :canceled, 0, when: :manual, allow_failure: false)
            create_build('verify', :canceled, 1)
          end

          it 'retries failed builds' do
            service.execute(pipeline)

            expect(build('test')).to be_pending
            expect(build('deploy')).to be_manual
            expect(build('verify')).to be_created
            expect(pipeline.reload).to be_running
          end
        end

        context 'when pipeline retry should block pipeline immediately' do
          before do
            create_build('test', :success, 0)
            create_build('deploy:1', :success, 1, when: :manual, allow_failure: false)
            create_build('deploy:2', :failed, 1, when: :manual, allow_failure: false)
            create_build('verify', :canceled, 2)
          end

          it 'reprocesses blocking manual action and blocks pipeline' do
            service.execute(pipeline)

            expect(build('deploy:1')).to be_success
            expect(build('deploy:2')).to be_manual
            expect(build('verify')).to be_created
            expect(pipeline.reload).to be_blocked
          end
        end
      end

      context 'when there is a skipped manual action in last stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('rspec 2', :skipped, 0, when: :manual, allow_failure: true)
          create_build('staging', :skipped, 1, when: :manual, allow_failure: true)
        end

        it 'retries canceled job and reprocesses manual actions' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('rspec 2')).to be_manual
          expect(build('staging')).to be_created
          expect(pipeline.reload).to be_running
        end
      end

      context 'when there is a created manual action in the last stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('staging', :created, 1, when: :manual, allow_failure: true)
        end

        it 'retries canceled job and does not update the manual action' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('staging')).to be_created
          expect(pipeline.reload).to be_running
        end
      end

      context 'when there is a created manual action in the first stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('staging', :created, 0, when: :manual, allow_failure: true)
        end

        it 'retries canceled job and processes the manual action' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('staging')).to be_manual
          expect(pipeline.reload).to be_running
        end
      end
    end

    it 'closes all todos about failed jobs for pipeline' do
      expect(::MergeRequests::AddTodoWhenBuildFailsService)
        .to receive_message_chain(:new, :close_all)

      service.execute(pipeline)
    end

    it 'reprocesses the pipeline' do
      expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

      service.execute(pipeline)
    end

    context 'when pipeline has processables with nil scheduling_type' do
      let!(:build1) { create_build('build1', :success, 0) }
      let!(:build2) { create_build('build2', :failed, 0) }
      let!(:build3) { create_build('build3', :failed, 1) }
      let!(:build3_needs_build1) { create(:ci_build_need, build: build3, name: build1.name) }

      before do
        statuses.update_all(scheduling_type: nil)
      end

      it 'populates scheduling_type of processables' do
        service.execute(pipeline)

        expect(build1.reload.scheduling_type).to eq('stage')
        expect(build2.reload.scheduling_type).to eq('stage')
        expect(build3.reload.scheduling_type).to eq('dag')
      end
    end

    context 'when the pipeline is a downstream pipeline and the bridge is depended' do
      let!(:bridge) { create(:ci_bridge, :strategy_depend, status: 'success') }

      before do
        create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge)
      end

      context 'without permission' do
        it 'does nothing to the bridge' do
          expect { service.execute(pipeline) }.to not_change { bridge.reload.status }
           .and not_change { bridge.reload.user }
        end
      end

      context 'with permission' do
        let!(:bridge_pipeline) { create(:ci_pipeline, project: create(:project)) }
        let!(:bridge) do
          create(:ci_bridge, :strategy_depend, status: 'success', pipeline: bridge_pipeline)
        end

        before do
          bridge_pipeline.project.add_maintainer(user)
        end

        it 'marks source bridge as pending' do
          expect { service.execute(pipeline) }.to change { bridge.reload.status }.to('pending')
            .and not_change { bridge.reload.user }
        end
      end
    end

    context 'when there are skipped jobs in later stages' do
      before do
        create_build('build 1', :success, 0)
        create_build('test 2', :failed, 1)
        create_build('report 3', :skipped, 2)
        create_bridge('deploy 4', :skipped, 2)
      end

      it 'retries failed jobs and processes skipped jobs' do
        service.execute(pipeline)

        expect(build('build 1')).to be_success
        expect(build('test 2')).to be_pending
        expect(build('report 3')).to be_created
        expect(build('deploy 4')).to be_created

        expect(pipeline.reload).to be_running
      end
    end

    context 'when user is not allowed to retry build' do
      before do
        build = create(:ci_build, pipeline: pipeline, status: :failed)
        allow_next_instance_of(Ci::RetryJobService) do |service|
          allow(service).to receive(:can?).with(user, :update_build, build).and_return(false)
        end
      end

      it 'returns an error' do
        response = service.execute(pipeline)

        expect(response.http_status).to eq(:forbidden)
        expect(response.errors).to include('403 Forbidden')
        expect(pipeline.reload).not_to be_running
      end
    end
  end

  context 'when user is not allowed to retry pipeline' do
    it 'returns an error' do
      response = service.execute(pipeline)

      expect(response.http_status).to eq(:forbidden)
      expect(response.errors).to include('403 Forbidden')
      expect(pipeline.reload).not_to be_running
    end
  end

  context 'when user is not allowed to trigger manual action' do
    before do
      project.add_developer(user)
      create(:protected_branch, :maintainers_can_push,
             name: pipeline.ref, project: project)
    end

    context 'when there is a failed manual action present' do
      before do
        create_build('test', :failed, 0)
        create_build('deploy', :failed, 0, when: :manual)
        create_build('verify', :canceled, 1)
      end

      it 'returns an error' do
        response = service.execute(pipeline)

        expect(response.http_status).to eq(:forbidden)
        expect(response.errors).to include('403 Forbidden')
        expect(pipeline.reload).not_to be_running
      end
    end

    context 'when there is a failed manual action in later stage' do
      before do
        create_build('test', :failed, 0)
        create_build('deploy', :failed, 1, when: :manual)
        create_build('verify', :canceled, 2)
      end

      it 'returns an error' do
        response = service.execute(pipeline)

        expect(response.http_status).to eq(:forbidden)
        expect(response.errors).to include('403 Forbidden')
        expect(pipeline.reload).not_to be_running
      end
    end
  end

  context 'when maintainer is allowed to push to forked project' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:forked_project) { fork_project(project) }
    let(:pipeline) { create(:ci_pipeline, project: forked_project, ref: 'fixes') }

    before do
      project.add_maintainer(user)
      create(:merge_request,
        source_project: forked_project,
        target_project: project,
        source_branch: 'fixes',
        allow_collaboration: true)
      create_build('rspec 1', :failed, 1)
    end

    it 'allows to retry failed pipeline' do
      allow_any_instance_of(Project).to receive(:branch_allows_collaboration?).and_return(true)
      allow_any_instance_of(Project).to receive(:empty_repo?).and_return(false)

      service.execute(pipeline)

      expect(build('rspec 1')).to be_pending
      expect(pipeline.reload).to be_running
    end
  end

  def statuses
    pipeline.reload.statuses
  end

  # The method name can be confusing because this can actually return both Ci::Build and Ci::Bridge
  def build(name)
    statuses.latest.find_by(name: name)
  end

  def create_build(name, status, stage_num, **opts)
    create_processable(:ci_build, name, status, stage_num, **opts)
  end

  def create_bridge(name, status, stage_num, **opts)
    create_processable(:ci_bridge, name, status, stage_num, **opts)
  end

  def create_processable(type, name, status, stage_num, **opts)
    create(type, name: name,
                 status: status,
                 stage: "stage_#{stage_num}",
                 stage_idx: stage_num,
                 pipeline: pipeline, **opts) do |_job|
      ::Ci::ProcessPipelineService.new(pipeline).execute
    end
  end
end
