Klomp Changes
--------------------------------------------------------------------------------

1.0.2 (2012/10/10)
================================================================================

- Frames now respond to `#[]` and `#[]=` (for header access) and `#body=` (for
  setting body after construction)
- Configurable foreground IO.select timeout through `options['select_timeout']`
- Add logging of read frames and exceptions when going offline

1.0.1 (2012/10/5)
================================================================================

- Make publish, subscribe, and unsubscribe methods behave like Klomp 0.0.x where
  the return value is the frame object(s) that was created by the operation.

1.0.0 (2012/10/3)
================================================================================

- BREAKING CHANGES from previous release. You will need to revisit and change
  all code that depends on Klomp 0.0.x
- ground-up rewrite to eliminate onstomp dependency
- Klomp::Client => Klomp
- preserves similar API but with fewer bells and whistles
- read latest README.md for details

0.0.8 (2012/8/15)
================================================================================

- add support for specifying vhost at client creation

0.0.7 (2012/8/15)
================================================================================

- back out the stomp/onstomp adapter code. we'll revisit this later

0.0.6 (2012/8/10)
================================================================================

- don't blow up if stomp is not installed

0.0.5 (2012/8/10)
================================================================================

- set message send/receive logging to debug instead of info
- add ability to switch between the stomp and onstomp adapters

0.0.4 (2012/6/22)
================================================================================

- Add fibonacci-based retry/reconnect back-off logic
- Add generated UUID message IDs to every message (and log them)

0.0.3 (2012/6/21)
================================================================================

- Upgraded to work with onstomp 1.0.7
- Fix unsubscribe to accept array of frames that subscribe returns

0.0.2 (2012/06/15)
================================================================================

- Add `:logger` option to log sending and receiving of messages
- Duck-type with `#to_json` for `:translate_json` option
- Clean up options parsing, pass all options through to OnStomp client config
- Clamp onstomp gem dependency version to 1.0.x

0.0.1 (2012/06/08)
================================================================================

- Initial release
