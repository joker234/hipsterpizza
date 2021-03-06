# encoding: utf-8

class Order < ActiveRecord::Base
  extend FriendlyId
  friendly_id :uuid

  belongs_to :basket, touch: true

  validates :uuid, presence: true, uniqueness: true
  validates :json, presence: true, json: true
  validates :nick, presence: true
  validates :basket_id, presence: true

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where(paid: false) }
  scope :sorted, -> { order('lower(nick) asc') }

  before_validation(on: :create) do
    create_uuid
  end

  def json_parsed
    ActiveSupport::JSON.decode(json)
  end

  def sum
    json_parsed.map { |i| i['price'] }.sum
  end

  def sum_with_tip
    # gets 'tip_percent' from the config and prevents negative values
    tip_percent = [0, CONFIG['tip_percent'].to_i].max
    # round to nearest 10 cents
    (sum * (tip_percent / 100.0 + 1)).round(1)
  end

  def nick_id
    n = UnicodeUtils.canonical_decomposition(nick)
    n = n.gsub(/[^a-z0-9]/i, '').upcase[0..2]
    n[1] ||= '~'
    n[2] ||= '~'
    n
  end

  # returns the date the order was actually submitted, i.e. the basket
  # submit time.
  def date
    basket.submitted.strftime('%Y-%m-%d') rescue I18n.t('time.never')
  end

  private

  def create_uuid
    raise 'Order has already an UUID' if uuid
    other = Order.pluck(:uuid)
    2.times do
      self.uuid = SecureRandom.uuid
      break unless other.include?(uuid)
    end
  end
end
