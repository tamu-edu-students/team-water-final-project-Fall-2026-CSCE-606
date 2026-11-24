class Chore < ApplicationRecord
  FREQUENCIES = %w[NONE DAILY WEEKLY MONTHLY].freeze
  CATEGORIES = %w[General Kitchen Bathroom Cleaning Laundry Trash Outdoor].freeze
  CATEGORY_DETAILS = {
    "General" => { icon: "📋", hint: "Everything else around the house" },
    "Kitchen" => { icon: "🍳", hint: "Dishes, counters, fridge" },
    "Bathroom" => { icon: "🛁", hint: "Showers, sinks, toilets" },
    "Cleaning" => { icon: "🧹", hint: "Vacuuming, dusting, mopping" },
    "Laundry" => { icon: "🧺", hint: "Washing, folding, linens" },
    "Trash" => { icon: "🗑️", hint: "Bins, recycling, compost" },
    "Outdoor" => { icon: "🌿", hint: "Patio, yard, plants" }
  }.freeze

  # Common household chores offered as one-click starting points on the chores page.
  TEMPLATES = [
    { key: "trash", title: "Take out the trash", category: "Trash", frequency: "WEEKLY",
      description: "Empty all bins and take bags to the curb." },
    { key: "recycling", title: "Take out recycling", category: "Trash", frequency: "WEEKLY",
      description: "Rinse and sort recyclables before pickup." },
    { key: "kitchen", title: "Clean the kitchen", category: "Kitchen", frequency: "WEEKLY",
      description: "Wipe counters, stovetop, and sink; sweep the floor." },
    { key: "dishes", title: "Wash the dishes", category: "Kitchen", frequency: "DAILY",
      description: "Wash, dry, and put away dishes; run the dishwasher." },
    { key: "fridge", title: "Clean out the fridge", category: "Kitchen", frequency: "MONTHLY",
      description: "Toss expired food and wipe the shelves." },
    { key: "vacuum", title: "Vacuum", category: "Cleaning", frequency: "WEEKLY",
      description: "Vacuum carpets, rugs, and shared rooms." },
    { key: "mop", title: "Mop the floors", category: "Cleaning", frequency: "WEEKLY",
      description: "Mop the kitchen, bathroom, and hallway floors." },
    { key: "bathroom", title: "Clean the bathroom", category: "Bathroom", frequency: "WEEKLY",
      description: "Scrub the toilet, sink, and shower; restock supplies." },
    { key: "laundry", title: "Wash shared towels", category: "Laundry", frequency: "WEEKLY",
      description: "Wash and fold kitchen and bathroom towels." },
    { key: "plants", title: "Water the plants", category: "Outdoor", frequency: "WEEKLY",
      description: "Water indoor and patio plants." }
  ].freeze

  def self.template(key)
    TEMPLATES.find { |template| template[:key] == key }
  end

  belongs_to :household
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id
  has_many :chore_assignments, dependent: :delete_all
  has_many :assignees, through: :chore_assignments, source: :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :frequency, inclusion: { in: FREQUENCIES }
  validates :category, inclusion: { in: CATEGORIES }

  def self.category_icon(category)
    CATEGORY_DETAILS.dig(category, :icon)
  end

  def self.category_hint(category)
    CATEGORY_DETAILS.dig(category, :hint)
  end

  # Next scheduled date on or after today; one-off chores keep their original due date.
  def next_due_at(now = Time.current)
    return due_at if due_at.blank? || frequency == "NONE"

    start_of_day = now.beginning_of_day
    return due_at if due_at >= start_of_day

    index = case frequency
    when "DAILY" then ((start_of_day - due_at) / 1.day).ceil
    when "WEEKLY" then ((start_of_day - due_at) / 1.week).ceil
    else (now.year * 12 + now.month) - (due_at.year * 12 + due_at.month)
    end
    index += 1 while occurrence_at(index) < start_of_day
    occurrence_at(index)
  end

  def due_status(now = Time.current)
    upcoming = next_due_at(now)
    return :unscheduled if upcoming.blank?
    return :today if upcoming.to_date == now.to_date
    return :overdue if upcoming < now
    return :soon if upcoming <= now + 7.days

    :later
  end

  private

  def occurrence_at(index)
    case frequency
    when "DAILY" then due_at + index.days
    when "WEEKLY" then due_at + index.weeks
    else due_at + index.months
    end
  end
end
