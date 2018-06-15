$kso_debug = true

module Kernel
  # :nodoc:
  def klog(*args)
    puts *args if $kso_debug
  end
end

require_relative 'api/common'
require_relative 'api/js_api'
require_relative 'view'
require_relative 'web'
