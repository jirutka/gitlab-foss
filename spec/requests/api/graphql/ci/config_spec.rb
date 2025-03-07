# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciConfig' do
  include GraphqlHelpers
  include StubRequests

  subject(:post_graphql_query) { post_graphql(query, current_user: user) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:query) do
    %(
      query {
        ciConfig(projectPath: "#{project.full_path}", content: "#{content}", dryRun: false) {
          status
          errors
          warnings
          stages {
            nodes {
              name
              groups {
                nodes {
                  name
                  size
                  jobs {
                    nodes {
                      name
                      groupName
                      stage
                      script
                      beforeScript
                      afterScript
                      allowFailure
                      only {
                        refs
                      }
                      when
                      except {
                        refs
                      }
                      environment
                      tags
                      needs {
                        nodes {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          mergedYaml
          includes {
            type
            location
            blob
            raw
            extra
            contextProject
            contextSha
          }
        }
      }
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql_query
    end
  end

  it 'returns the correct structure' do
    post_graphql_query

    expect(graphql_data['ciConfig']).to include(
      "status" => "VALID",
      "errors" => [],
      "warnings" => [],
      "includes" => [],
      "mergedYaml" => a_kind_of(String),
      "stages" =>
      {
        "nodes" =>
        [
          {
            "name" => "build",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "rspec",
                  "size" => 2,
                  "jobs" =>
                  {
                    "nodes" =>
                    [
                      {
                        "name" => "rspec 0 1",
                        "groupName" => "rspec",
                        "stage" => "build",
                        "script" => ["rake spec"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => false,
                        "only" => { "refs" => %w[branches master] },
                        "when" => "on_success",
                        "except" => nil,
                        "environment" => nil,
                        "tags" => %w[ruby postgres],
                        "needs" => { "nodes" => [] }
                      },
                      {
                        "name" => "rspec 0 2",
                        "groupName" => "rspec",
                        "stage" => "build",
                        "script" => ["rake spec"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => true,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "on_failure",
                        "except" => nil,
                        "environment" => nil,
                        "tags" => [],
                        "needs" => { "nodes" => [] }
                      }
                    ]
                  }
                },
                {
                  "name" => "spinach", "size" => 1, "jobs" =>
                {
                  "nodes" =>
                    [
                      {
                        "name" => "spinach",
                        "groupName" => "spinach",
                        "stage" => "build",
                        "script" => ["rake spinach"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => false,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "on_success",
                        "except" => { "refs" => ["tags"] },
                        "environment" => nil,
                        "tags" => [],
                        "needs" => { "nodes" => [] }
                      }
                    ]
                  }
                }
              ]
            }
          },
          {
            "name" => "test",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "docker",
                  "size" => 1,
                    "jobs" =>
                    {
                      "nodes" => [
                      {
                        "name" => "docker",
                        "groupName" => "docker",
                        "stage" => "test",
                        "script" => ["curl http://dockerhub/URL"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => true,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "manual",
                        "except" => { "refs" => ["branches"] },
                        "environment" => nil,
                        "tags" => [],
                        "needs" => { "nodes" => [{ "name" => "spinach" }, { "name" => "rspec 0 1" }] }
                      }
                    ]
                  }
                }
              ]
            }
          },
          {
            "name" => "deploy",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "deploy_job",
                  "size" => 1,
                    "jobs" =>
                    {
                      "nodes" => [
                      {
                        "name" => "deploy_job",
                        "groupName" => "deploy_job",
                        "stage" => "deploy",
                        "script" => ["echo 'done'"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => false,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "on_success",
                        "except" => nil,
                        "environment" => "production",
                        "tags" => [],
                        "needs" => { "nodes" => [] }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    )
  end

  context 'when the config file includes other files' do
    let_it_be(:content) do
      YAML.dump(
        include: 'other_file.yml',
        rspec: {
          script: 'rspec'
        }
      )
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).with(an_instance_of(String), 'other_file.yml') do
          YAML.dump(
            build: {
              script: 'build'
            }
          )
        end
      end

      post_graphql_query
    end

    it_behaves_like 'a working graphql query'

    it 'returns the correct structure with included files' do
      expect(graphql_data['ciConfig']).to eq(
        "status" => "VALID",
        "errors" => [],
        "warnings" => [],
        "includes" => [
          {
            "type" => "local",
            "location" => "other_file.yml",
            "blob" => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/other_file.yml",
            "raw" => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/other_file.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          }
        ],
        "mergedYaml" => "---\nbuild:\n  script: build\nrspec:\n  script: rspec\n",
        "stages" =>
        {
          "nodes" =>
          [
            {
              "name" => "test",
              "groups" =>
              {
                "nodes" =>
                [
                  {
                    "name" => "build",
                    "size" => 1,
                    "jobs" =>
                    {
                      "nodes" =>
                      [
                        {
                          "name" => "build",
                          "stage" => "test",
                          "groupName" => "build",
                          "script" => ["build"],
                          "afterScript" => [],
                          "beforeScript" => [],
                          "allowFailure" => false,
                          "environment" => nil,
                          "except" => nil,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "on_success",
                          "tags" => [],
                          "needs" => { "nodes" => [] }
                        }
                      ]
                    }
                  },
                  {
                    "name" => "rspec",
                    "size" => 1,
                    "jobs" =>
                    {
                      "nodes" =>
                      [
                        { "name" => "rspec",
                          "stage" => "test",
                          "groupName" => "rspec",
                          "script" => ["rspec"],
                          "afterScript" => [],
                          "beforeScript" => [],
                          "allowFailure" => false,
                          "environment" => nil,
                          "except" => nil,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "on_success",
                          "tags" => [],
                           "needs" => { "nodes" => [] } }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      )
    end
  end

  context 'when the config file has multiple includes' do
    let_it_be(:other_project) { create(:project, :repository, creator: user, namespace: user.namespace) }

    let_it_be(:content) do
      YAML.dump(
        include: [
          { local: 'other_file.yml' },
          { remote: 'https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml' },
          { file: 'other_project_file.yml', project: other_project.full_path },
          { template: 'Jobs/Build.gitlab-ci.yml' }
        ],
        rspec: {
          script: 'rspec'
        }
      )
    end

    let(:remote_file_content) do
      YAML.dump(
        remote_file_test: {
          script: 'remote_file_test'
        }
      )
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).with(an_instance_of(String), 'other_file.yml') do
          YAML.dump(
            build: {
              script: 'build'
            }
          )
        end

        allow(repository).to receive(:blob_data_at).with(an_instance_of(String), 'other_project_file.yml') do
          YAML.dump(
            other_project_test: {
              script: 'other_project_test'
            }
          )
        end
      end

      stub_full_request('https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml').to_return(body: remote_file_content)

      post_graphql_query
    end

    it_behaves_like 'a working graphql query'

    # rubocop:disable Layout/LineLength
    it 'returns correct includes' do
      expect(graphql_data['ciConfig']["includes"]).to eq(
        [
          {
            "type" => "local",
            "location" => "other_file.yml",
            "blob" => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/other_file.yml",
            "raw" => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/other_file.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "remote",
            "location" => "https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml",
            "blob" => nil,
            "raw" => "https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "file",
            "location" => "other_project_file.yml",
            "blob" => "http://localhost/#{other_project.full_path}/-/blob/#{other_project.commit.sha}/other_project_file.yml",
            "raw" => "http://localhost/#{other_project.full_path}/-/raw/#{other_project.commit.sha}/other_project_file.yml",
            "extra" => { "project" => other_project.full_path, "ref" => "HEAD" },
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "template",
            "location" => "Jobs/Build.gitlab-ci.yml",
            "blob" => nil,
            "raw" => "https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          }
        ]
      )
    end
    # rubocop:enable Layout/LineLength
  end
end
