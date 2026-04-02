nag, a bash script for setting one-off or repeating alarms

```text
Usage:
  nag                                     list all alarms
  nag <time> <message...>                 one-shot alarm
  nag every <rules> <time> <message...>   repeating alarm
  nag stop <id|tag>                       delete alarm(s)
  nag skip <id|tag>                       skip next occurrence(s)
  nag tag <id> <tags...>                  add tags to an alarm
  nag tag <tag>                           list alarms with a tag
  nag untag <id> <tags...>                remove tags from an alarm
  nag check                               check and fire due alarms
  nag mute                                mute alarm sounds
  nag unmute                              unmute alarm sounds
  nag edit                                edit alarms file directly
  nag help [<subcommand>]                 show help
  nag version                             show version

Options:
  -e  Edit alarms file directly.
  -f  Skip all prompts.
  -v  Show version.

Environment:
  NAG_DIR    Alarm storage directory (default: ~/.local/share/nag)
  NAG_CMD    Notification command (default: notify-send)
  NAG_SOUND  Sound file to play (default: freedesktop bell sound)
```

### Help

<p>
  <sup>
    <a href="#installation">↑</a>
  </sup>
</p>

<div align="center">
  <a href="#nag-list"><code>list</code></a>&nbsp;·
  <a href="#nag-at"><code>at</code></a>&nbsp;·
  <a href="#nag-every"><code>every</code></a>&nbsp;·
  <a href="#nag-stop"><code>stop</code></a>&nbsp;·
  <a href="#nag-skip"><code>skip</code></a>&nbsp;·
  <a href="#nag-tag"><code>tag</code></a>&nbsp;·
  <a href="#nag-untag"><code>untag</code></a>&nbsp;·
  <a href="#nag-check"><code>check</code></a>&nbsp;·
  <a href="#nag-mute"><code>mute</code></a>&nbsp;·
  <a href="#nag-unmute"><code>unmute</code></a>&nbsp;·
  <a href="#nag-edit"><code>edit</code></a>&nbsp;·
  <a href="#nag-help"><code>help</code></a>&nbsp;·
  <a href="#nag-version"><code>version</code></a>
</div>

#### `nag list`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag list

Description:
  List all alarms. This is the default when no subcommand is given.
```

#### `nag at`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag [at] <time> <message...>

Description:
  Create a one-shot alarm. The "at" is optional. If the first argument
  doesn't match any other subcommand of nag, it'll fallback to "at".

Examples:
  nag 3pm take a break
  nag at 3pm take a break
  nag "tomorrow 9am" dentist appointment
```

#### `nag every`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag every <rules> <time> <message...>

Description:
  Create a repeating alarm. Rules are comma-separated and case-insensitive.

Rules (and aliases):
  hour    (h, hourly)    monday    (mon, mondays)
  day     (d, daily)     tuesday   (tue, tuesdays)
  week    (weekly)       wednesday (wed, wednesdays)
  month   (monthly)      thursday  (thurs, thursdays)
  year    (yearly)       friday    (fri, fridays)
  weekday (weekdays)     saturday  (sat, saturdays)
  weekend (weekends)     sunday    (sun, sundays)

Examples:
  nag every weekday 9am standup meeting
  nag every tue,thu 3pm team sync
  nag every year "December 25" Christmas
```

#### `nag stop`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag stop <id|tag>

Description:
  Stop an alarm by ID, or stop all alarms with a tag (requires -f).
```

#### `nag skip`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag skip <id|tag>

Description:
  Skip the next occurrence of a repeating alarm (reschedule without firing).
  For one-shot alarms, this deletes them. With a tag, applies to all
  matching alarms (requires -f).
```

#### `nag tag`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag tag <id> <tags...>    add tags to an alarm
  nag tag <tag>             list alarms with a tag

Description:
  Add tags to an alarm by ID, or list all alarms matching a tag.
  Tags must not be pure integers.
```

#### `nag untag`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag untag <id> <tags...>

Description:
  Remove one or more tags from an alarm.
```

#### `nag check`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag check

Description:
  Check for due alarms and fire them. Run automatically by a systemd
  timer (every 15s) or cron (every 60s). Repeating alarms are
  rescheduled. One-shot alarms are removed. Stale alarms older than
  15 minutes are silently dropped or rescheduled without firing.
```

#### `nag mute`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag mute [<tag>]

Description:
  Mute alarm sounds. With no argument, mutes all alarms globally.
  With a tag, mutes only alarms with that tag.
```

#### `nag unmute`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag unmute [<tag>]

Description:
  Unmute alarm sounds. With no argument, unmutes everything.
  With a tag, unmutes only that tag.
```

#### `nag edit`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag ( edit | -e )

Description:
  Open the alarms file in $EDITOR (falls back to $VISUAL, then vi).
```

#### `nag help`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag help [<subcommand>]

Description:
  Display help information for nag or a specified subcommand.
```

#### `nag version`

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

```text
Usage:
  nag ( version | -v )

Description:
  Display the current program version.
```

### License

<p>
  <sup>
    <a href="#help">↑</a>
  </sup>
</p>

MIT - see [LICENSE](LICENSE).
