class ProfilesController < ApplicationController
  def show
    @user = current_user
    @recommendations = @user.recommendations
    @today_activities = current_user.activities.on_date(Time.zone.today).to_a
    @today = {
      calories_in: @today_activities.select(&:intake?).sum { |a| a.calories.to_f },
      calories_burned: @today_activities.select(&:burn?).sum { |a| a.calories.to_f },
      water: @today_activities.select { |a| a.category == "water" }.sum { |a| a.value.to_f }.round(1),
      protein_g: @today_activities.select(&:intake?).sum { |a| a.protein_g.to_f }.round(1),
      carbs_g: @today_activities.select(&:intake?).sum { |a| a.carbs_g.to_f }.round(1),
      fat_g: @today_activities.select(&:intake?).sum { |a| a.fat_g.to_f }.round(1)
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
