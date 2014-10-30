# encoding: utf-8
require 'nokogiri'
module Core
  module Parser
    module UXF
      def parse path
        doc = Nokogiri::XML(File.open path)

      end
    end
  end
end
