nag, a bash script for setting one-off or repeating alarms with natural language

`nag` typically requires a cron daemon or systemd-timer to be available. On the first alarm set, `nag` will prompt to install whichever is relevant for your system. The timer will then invoke `nag check` on an interval, which checks for alarms that are due to go off, and triggers them as appropritate. By default `notify-send` is used, but the command triggered can be overriden with `NAG_CMD` to anything you like.

`nag` attempts to use something close to natural language. You can `nag [at] 2pm` for a one-off alarm at 2pm, or `nag every 2pm` for an alarm every 2pm. To delete an alarm, `nag stop` it, or to just skip one instance `nag skip`. If it's a one-off alarm being skipped, that's the same as just stopping it. If you want to keep an alarm from triggering for a duration, like during a week off, you can `nag snooze` it; that'll stop it triggering entirely. For just silencing the sound, `nag mute` instead.

Alarms can be tagged with `nag tag <id> <tags...>`, and all alarms of a tag can be listed with `nag tag <tag>`. When you `stop`, `skip`, `snooze`, or `mute` an alarm, you can either operate on `all` alarms, a specific id, or a specific tag. For example, `nag snooze work "until next Tuesday"`, or `nag mute all`.

`un-` commands work with all of the above. You can `nag unskip` a skipped alarm to bring it back to the next date. For example, if you skip your Friday alarm by mistake, `nag unskip` will find the next Friday and set the next expiration to whenever that is.

Time parsing is done with `date -d`, so it supports a decent array of formats:
- Times of day (15:30, 3:30pm, 3pm, noon, teatime)
- Calendar dates (2025-12-25, 25 Dec 2025, Dec 25)
- Combined (tomorrow 9am, next monday 15:30)
- Relative days (now, today, tomorrow, next week)
- Relative times (+1 hour, 30 minutes, +1 day)
- Ordinal dates (first monday, third friday of next month)
- Time zones (15:30 UTC, 3pm PST)
- ISO 8601 (2025-12-25T15:30:00)
- Epoch (@1735138200)

Rules for `nag every` are:
- hourly (h, hr, hours, hourly)
- daily (d, days, daily)
- weekly (week, weekly)
- monthly (month, months, monthly)
- yearly (year, years, yearly)
- weekday (weekday, weekdays)
- weekend (weekend, weekends)
- specific weekdays (mon, monday, mondays, etc.)

e.g. `nag every weekday midday "Take a break for dinner."`

```text
Usage:
  nag                                     list all alarms
  nag <time> <message...>                 one-shot alarm
  nag every <rules> <time> <message...>   repeating alarm
  nag stop <all|id|tag>                   delete alarm(s)
  nag skip <all|id|tag>                   skip next occurrence(s)
  nag unskip <all|id|tag>                 reset to next occurrence
  nag tag <id> <tags...>                  add tags to an alarm
  nag tag <tag>                           list alarms with a tag
  nag untag <id> <tags...>                remove tags from an alarm
  nag snooze <all|id|tag> [<duration>]    snooze alarms
  nag unsnooze <all|id|tag>               unsnooze alarms
  nag check                               check and fire due alarms
  nag mute <all|tag>                      mute alarm sounds
  nag unmute <all|tag>                    unmute alarm sounds
  nag edit                                edit alarms file directly
  nag help [<subcommand>]                 show help
  nag version                             show version

Options:
  -e         Edit alarms file directly.
  -f         Skip all prompts.
  --iso      Show times as YYYY-MM-DD HH:MM:SS.
  --epoch    Show times as unix timestamps.
  -v         Show version.

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
  Stop an alarm by ID, or stop all alarms with a tag.
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
  matching alarms.
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
