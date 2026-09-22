// Mark cards whose hostname is exposed to the internet via the Cloudflare
// tunnel (everything else on *.bjelke.org is tailnet-only). Homepage doesn't
// give service cards ids, so match by link hostname and re-apply on React
// re-renders via a MutationObserver.
(() => {
  const EXPOSED = new Set([
    "resume.bjelke.org",
    "skysend.bjelke.org",
    "feeds.bjelke.org",
    // /share pages only, via the share.bjelke.org gate — the app itself stays tailnet-only
    "docmost.bjelke.org",
  ]);

  const mark = () => {
    document.querySelectorAll(".service-card a[href]").forEach((a) => {
      let host;
      try {
        host = new URL(a.href).hostname;
      } catch {
        return;
      }
      if (!EXPOSED.has(host)) return;
      const card = a.closest(".service-card");
      if (!card || card.classList.contains("exposed")) return;
      card.classList.add("exposed");
      const badge = document.createElement("span");
      badge.className = "exposed-badge";
      badge.textContent = "🌐 public";
      badge.title = "Reachable from the internet (Cloudflare tunnel)";
      card.appendChild(badge);
    });
  };

  new MutationObserver(mark).observe(document.body, {
    childList: true,
    subtree: true,
  });
  mark();
})();

// Calendar as a modal. The "Calendar" group is rendered on every tab (no `tab:`
// in settings.yaml) but hidden by custom.css; clicking the date in the header
// toggles `.calendar-open` on <body>, which reveals it as a centred panel.
// Nothing is moved in the DOM — React owns those nodes, we only add classes.
(() => {
  const GROUP = "Calendar";
  const OPEN = "calendar-open";

  // Clicking a day is Homepage's own behaviour (onClick -> setShowDate) and it
  // already renders that day's events in a strip under the grid, so there is no
  // JS here for the day list at all — custom.css just moves that strip into a
  // second column beside the calendar.
  const close = () => document.body.classList.remove(OPEN);

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") close();
  });

  // The dimmer is a CSS pseudo-element, so it can't take its own listener.
  // Clicks on it land on #layout-groups; anything outside the panel closes.
  document.addEventListener(
    "click",
    (e) => {
      if (!document.body.classList.contains(OPEN)) return;
      if (!(e.target instanceof Element)) return;
      if (e.target.closest(".calendar-modal")) return;
      if (e.target.closest(".information-widget-datetime")) return;
      close();
    },
    true,
  );

  const wire = () => {
    document.querySelectorAll(".services-group").forEach((group) => {
      const name = group.querySelector(".service-group-name");
      if (name && name.textContent.trim() === GROUP) {
        group.classList.add("calendar-modal");
      }
    });

    document.querySelectorAll(".information-widget-datetime").forEach((el) => {
      if (el.dataset.calendarTrigger) return;
      el.dataset.calendarTrigger = "1";
      el.title = "Open calendar";
      el.addEventListener("click", (e) => {
        e.stopPropagation();
        document.body.classList.toggle(OPEN);
      });
    });
  };

  // Only childList/subtree — class changes aren't observed, so adding
  // .calendar-modal here can't retrigger this observer.
  new MutationObserver(wire).observe(document.body, {
    childList: true,
    subtree: true,
  });
  wire();
})();

// Temperature row under the Server / NAS info widgets. A host-side timer
// (temps-publish.timer) writes /images/temps.json — the stock widgets can't
// show per-disk temps, and the browser can't reach the TrueNAS API (LAN-only,
// and the key must stay server-side). The two widgets render different
// markup (only glances gets information-widget-* classes), so anchor on the
// label text from widgets.yaml instead of widget root classes.
(() => {
  const SRC = "/images/temps.json";
  const REFRESH_MS = 10_000;
  const STALE_MS = 10 * 60 * 1000;
  let data = null;

  const short = (name) => (name === "/mnt/storage" ? "storage" : name);

  const entries = (labelText) => {
    if (labelText === "Server") {
      const cpu = data.server?.cpu ? [{ ...data.server.cpu, name: "CPU" }] : [];
      return cpu.concat(data.server?.disks ?? []);
    }
    if (labelText === "NAS") return data.nas?.disks ?? [];
    return [];
  };

  const render = () => {
    const stale = !data || Date.now() - data.updated * 1000 > STALE_MS;
    document
      .querySelectorAll("div.pt-1.text-center.text-xs:not(.temps-line)")
      .forEach((label) => {
        const name = label.textContent.trim();
        if (name !== "Server" && name !== "NAS") return;
        // Tag the widget roots so custom.css can grid-place them on phones.
        // Attribute changes aren't observed (childList only), so no feedback
        // loop; a React remount re-triggers via childList and re-tags.
        label.parentElement?.classList.add(
          name === "NAS" ? "nas-widget" : "server-widget",
        );
        const next = label.nextElementSibling;
        const row = next?.classList.contains("temps-line") ? next : null;
        const parts = stale ? [] : entries(name);
        if (!parts.length) {
          row?.remove();
          return;
        }
        const sig = parts.map((p) => `${p.name}:${p.temp}`).join(",");
        // Only touch the DOM on change — the MutationObserver below watches
        // the whole body, so an unconditional rewrite would loop forever.
        if (row && row.dataset.sig === sig) return;
        const line = row ?? document.createElement("div");
        line.className = `temps-line ${label.className}`;
        line.dataset.sig = sig;
        line.replaceChildren(
          ...parts.flatMap((p, i) => {
            const span = document.createElement("span");
            span.textContent = `${short(p.name)} ${Math.round(p.temp)}°`;
            if (p.warn && p.temp >= p.warn) span.classList.add("temp-hot");
            return i ? [document.createTextNode(" · "), span] : [span];
          }),
        );
        if (!row) label.after(line);
      });
  };

  const refresh = async () => {
    try {
      // The timestamp also bypasses PWA/reverse-proxy caches that may ignore
      // fetch's cache mode for a static file.
      const resp = await fetch(`${SRC}?updated=${Date.now()}`, {
        cache: "no-store",
      });
      if (resp.ok) data = await resp.json();
    } catch {
      // keep the previous data; staleness handling hides it eventually
    }
    render();
  };

  new MutationObserver(render).observe(document.body, {
    childList: true,
    subtree: true,
  });
  refresh();
  setInterval(refresh, REFRESH_MS);
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden) refresh();
  });
})();

// When running as an installed PWA (Chrome "install as app"), open links in
// the app window instead of popping out to the browser. Regular browser tabs
// (e.g. on the phone) keep Homepage's default target=_blank behaviour.
(() => {
  if (!window.matchMedia("(display-mode: standalone)").matches) return;

  const retarget = () => {
    document.querySelectorAll('a[target="_blank"]').forEach((a) => {
      a.target = "_self";
    });
  };

  new MutationObserver(retarget).observe(document.body, {
    childList: true,
    subtree: true,
  });
  retarget();
})();

// Notification centre. Every homelab publisher already writes to the local
// ntfy topics below before ~/ops/ntfy-pushover-forwarder.py mirrors the same
// event to Pushover. Reading ntfy here therefore shows the Pushover feed
// without exposing Pushover credentials or registering another client.
(() => {
  const NTFY_BASE = "https://ntfy.bjelke.org/alerts,downloads";
  const HISTORY_WINDOW = "168h";
  const MAX_RENDERED = 100;
  const LAST_SEEN_KEY = "homepage-notifications-last-seen";
  const READ_IDS_KEY = "homepage-notifications-read-ids";
  const BUTTON_ID = "notification-centre-button";
  const DRAWER_ID = "notification-centre-drawer";
  const TOAST_ID = "notification-centre-toast";
  const OPEN = "notification-centre-open";

  const messages = new Map();
  let filter = "all";
  let loading = true;
  let loadError = false;
  let eventSource;
  let toastTimer;

  const readLastSeen = () => {
    const value = Number.parseInt(localStorage.getItem(LAST_SEEN_KEY) ?? "0", 10);
    return Number.isFinite(value) ? value : 0;
  };

  const readMessageIds = () => {
    try {
      const value = JSON.parse(localStorage.getItem(READ_IDS_KEY) ?? "[]");
      return new Set(Array.isArray(value) ? value.map(String) : []);
    } catch {
      return new Set();
    }
  };

  const isUnread = (message) =>
    message.time > readLastSeen() && !readMessageIds().has(message.id);

  const showToast = (text) => {
    let toast = document.querySelector(`#${TOAST_ID}`);
    if (!toast) {
      toast = document.createElement("div");
      toast.id = TOAST_ID;
      toast.className = "notification-centre-toast";
      toast.setAttribute("role", "status");
      toast.setAttribute("aria-live", "polite");
      document.body.append(toast);
    }
    toast.textContent = text;
    toast.classList.remove("visible");
    requestAnimationFrame(() => toast.classList.add("visible"));
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => toast.classList.remove("visible"), 2200);
  };

  const markAllRead = () => {
    localStorage.setItem(LAST_SEEN_KEY, String(Math.floor(Date.now() / 1000)));
    localStorage.removeItem(READ_IDS_KEY);
    updateBadge();
    render();
    showToast("All notifications marked as read");
  };

  const markMessageRead = (message, item) => {
    if (!isUnread(message)) return;
    const ids = readMessageIds();
    ids.add(message.id);
    localStorage.setItem(READ_IDS_KEY, JSON.stringify([...ids].slice(-500)));
    item.classList.remove("unread");
    updateBadge();
  };

  const relativeTime = (timestamp) => {
    const seconds = Math.max(0, Math.floor(Date.now() / 1000) - timestamp);
    if (seconds < 60) return "just now";
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
    return new Intl.DateTimeFormat(undefined, {
      month: "short",
      day: "numeric",
    }).format(new Date(timestamp * 1000));
  };

  const safeLink = (value) => {
    if (!value) return null;
    try {
      const url = new URL(value);
      return url.protocol === "https:" || url.protocol === "http:"
        ? url.href
        : null;
    } catch {
      return null;
    }
  };

  const normalise = (value) => {
    if (!value || value.event !== "message" || !value.id || !value.time) {
      return null;
    }
    return {
      id: String(value.id),
      time: Number(value.time),
      topic: value.topic === "downloads" ? "downloads" : "alerts",
      title: String(value.title || value.topic || "Notification"),
      message: String(value.message || ""),
      priority: Number(value.priority || 3),
      icon: safeLink(value.icon),
      click: safeLink(value.click),
    };
  };

  const addMessage = (value) => {
    const message = normalise(value);
    if (!message) return false;
    messages.set(message.id, message);
    return true;
  };

  const sortedMessages = () =>
    [...messages.values()]
      .filter((message) => filter === "all" || message.topic === filter)
      .sort((left, right) => right.time - left.time)
      .slice(0, MAX_RENDERED);

  const createIcon = (message) => {
    if (message.icon) {
      const image = document.createElement("img");
      image.className = "notification-centre-icon";
      image.src = message.icon;
      image.alt = "";
      image.loading = "lazy";
      return image;
    }

    const fallback = document.createElement("span");
    fallback.className = `notification-centre-icon notification-centre-icon-fallback ${message.topic}`;
    fallback.textContent = message.topic === "downloads" ? "↓" : "!";
    return fallback;
  };

  const createMessage = (message) => {
    const item = document.createElement("article");
    item.className = `notification-centre-item priority-${message.priority}`;
    item.classList.toggle("unread", isUnread(message));

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "notification-centre-item-toggle";
    toggle.setAttribute("aria-expanded", "false");

    const content = document.createElement("div");
    content.className = "notification-centre-item-content";

    const heading = document.createElement("div");
    heading.className = "notification-centre-item-heading";

    const title = document.createElement("strong");
    title.textContent = message.title;

    const time = document.createElement("time");
    time.dateTime = new Date(message.time * 1000).toISOString();
    time.title = new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(message.time * 1000));
    time.textContent = relativeTime(message.time);

    const body = document.createElement("p");
    body.textContent = message.message;

    const topic = document.createElement("span");
    topic.className = `notification-centre-topic ${message.topic}`;
    topic.textContent = message.topic;

    const chevron = document.createElement("span");
    chevron.className = "notification-centre-chevron";
    chevron.setAttribute("aria-hidden", "true");
    chevron.textContent = "⌄";

    heading.append(title, time);
    content.append(heading, body, topic);
    toggle.append(createIcon(message), content, chevron);
    toggle.addEventListener("click", () => {
      const expanded = item.classList.toggle("expanded");
      toggle.setAttribute("aria-expanded", String(expanded));
      markMessageRead(message, item);
    });
    item.append(toggle);

    if (message.click) {
      const link = document.createElement("a");
      link.className = "notification-centre-open-link";
      link.href = message.click;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.textContent = "Open service ↗";
      item.append(link);
    }

    return item;
  };

  const render = () => {
    const list = document.querySelector("#notification-centre-list");
    if (!list) return;

    const items = sortedMessages();
    if (loading && !items.length) {
      const state = document.createElement("p");
      state.className = "notification-centre-state";
      state.textContent = "Loading notifications…";
      list.replaceChildren(state);
      return;
    }
    if (loadError && !items.length) {
      const state = document.createElement("p");
      state.className = "notification-centre-state notification-centre-error";
      state.textContent = "Could not reach the notification feed.";
      list.replaceChildren(state);
      return;
    }
    if (!items.length) {
      const state = document.createElement("p");
      state.className = "notification-centre-state";
      state.textContent = `No ${filter === "all" ? "" : `${filter} `}notifications in the last 7 days.`;
      list.replaceChildren(state);
      return;
    }

    list.replaceChildren(...items.map(createMessage));
  };

  const updateBadge = () => {
    const badge = document.querySelector("#notification-centre-badge");
    const button = document.querySelector(`#${BUTTON_ID}`);
    if (!badge || !button) return;
    const unread = [...messages.values()].filter(isUnread).length;
    badge.textContent = unread > 99 ? "99+" : String(unread);
    badge.hidden = unread === 0;
    button.setAttribute(
      "aria-label",
      unread ? `Notifications, ${unread} unread` : "Notifications",
    );
  };

  const close = () => {
    document.body.classList.remove(OPEN);
    document.querySelector(`#${BUTTON_ID}`)?.setAttribute("aria-expanded", "false");
  };

  const open = () => {
    document.body.classList.add(OPEN);
    document.querySelector(`#${BUTTON_ID}`)?.setAttribute("aria-expanded", "true");
    render();
  };

  const createDrawer = () => {
    if (document.querySelector(`#${DRAWER_ID}`)) return;

    const overlay = document.createElement("button");
    overlay.type = "button";
    overlay.className = "notification-centre-overlay";
    overlay.setAttribute("aria-label", "Close notifications");
    overlay.addEventListener("click", close);

    const drawer = document.createElement("aside");
    drawer.id = DRAWER_ID;
    drawer.className = "notification-centre-drawer";
    drawer.setAttribute("aria-label", "Notifications");

    const header = document.createElement("header");
    header.className = "notification-centre-header";
    const heading = document.createElement("div");
    const title = document.createElement("h2");
    title.textContent = "Notifications";
    const subtitle = document.createElement("p");
    subtitle.textContent = "Alerts and downloads · last 7 days";
    heading.append(title, subtitle);

    const actions = document.createElement("div");
    actions.className = "notification-centre-actions";
    const markRead = document.createElement("button");
    markRead.type = "button";
    markRead.textContent = "Mark read";
    markRead.addEventListener("click", markAllRead);
    const closeButton = document.createElement("button");
    closeButton.type = "button";
    closeButton.className = "notification-centre-close";
    closeButton.setAttribute("aria-label", "Close notifications");
    closeButton.textContent = "×";
    closeButton.addEventListener("click", close);
    actions.append(markRead, closeButton);
    header.append(heading, actions);

    const filters = document.createElement("nav");
    filters.className = "notification-centre-filters";
    filters.setAttribute("aria-label", "Notification filters");
    for (const [value, label] of [
      ["all", "All"],
      ["alerts", "Alerts"],
      ["downloads", "Downloads"],
    ]) {
      const button = document.createElement("button");
      button.type = "button";
      button.dataset.filter = value;
      button.className = value === filter ? "active" : "";
      button.textContent = label;
      button.addEventListener("click", () => {
        filter = value;
        filters.querySelectorAll("button").forEach((item) => {
          item.classList.toggle("active", item === button);
        });
        render();
      });
      filters.append(button);
    }

    const list = document.createElement("div");
    list.id = "notification-centre-list";
    list.className = "notification-centre-list";
    list.setAttribute("aria-live", "polite");

    drawer.append(header, filters, list);
    document.body.append(overlay, drawer);
    render();
  };

  const createButton = () => {
    if (document.querySelector(`#${BUTTON_ID}`)) return;
    const target = document.querySelector("#information-widgets-right");
    if (!target) return;

    const button = document.createElement("button");
    button.id = BUTTON_ID;
    button.className = "notification-centre-button";
    button.type = "button";
    button.setAttribute("aria-controls", DRAWER_ID);
    button.setAttribute("aria-expanded", "false");
    button.setAttribute("aria-label", "Notifications");
    button.innerHTML =
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></svg><span id="notification-centre-badge" hidden></span>';
    button.addEventListener("click", () => {
      document.body.classList.contains(OPEN) ? close() : open();
    });
    target.prepend(button);
    updateBadge();
  };

  const mount = () => {
    createDrawer();
    createButton();
  };

  const parseJsonLines = (text) => {
    for (const line of text.split("\n")) {
      if (!line.trim()) continue;
      try {
        addMessage(JSON.parse(line));
      } catch {
        // Ignore a malformed stream line; later events still remain usable.
      }
    }
  };

  const connectLive = () => {
    eventSource?.close();
    const newest = [...messages.values()].sort(
      (left, right) => right.time - left.time,
    )[0];
    const since = newest ? newest.id : HISTORY_WINDOW;
    eventSource = new EventSource(`${NTFY_BASE}/sse?since=${encodeURIComponent(since)}`);
    eventSource.onmessage = (event) => {
      try {
        if (addMessage(JSON.parse(event.data))) {
          updateBadge();
          render();
        }
      } catch {
        // EventSource reconnects automatically; one invalid event is harmless.
      }
    };
  };

  const load = async () => {
    try {
      const response = await fetch(
        `${NTFY_BASE}/json?poll=1&since=${HISTORY_WINDOW}`,
        { cache: "no-store" },
      );
      if (!response.ok) throw new Error(`ntfy returned ${response.status}`);
      parseJsonLines(await response.text());
      loadError = false;
    } catch {
      loadError = true;
    } finally {
      loading = false;
      updateBadge();
      render();
      connectLive();
    }
  };

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
  });
  document.addEventListener("visibilitychange", () => {
    if (!document.hidden && eventSource?.readyState === EventSource.CLOSED) {
      connectLive();
    }
  });

  new MutationObserver(mount).observe(document.body, {
    childList: true,
    subtree: true,
  });
  mount();
  load();
})();
