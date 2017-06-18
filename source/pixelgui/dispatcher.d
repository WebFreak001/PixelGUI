module pixelgui.dispatcher;

import std.datetime;

///
struct Dispatcher
{
	void tick()
	{
		void delegate()[] toCall;
		foreach_reverse (i, ref timeout; timeouts)
		{
			if (timeout.sw.peek.to!("msecs", int) >= timeout.ms)
			{
				toCall ~= timeout.callback;
				if (timeout.repeat)
				{
					timeout.sw.stop();
					timeout.sw.reset();
					timeout.sw.start();
				}
				else
				{
					timeouts[i] = timeouts[$ - 1];
					timeouts.length--;
					continue;
				}
			}
		}
		foreach (fn; toCall)
			fn();
	}

	private TimeoutInfo[] timeouts;
}

private struct TimeoutInfo
{
	int id;
	StopWatch sw;
	int ms;
	void delegate() callback;
	bool repeat;
}

/// Current thread dispatcher
Dispatcher dispatcher;

private int currentTimeout;
/// Synchronously runs a delayed task
int setTimeout(void delegate() callback, int ms, bool repeat = false)
{
	++currentTimeout;
	TimeoutInfo info;
	info.id = currentTimeout;
	info.sw.start();
	info.ms = ms;
	info.callback = callback;
	info.repeat = repeat;
	dispatcher.timeouts ~= info;
	return currentTimeout;
}

/// Synchronously runs a repeating delayed task
int setInterval(void delegate() callback, int ms)
{
	return setTimeout(callback, ms, true);
}

/// Removes a scheduled task
bool clearTimeout(int id)
{
	foreach (i, ref timeout; dispatcher.timeouts)
	{
		if (timeout.id == id)
		{
			dispatcher.timeouts[i] = dispatcher.timeouts[$ - 1];
			dispatcher.timeouts.length--;
			return true;
		}
	}
	return false;
}

/// ditto
alias clearInterval = clearTimeout;
