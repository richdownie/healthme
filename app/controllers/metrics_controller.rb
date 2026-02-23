class MetricsController < ApplicationController
  def show
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.today
    @recommendations = current_user.recommendations
  end

  def data
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.today
    activities = current_user.activities.where(performed_on: start_date..end_date)

    dates = (start_date..end_date).to_a
    grouped = activities.group_by(&:performed_on)

    render json: {
      dates: dates.map(&:iso8601),
      calories_in: dates.map { |d| day_sum(grouped[d], Activity::INTAKE_CATEGORIES, :calories) },
      calories_burned: dates.map { |d| day_sum(grouped[d], Activity::BURN_CATEGORIES, :calories) },
      protein: dates.map { |d| day_sum(grouped[d], Activity::INTAKE_CATEGORIES, :protein_g) },
      carbs: dates.map { |d| day_sum(grouped[d], Activity::INTAKE_CATEGORIES, :carbs_g) },
      fat: dates.map { |d| day_sum(grouped[d], Activity::INTAKE_CATEGORIES, :fat_g) },
      water_cups: dates.map { |d| day_sum(grouped[d], %w[water], :value) },
      exercise_minutes: {
        walk: dates.map { |d| day_sum(grouped[d], %w[walk], :value) },
        run: dates.map { |d| day_sum(grouped[d], %w[run], :value) },
        weights: dates.map { |d| day_sum(grouped[d], %w[weights], :value) },
        yoga: dates.map { |d| day_sum(grouped[d], %w[yoga], :value) }
      },
      blood_pressure: bp_readings(activities),
      sleep_hours: dates.map { |d| day_sum(grouped[d], %w[sleep], :value) },
      prayer_minutes: dates.map { |d| day_sum(grouped[d], %w[prayer_meditation], :value) },
      medication_count: dates.map { |d| day_count(grouped[d], %w[medication]) }
    }
  end

  private

  def day_sum(day_activities, categories, field)
    return 0 unless day_activities
    day_activities.select { |a| a.category.in?(categories) }.sum { |a| a.send(field).to_f }.round(1)
  end

  def day_count(day_activities, categories)
    return 0 unless day_activities
    day_activities.count { |a| a.category.in?(categories) }
  end

  def bp_readings(activities)
    activities.where(category: "blood_pressure").order(:performed_on, :created_at).map do |a|
      { date: a.performed_on.iso8601, systolic: a.value.to_f, diastolic: a.unit.to_f, time: a.created_at.in_time_zone.strftime("%-I:%M %p") }
    end
  end
end
