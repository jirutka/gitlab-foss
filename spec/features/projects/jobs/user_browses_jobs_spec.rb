# frozen_string_literal: true

require 'spec_helper'

def visit_jobs_page
  visit(project_jobs_path(project))

  wait_for_requests
end

RSpec.describe 'User browses jobs' do
  describe 'Jobs', :js do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }

    before do
      project.add_maintainer(user)
      project.enable_ci

      sign_in(user)
    end

    describe 'header tabs' do
      before do
        visit_jobs_page
      end

      it 'shows a tab for All jobs and count' do
        expect(page.find('[data-testid="jobs-all-tab"]').text).to include('All')
        expect(page.find('[data-testid="jobs-all-tab"] .badge').text).to include('0')
      end

      it 'shows a tab for Finished jobs and count' do
        expect(page.find('[data-testid="jobs-finished-tab"]').text).to include('Finished')
      end

      it 'updates the content when tab is clicked' do
        page.find('[data-testid="jobs-finished-tab"]').click
        wait_for_requests

        expect(page).to have_content('No jobs to show')
      end
    end

    describe 'Empty state' do
      before do
        visit_jobs_page
      end

      it 'renders an empty state' do
        expect(page).to have_content 'Use jobs to automate your tasks'
        expect(page).to have_content 'Create CI/CD configuration file'
      end
    end

    describe 'Job actions' do
      let!(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: 'master') }

      context 'when a job can be canceled' do
        let!(:job) do
          create(:ci_build, pipeline: pipeline,
                 stage: 'test')
        end

        before do
          job.run

          visit_jobs_page
        end

        it 'cancels a job successfully' do
          page.find('[data-testid="cancel-button"]').click

          wait_for_requests

          expect(page).to have_selector('.ci-canceled')
          expect(page).not_to have_selector('[data-testid="jobs-table-error-alert"]')
        end
      end

      context 'when a job can be retried' do
        let!(:job) do
          create(:ci_build, pipeline: pipeline,
                 stage: 'test')
        end

        before do
          job.drop

          visit_jobs_page
        end

        it 'retries a job successfully' do
          page.find('[data-testid="retry"]').click

          wait_for_requests

          expect(page).to have_selector('.ci-pending')
        end
      end

      context 'with a coverage job' do
        let!(:job) do
          create(:ci_build, :coverage, pipeline: pipeline)
        end

        before do
          job.update!(coverage_regex: '/Coverage (\d+)%/')

          visit_jobs_page

          wait_for_requests
        end

        it 'shows the coverage' do
          page.within('[data-testid="job-coverage"]') do
            expect(page).to have_content('99.9%')
          end
        end
      end

      context 'with a scheduled job' do
        let!(:scheduled_job) { create(:ci_build, :scheduled, pipeline: pipeline, name: 'build') }

        before do
          visit_jobs_page
        end

        it 'plays a job successfully' do
          page.find('[data-testid="play-scheduled"]').click

          page.within '#play-job-modal' do
            page.find_button('OK').click
          end

          wait_for_requests

          expect(page).to have_selector('.ci-pending')
        end

        it 'unschedules a job successfully' do
          page.find('[data-testid="unschedule"]').click

          wait_for_requests

          expect(page).to have_selector('.ci-manual')
        end
      end

      context 'with downloadable artifacts' do
        let!(:with_artifacts) do
          build = create(:ci_build, :success,
                         pipeline: pipeline,
                         name: 'rspec tests',
                         stage: 'test')

          create(:ci_job_artifact, :archive, job: build)
        end

        before do
          visit_jobs_page
        end

        it 'shows the download artifacts button' do
          expect(page).to have_selector('[data-testid="download-artifacts"]')
        end
      end

      context 'with artifacts expired' do
        let!(:with_artifacts_expired) do
          create(:ci_build, :expired, :success,
                 pipeline: pipeline,
                 name: 'rspec',
                 stage: 'test')
        end

        before do
          visit_jobs_page
        end

        it 'does not show the download artifacts button' do
          expect(page).not_to have_selector('[data-testid="download-artifacts"]')
        end
      end
    end

    describe 'Jobs table' do
      let!(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: 'master') }

      context 'column links' do
        let!(:job) do
          create(:ci_build, pipeline: pipeline,
                 stage: 'test')
        end

        before do
          job.run

          visit_jobs_page
        end

        it 'contains a link to the pipeline' do
          expect(page.find('[data-testid="pipeline-id"]')).to have_content "##{pipeline.id}"
        end

        it 'contains a link to the job sha' do
          expect(page.find('[data-testid="job-sha"]')).to have_content "#{job.sha[0..7]}"
        end

        it 'contains a link to the job id' do
          expect(page.find('[data-testid="job-id-link"]')).to have_content "#{job.id}"
        end

        it 'contains a link to the job ref' do
          expect(page.find('[data-testid="job-ref"]')).to have_content "#{job.ref}"
        end
      end
    end

    describe 'when user is not logged in' do
      before do
        sign_out(user)
      end

      context 'when project is public' do
        let(:public_project) { create(:project, :public, :repository) }

        context 'without jobs' do
          it 'shows an empty state' do
            visit project_jobs_path(public_project)
            wait_for_requests

            expect(page).to have_content 'Use jobs to automate your tasks'
          end
        end
      end

      context 'when project is private' do
        let(:private_project) { create(:project, :private, :repository) }

        it 'redirects the user to sign_in and displays the flash alert' do
          visit project_jobs_path(private_project)
          wait_for_requests

          expect(page).to have_content 'You need to sign in'
          expect(page).to have_current_path("/users/sign_in")
        end
      end
    end
  end
end
