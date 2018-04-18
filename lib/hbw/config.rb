module HBW
  class Config
    def initialize
      @notice_only_api_key = nil
    end
    attr_accessor :notice_only_api_key
  end
end
