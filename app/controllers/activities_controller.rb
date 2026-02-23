class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[edit update destroy quick_update duplicate]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    @activities = current_user.activities.on_date(@date).order(created_at: :desc).with_attached_photos
    @grouped = @activities.group_by(&:category)
    @calories_in = @activities.calories_intake
    @calories_burned = @activities.calories_burned
    @calories_net = @calories_in - @calories_burned
    @recommendations = current_user.recommendations
    @prev_activities = filter_already_added(
      current_user.activities.on_date(@date - 1.day).order(:category, :created_at),
      @activities
    )
  end

  def new
    @activity = current_user.activities.new(performed_on: params[:date] || Time.zone.today)
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

  def estimate_calories
    images = []

    # Support both single photo and multiple photos params
    photo_params = Array(params[:photos] || params[:photo]).compact
    photo_params.each do |uploaded|
      next unless uploaded.respond_to?(:read)
      images << { data: Base64.strict_encode64(uploaded.read), content_type: uploaded.content_type }
    end

    result = CalorieEstimator.estimate(
      images: images,
      notes: params[:notes],
      category: params[:category],
      value: params[:value],
      unit: params[:unit]
    )

    if result
      render json: result
    else
      render json: { error: "Could not estimate calories" }, status: :unprocessable_entity
    end
  end

  def quick_update
    add = params[:add_value].to_f
    @activity.update!(value: (@activity.value || 0) + add)
    redirect_to activities_path(date: @activity.performed_on), notice: "Added #{add} #{@activity.unit}!"
  end

  def duplicate
    target_date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    new_activity = @activity.dup
    new_activity.performed_on = target_date
    @activity.photos.each { |photo| new_activity.photos.attach(photo.blob) }
    new_activity.save!
    redirect_to activities_path(date: new_activity.performed_on), notice: "Activity logged!"
  end

  def diet_tips
    date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    activities = current_user.activities.on_date(date)
    recommendations = current_user.recommendations

    tips = DietAdvisor.advise(
      user: current_user,
      activities: activities,
      recommendations: recommendations
    )

    if tips
      render json: { tips: tips }
    else
      render json: { error: "Could not generate tips" }, status: :unprocessable_entity
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
    params.require(:activity).permit(:category, :value, :unit, :notes, :performed_on, :calories, photos: [])
  end

  def activity_signature(activity)
    [activity.category, activity.value.to_f, activity.unit, activity.calories.to_i, activity.notes]
  end

  def filter_already_added(prev_activities, current_activities)
    # Count how many times each signature appears in current day
    used = Hash.new(0)
    current_activities.each { |a| used[activity_signature(a)] += 1 }

    # Remove prev activities that have already been duplicated
    prev_activities.select do |prev|
      sig = activity_signature(prev)
      if used[sig] > 0
        used[sig] -= 1
        false
      else
        true
      end
    end
  end
end
