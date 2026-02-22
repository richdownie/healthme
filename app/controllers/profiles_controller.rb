class ProfilesController < ApplicationController
  def show
    @user = current_user
    @recommendations = @user.recommendations
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :display_name, :weight, :height, :date_of_birth, :sex, :race_ethnicity,
      :activity_level, :health_concerns, :blood_pressure_systolic,
      :blood_pressure_diastolic, :goal, :timezone, :prayer_goal_minutes, :water_goal_cups,
      :fasting_start_hour
    )
  end
end
