class ItemDecorator < ApplicationDecorator
  delegate_all

  # change that
  alias_method :source, :model

  def link_to_item
    h.link_to thread_url, target: "_blank" do
      item_name = h.content_tag :span, source.name, class: rarity_name
      item_name << " " << source.base_name if source.name != source.base_name
      item_name
    end
  end

  def properties
    props = case source.archetype
    when 0; weapon_stats
    when 1; armour_stats
    when 2; misc_stats
    end.to_a

    props.concat(stats.select(&:hidden).map { |s| [s.name, s.value, s.mod_id] })
    props.delete_if { |stat| !stat || stat[1] == 0 }
    props
  end

  def level
    h.content_tag :span, data: { sort: :level } do
      "#{ source.item_type ==  "Map" ? "Level" : "Requires level" } #{source.level.to_i}"
    end
  end

  def requirement_list
    reqs = [source.league_name.try(:capitalize)]
    reqs << level if source.level.to_i > 0

    reqs << ["str", "dex", "int"].map do |stat|
      value = source.send(stat.to_sym)
      h.content_tag(:span, class: stat) do
        value.to_s << " #{stat.capitalize}"
      end if value && value > 0
    end.compact.join(", ")

    reqs << quality
    reqs.delete_if{|r|r.blank?}.join(" &mdash; ").html_safe
  end

  def online_status
    h.content_tag :span, class: "online-status" do
      h.link_to(h.account_path(source.account),
        class: "account",
          data: { account: source.account }) do
        h.content_tag(:i, "", class: "fa fa-circle-o online-icon") + \
        h.content_tag(:span, source.account)
      end
    end.html_safe
  end

  def quality
    h.content_tag :span, data: { sort: :quality } do
      "<b>+#{source.quality.to_i}%</b> Quality".html_safe
    end
  end

  def indexed_at
    "<i class='fa fa-clock-o'></i> #{h.content_tag(:time, source.indexed_at, datetime: source.indexed_at)}".html_safe
  end

  def buy_button
    h.link_to thread_url, class: "btn btn-success", target: "_blank" do
      h.content_tag(:i, "", class: "fa-thumbs-up fa-white") + \
      " Buy now"
    end
  end

  def pm_button
    h.link_to "#", class: "send-pm btn #{button_size_class}" do
      'PM <i class="fa fa-comments-o"></i>'.html_safe
    end
  end

  def price_button
    return "".html_safe unless (price = source.price.try(:to_hash)).present?
    orb = price.keys.first

    h.link_to "#",
    class: "btn #{button_size_class} ttip price",
      data: { container: "body" },
      title: "Item b/o" do
        "#{price[orb]} x <span class='orb #{orb}'>#{orb}</span>".html_safe
      end
  end

  def verify_button
    h.link_to h.verify_item_path(source.id),
    class: "btn btn-warning #{button_size_class} ttip verify",
      title: "Verify this item",
      data: { placement: "top", container: "body" } do
        h.concat h.content_tag(:i, "", class: "fa fa-check")
      end
  end

  def skill?
    source.item_type == "Skill"
  end

  def size
    @_size ||= context.fetch(:size, :small)
  end

  def link_to_item_view
    h.link_to h.item_path(source.id), class: "", target: "_blank" do
      "<i class='fa fa-adjust'></i> Find similar items".html_safe
    end
  end

  #######
  private

  def button_size_class
    return "btn-#{size}" if button_sizes.include?(size)
  end

  def button_sizes
    [:small, :mini]
  end

  ## These values depend on ItemSorting values

  def weapon_stats
    [
      ["DPS", source.dps.to_i, :dps],
      ["pDPS", source.physical_dps.to_i, :physical_dps],
      ["APS", source.aps.to_f, :aps]
    ].concat(weapon_and_misc_stats)
  end

  def weapon_and_misc_stats
    [
      ["Physical dmg", displayed_physical_damage, :physical_damage],
      ["Elemental dmg", source.elemental_damage.to_i, :elemental_damage],
      ["CS chance", source.critical_strike_chance.to_f, :critical_strike_chance]
    ]
  end

  def armour_stats
    [
      ["Evasion",          source.evasion.to_i, :evasion],
      ["Armour",            source.armour.to_i, :armour],
      ["ES",                source.energy_shield.to_i, :energy_shield],
      ["% Chance to block", source.block_chance.to_i, :block_chance]
    ]
  end

  def misc_stats
    weapon_and_misc_stats
  end

  def displayed_physical_damage
    if source.raw_physical_damage.present?
      "#{source.raw_physical_damage} (#{source.physical_damage})"
    else
      source.physical_damage.to_i
    end
  end

  def thread_url
    @_url ||= ForumThreadHtml.url(source.thread_id)
  end

  def rarity_name
    source.rarity_name.downcase
  end
end
