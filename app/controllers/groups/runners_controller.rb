# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  before_action :authorize_read_group_runners!, only: [:index, :show]
  before_action :authorize_admin_group_runners!, only: [:edit, :update, :destroy, :pause, :resume]
  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  feature_category :runner
  urgency :low

  def index
    finder = Ci::RunnersFinder.new(current_user: current_user, params: { group: @group })
    @group_runners_limited_count = finder.execute.except(:limit, :offset).page.total_count_with_limit(:all, limit: 1000)

    Gitlab::Tracking.event(self.class.name, 'index', user: current_user, namespace: @group)
  end

  def show
  end

  def edit
  end

  def update
    if Ci::Runners::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to group_runner_path(@group, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  private

  def runner
    @runner ||= Ci::RunnersFinder.new(current_user: current_user, params: { group: @group }).execute
      .except(:limit, :offset)
      .find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end

Groups::RunnersController.prepend_mod
