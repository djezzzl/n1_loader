# frozen_string_literal: true

module N1Loader
  # Add support of question mark names
  module Name
    def n1_loader_name(name)
      to_sym = name.is_a?(Symbol)

      converted = name.to_s.gsub("?", "_question_mark")

      to_sym ? converted.to_sym : converted
    end
  end
end
