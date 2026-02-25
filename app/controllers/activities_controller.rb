class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[edit update destroy quick_update duplicate dismiss_repeat]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    @activities = current_user.activities.on_date(@date).order(created_at: :desc).with_attached_photos
    @grouped = @activities.group_by(&:category)
    @day_activities = current_user.activities.on_date(@date)
    @calories_in = @day_activities.calories_intake
    @calories_burned = @day_activities.calories_burned
    @calories_net = @calories_in - @calories_burned
    @macros = @day_activities.macro_totals
    @recommendations = current_user.recommendations
    @last_food_at = current_user.activities
      .where(category: %w[food coffee])
      .order(created_at: :desc)
      .pick(:created_at)
    dismissed = session[:dismissed_repeat_ids] || []
    @prev_activities = filter_by_time_period(
      filter_already_added(
        current_user.activities.on_date(@date - 1.day).order(:category, :created_at),
        @activities
      )
    ).reject { |a| dismissed.include?(a.id) }
    @time_period = current_time_period
  end

  def dismiss_repeat
    session[:dismissed_repeat_ids] ||= []
    session[:dismissed_repeat_ids] |= [@activity.id]
    head :ok
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
      unit: params[:unit],
      health_concerns: current_user.health_concerns
    )

    if result
      render json: result
    else
      render json: { error: "Could not estimate calories" }, status: :unprocessable_entity
    end
  end

  def analyze_bp
    date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    activities_today = current_user.activities.on_date(date).to_a

    result = BpAnalyzer.analyze(
      systolic: params[:systolic],
      diastolic: params[:diastolic],
      user: current_user,
      activities_today: activities_today
    )

    if result
      render json: result
    else
      render json: { error: "Could not analyze reading" }, status: :unprocessable_entity
    end
  end

  def analyze_sleep
    date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    activities_today = current_user.activities.on_date(date).to_a

    result = SleepAnalyzer.analyze(
      hours: params[:hours],
      notes: params[:notes],
      user: current_user,
      activities_today: activities_today
    )

    if result
      render json: result
    else
      render json: { error: "Could not analyze sleep" }, status: :unprocessable_entity
    end
  end

  def analyze_medication
    date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    medications_today = current_user.activities.on_date(date).where(category: "medication").to_a

    result = MedicationAnalyzer.analyze(
      name: params[:name],
      dose: params[:dose],
      unit: params[:unit],
      user: current_user,
      medications_today: medications_today
    )

    if result
      render json: result
    else
      render json: { error: "Could not analyze medication" }, status: :unprocessable_entity
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

    last_food_at = current_user.activities
      .where(category: %w[food coffee])
      .order(created_at: :desc)
      .pick(:created_at)

    tips = DietAdvisor.advise(
      user: current_user,
      activities: activities,
      recommendations: recommendations,
      last_food_at: last_food_at,
      question: params[:question].presence
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
    params.require(:activity).permit(:category, :value, :unit, :notes, :performed_on, :calories,
                                     :protein_g, :carbs_g, :fat_g, :fiber_g, :sugar_g, photos: [])
  end

  def activity_signature(activity)
    [activity.category, activity.value.to_f, activity.unit, activity.calories.to_i, activity.notes]
  end

  def current_time_period
    hour = Time.zone.now.hour
    if hour < 12
      :morning
    elsif hour < 17
      :afternoon
    else
      :evening
    end
  end

  def time_period_for(time)
    hour = time.in_time_zone(Time.zone).hour
    if hour < 12
      :morning
    elsif hour < 17
      :afternoon
    else
      :evening
    end
  end

  def filter_by_time_period(activities)
    period = current_time_period
    activities.select { |a| time_period_for(a.created_at) == period }
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
