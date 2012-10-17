shared_context :acceptance_client do
  Given(:server) { "127.0.0.1:61613" }
  Given(:credentials) { %w(admin password) }
  Given(:options) { Hash[*%w(login passcode).zip(credentials).flatten] }
  Given(:clients) { [] }
  Given(:klomp) { Klomp.new(server, options).tap {|l| clients << l } }

  after { clients.each(&:disconnect) }
end
