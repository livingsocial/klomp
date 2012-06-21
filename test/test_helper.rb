trap("QUIT") do
  $stderr.puts "\n\nThread dump:\n"
  Thread.list.each do |t|
    $stderr.puts t.inspect
    $stderr.puts *t.backtrace
    $stderr.puts
  end
end

module KlompTestHelpers
  def let_background_processor_run
    sleep 1
  end
end
