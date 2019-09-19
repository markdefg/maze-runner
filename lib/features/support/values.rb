# Provides a hash to store values for cross-request comparisons
class Store
  class << self
    # Returns the hash of stored values for the current scenario
    #
    # @return [Hash] The stored value hash
    def values
      @values ||= {}
    end
  end
end

# Before each test
Before do
  Store.values.clear
end