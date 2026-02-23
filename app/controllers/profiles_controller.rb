class ProfilesController < ApplicationController
  def show
    @user = current_user
    @recommendations = @user.recommendations
    today = current_user.activities.on_date(Time.zone.today)
    @today = {
      calories_in: today.calories_intake,
      calories_burned: today.calories_burned,
      water: today.where(category: "water").sum(:value).to_f.round(1),
      protein_g: today.macro_totals[:protein_g],
      carbs_g: today.macro_totals[:carbs_g],
      fat_g: today.macro_totals[:fat_g]
    }
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
