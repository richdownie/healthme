class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[edit update destroy]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @activities = current_user.activities.on_date(@date).order(created_at: :desc)
    @grouped = @activities.group_by(&:category)
    @calories_in = @activities.calories_intake
    @calories_burned = @activities.calories_burned
    @calories_net = @calories_in - @calories_burned
  end

  def new
    @activity = current_user.activities.new(performed_on: params[:date] || Date.today)
  end

  def create
    @activity = current_user.activities.new(activity_params)

    if @activity.save
      redirect_to activities_path(date: @activity.performed_on), notice: "Activity logged!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to activities_path(date: @activity.performed_on), notice: "Activity updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    date = @activity.performed_on
    @activity.destroy
    redirect_to activities_path(date: date), notice: "Activity removed."
  end

  private

  def set_activity
    @activity = current_user.activities.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:category, :value, :unit, :notes, :performed_on, :photo, :calories)
  end
end
