# frozen_string_literal: true

# Graphs activities by month

module Friends
  class Graph
    DATE_FORMAT = "%b %Y".freeze
    SCALED_SIZE = 20

    # @param filtered_activities [Array<Friends::Activity>] a list of activities to highlight in
    #   the graph (may be the same as `all_activities`)
    # @param all_activities [Array<Friends::Activity>] a list of activities to graph
    # @param unscaled [Boolean] true iff we should show the absolute size of bars in the graph
    #   rather than a scaled version
    def initialize(filtered_activities:, all_activities:, unscaled:)
      @filtered_activities = filtered_activities
      @all_activities = all_activities
      @unscaled = unscaled

      return if @all_activities.empty?

      @start_date = @all_activities.last.date
      @end_date = @all_activities.first.date
    end

    # @return [Array<String>] the output to print, with colors
    def output
      hash = to_h
      global_total = hash.max_by { |_, (_, val)| val }.last.last unless @unscaled || hash.empty?

      hash.map do |month, (filtered_count, total_count)|
        unless @unscaled
          # We want to use rationals for math so we can round up as well
          # as down (instead of int division), for more accurate graphing.
          # Floats are less trustworthy and could give results < 0 or > total_count
          filtered_count = Rational(filtered_count * SCALED_SIZE, global_total).round
          total_count = SCALED_SIZE
        end

        str = "#{month} |"
        str += Array.new(filtered_count) do |count|
          Paint["█", color(count)]
        end.join
        if total_count > filtered_count
          str += Array.new(total_count - filtered_count) do |count|
            Paint["∙", color(filtered_count + count)]
          end.join + Paint["|", color(total_count + 1)]
        end

        str
      end.reverse!
    end

    private

    # Render the graph as a hash in the format:
    #
    #   {
    #     "Jan 2015" => [3, 4], # [# filtered activities, # total activities]
    #     "Feb 2015" => [0, 0],
    #     "Mar 2015" => [0, 9]
    #   }
    #
    # @return [Hash{String => Integer}]
    def to_h
      empty_graph.tap do |graph|
        @filtered_activities.each do |activity|
          graph[format_date(activity.date)][0] += 1
        end
        @all_activities.each do |activity|
          graph[format_date(activity.date)][1] += 1
        end
      end
    end

    # Render an empty graph as a hash in the format:
    #
    #   {
    #     "Jan 2015" => [0, 0] # [# filtered activities, # total activities]
    #     "Feb 2015" => [0, 0]
    #     "Mar 2015" => [0, 0]
    #   }
    #
    # @return [Hash{String => Integer}]
    def empty_graph
      Hash[(@start_date && @end_date ? (@start_date..@end_date) : []).map do |date|
        [format_date(date), [0, 0]]
      end]
    end

    # Format a date for use in the graph label
    # @param date [Date] the date to format
    # @return [String]
    def format_date(date)
      date.strftime(DATE_FORMAT)
    end

    # @param x_coord [Integer] the x coordinate we want to color; x >= 0
    # @return [Array<Integer>] the color we should use to paint
    #   a point on the graph at the given x coordinate
    def color(x_coord)
      COLORS[x_coord % COLORS.size]
    end

    # Originally generated by executing the code in Minitest's Pride plugin (the PrideLOL class),
    # and then pulling the unique values out and doubling them to create a more even distribution
    # of colors.
    COLORS = [
      [153, 255, 0], [153, 255, 0],
      [153, 204, 0], [153, 204, 0],
      [204, 204, 0], [204, 204, 0],
      [255, 153, 0], [255, 153, 0],
      [255, 102, 0], [255, 102, 0],
      [255, 51, 51], [255, 51, 51],
      [255, 0, 102], [255, 0, 102],
      [255, 0, 153], [255, 0, 153],
      [204, 0, 204], [204, 0, 204],
      [153, 0, 255], [153, 0, 255],
      [102, 0, 255], [102, 0, 255],
      [51, 51, 255], [51, 51, 255],
      [0, 102, 255], [0, 102, 255],
      [0, 153, 255], [0, 153, 255],
      [0, 204, 204], [0, 204, 204],
      [0, 255, 153], [0, 255, 153],
      [0, 255, 102], [0, 255, 102],
      [51, 255, 51], [51, 255, 51],
      [102, 255, 0], [102, 255, 0]
    ].freeze
    private_constant :COLORS
  end
end
