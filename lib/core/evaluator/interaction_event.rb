module Core
  module Evaluator
    class InteractionEvent

      def self.load_all path
        event_doc = File.open(path, "rb:UTF-8")
        events = event_doc.map { |line| details = line.chomp.split(','); details[0] = details[0].to_sym; InteractionEvent.new details }
      end

      def self.parameter_cut string
        string.split(':')
      end

      def initialize details
        @type = details[0]
        @id = details[1]
        @time = DateTime.parse details[2]
        @other = details.drop 3
      end

      def members
        [@id].concat @other
      end

      def matches event_prescription
        param_dict = Hash.new

        if @type != event_prescription.type
          return false
        end

        if members.count != event_prescription.members.count
          return false
        end

        presc_members = event_prescription.members
        members.each_with_index do |m, index|
          my_param_cut = InteractionEvent.parameter_cut m
          ye_param_cut = InteractionEvent.parameter_cut presc_members[index]
          if my_param_cut[0] != ye_param_cut[0] || my_param_cut.count != ye_param_cut.count
            return false
          end
          if my_param_cut.count > 1
            if param_dict.has_key? ye_param_cut[1]
              if param_dict[ye_param_cut[1]] != my_param_cut[1]
                return false
              end
            else
              param_dict[ye_param_cut[1]] = my_param_cut[1]
            end
          end
        end

        @parameter_dictionary = param_dict
        true
      end

      def equals event_prescription, param_dict
        if @type != event_prescription.type
          return false
        end

        if members.count != event_prescription.members.count
          return false
        end

        presc_members = event_prescription.members
        members.each_with_index do |m, index|
          my_param_cut = InteractionEvent.parameter_cut m
          ye_param_cut = InteractionEvent.parameter_cut presc_members[index]
          if my_param_cut[0] != ye_param_cut[0] || my_param_cut.count != ye_param_cut.count
            return false
          end
          if my_param_cut.count > 1
            if param_dict[ye_param_cut[1]] != my_param_cut[1]
              return false
            end
          end
        end

        true
      end

      attr_accessor :type, :parameter_dictionary

    end
  end
end