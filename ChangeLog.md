Changes
--------------------------------------------------------------------------------

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
