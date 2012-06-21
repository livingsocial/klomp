trap("QUIT") do
  $stderr.puts "\n\nThread dump:\n"
  Thread.list.each do |t|
    $stderr.puts t.inspect
    $stderr.puts *t.backtrace
    $stderr.puts
  end
end
