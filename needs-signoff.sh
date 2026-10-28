#!/bin/bash
# needs-signoff.sh prs|designs [--dry-run]
# Run hourly via launchd. First tick at/after 9am Pacific: for each PERSON who has
# un-✅'d bot posts in the channel (PRs in #prs, designs in #claudedesigns), post a
# "🧵 <@person> NEEDS SIGNOFF: N/N …" parent in that same channel + a threaded list
# of their items. Every later tick that day: re-check, drop the ✅'d ones, edit the
# list, burn the count down. People with nothing pending get no post.
# An item @-mentions its owner ONCE (the first day it is seen); after that it is only
# re-listed every REMIND_DAYS, in a parent that names the person without pinging them.
# Seen-items map: ~/.config/needs-signoff-<kind>.json {item_ts: {first, last}}.
set -euo pipefail
REMIND_DAYS=2

MODE="${1:-}"; DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
case "$MODE" in
  prs)     CH="C091HEJ9B1V"; DAYS=4; LABEL="PR(s)";     KIND="prs" ;;
  designs) CH="C0BV698RM6X"; DAYS=7; LABEL="design(s)"; KIND="designs" ;;
  *) echo "usage: $0 prs|designs [--dry-run]"; exit 2 ;;
esac

TOKEN=$(cat /Users/carlos/.claude/skills/claudeqs/.bot-token)
CLAUDE_BOT="U0BEY4312LR"
CARLOS="U0516TWQHGD"
MARKER="NEEDS SIGNOFF:"

day_start=$(TZ=America/Los_Angeles date -j -f '%Y-%m-%d %H:%M:%S' \
  "$(TZ=America/Los_Angeles date '+%Y-%m-%d') 09:00:00" '+%s')
now=$(date '+%s')
[ "$now" -lt "$day_start" ] && { echo "before 9am PT, skipping"; exit 0; }

# Jira creds for assignee lookup (prs mode); missing file degrades to thread-tag logic.
JIRA_EMAIL=""; JIRA_API_TOKEN=""; JIRA_SITE_URL=""
[ -f "$HOME/.config/jira-sweep.env" ] && source "$HOME/.config/jira-sweep.env"

TOKEN="$TOKEN" CH="$CH" DAYS="$DAYS" LABEL="$LABEL" KIND="$KIND" CLAUDE_BOT="$CLAUDE_BOT" \
CARLOS="$CARLOS" MARKER="$MARKER" DAY_START="$day_start" NOW="$now" DRY="$DRY" REMIND_DAYS="$REMIND_DAYS" \
STATE_FILE="$HOME/.config/needs-signoff-$KIND.json" \
JIRA_EMAIL="$JIRA_EMAIL" JIRA_API_TOKEN="$JIRA_API_TOKEN" JIRA_SITE_URL="$JIRA_SITE_URL" python3 <<'PY'
import os,re,json,urllib.request,urllib.parse
tok=os.environ["TOKEN"]; ch=os.environ["CH"]; days=int(os.environ["DAYS"]); label=os.environ["LABEL"]
kind=os.environ["KIND"]; bot=os.environ["CLAUDE_BOT"]; carlos=os.environ["CARLOS"]; marker=os.environ["MARKER"]
day_start=int(os.environ["DAY_START"]); now=int(os.environ["NOW"]); dry=os.environ["DRY"]=="1"
remind_secs=int(os.environ["REMIND_DAYS"])*86400; state_file=os.environ["STATE_FILE"]
# People whose summary must carry every pending item, not only the ones due (Trent, 2026-09-19).
ALWAYS_LIST={"U0516TPEU2Z"}
seen={}
if os.path.exists(state_file):
    with open(state_file) as f: seen=json.load(f)
def save_seen():
    os.makedirs(os.path.dirname(state_file),exist_ok=True)
    with open(state_file,"w") as f: json.dump(seen,f,indent=1)

def api(method,params,post=False):
    data=None; url="https://slack.com/api/"+method
    if post: data=urllib.parse.urlencode(params).encode()
    else: url+="?"+urllib.parse.urlencode(params)
    req=urllib.request.Request(url,data=data,headers={"Authorization":"Bearer "+tok})
    return json.load(urllib.request.urlopen(req))

def checked(m): return any(r.get("name")=="white_check_mark" for r in m.get("reactions",[]))
def top_level(m): return not m.get("thread_ts") or m.get("thread_ts")==m.get("ts")
def is_item(m):
    if m.get("user")!=bot or not top_level(m) or marker in m.get("text",""): return False
    t=m.get("text","")
    if kind=="prs": return ":robot_face:" in t or t.startswith("🤖")
    return "Design ready" in t

jira_email=os.environ["JIRA_EMAIL"]; jira_tok=os.environ["JIRA_API_TOKEN"]; jira_site=os.environ["JIRA_SITE_URL"]
_jira_cache={}; _roster={}
def slack_roster():
    # Jira hides emails, so map by name: {real_name.lower(): slack id} for active humans.
    if not _roster:
        for u in api("users.list",{"limit":500}).get("members",[]):
            if u.get("deleted") or u.get("is_bot"): continue
            for n in (u.get("real_name",""), u.get("profile",{}).get("display_name","")):
                if n.strip(): _roster.setdefault(n.strip().lower(), u["id"])
    return _roster
def jira_assignee_slack_id(ticket_key):
    # ENG-xxxx -> Jira assignee email -> Slack id; None on any gap (no creds, no assignee, hidden email).
    if ticket_key in _jira_cache: return _jira_cache[ticket_key]
    uid=None
    try:
        if jira_tok:
            import base64
            auth=base64.b64encode(f"{jira_email}:{jira_tok}".encode()).decode()
            req=urllib.request.Request(f"https://{jira_site}/rest/api/3/issue/{ticket_key}?fields=assignee",
                headers={"Authorization":"Basic "+auth,"Accept":"application/json"})
            assignee=(json.load(urllib.request.urlopen(req)).get("fields") or {}).get("assignee") or {}
            name=(assignee.get("displayName") or "").strip().lower()
            if name: uid=slack_roster().get(name)
    except Exception as e:
        print(f"{ticket_key}: jira lookup failed: {e}")
    _jira_cache[ticket_key]=uid
    return uid

def person(m):
    # designs: the parent tags the approver; prs: Jira assignee of the ticket in the post,
    # falling back to the bot's "👤 <@id>" thread reply.
    t=m.get("text","")
    mm=re.search(r"<@(U[A-Z0-9]+)>",t)
    if kind=="prs":
        km=re.search(r"\bENG-\d+\b",t)
        if km:
            uid=jira_assignee_slack_id(km.group(0))
            if uid: return uid
        reps=api("conversations.replies",{"channel":ch,"ts":m["ts"],"limit":50}).get("messages",[])[1:]
        for r in reps:
            if r.get("user")==bot and (":bust_in_silhouette:" in r.get("text","") or r.get("text","").startswith("👤")):
                mm=re.search(r"<@(U[A-Z0-9]+)>",r.get("text","")); break
    return mm.group(1) if mm else carlos

def summarize(text):
    t=re.sub(r"<[^>]*>","",text.split("\n")[0])
    t=re.sub(r"^\s*(:robot_face:|🤖)\s*:?\s*(AI-CREATED-PR:|Design ready\s*—?)?\s*","",t)
    t=re.sub(r"\(\s*\)","",re.sub(r"\s+"," ",t))
    return re.sub(r"[\s—–()-]+$","",t).strip()

_names={}
def plain_name(uid):
    # Name without <@…> so a repeat reminder does not ping anyone.
    if uid not in _names:
        u=api("users.info",{"user":uid}).get("user",{})
        _names[uid]=u.get("real_name") or u.get("name") or uid
    return _names[uid]

def parent_text(uid,remaining,total,ping):
    if ping: who=f"<@{uid}>"
    else: who=plain_name(uid)
    return f"🧵 {who} {marker} {remaining}/{total} {label} from the last {days} days still need your ✅ — see thread"

hist=api("conversations.history",{"channel":ch,"oldest":now-days*86400,"limit":200}).get("messages",[])
items=[m for m in hist if is_item(m)]
checked_ts={m["ts"] for m in hist if checked(m)}

# First run: everything already pending has been pinged before, so seed the map and post nothing.
if not os.path.exists(state_file):
    for m in items:
        if not checked(m): seen[m["ts"]]={"first":now,"last":now}
    if dry: print(f"would seed {len(seen)} item(s) into {state_file}")
    else: save_seen(); print(f"seeded {len(seen)} item(s) into {state_file}")
    raise SystemExit(0)

# Today's per-person parents (bot posts carrying the marker since 9am).
parents={}
for m in hist:
    if m.get("user")==bot and marker in m.get("text","") and float(m["ts"])>=day_start:
        mm=re.search(r"<@(U[A-Z0-9]+)>",m.get("text",""))
        if mm and mm.group(1) not in parents: parents[mm.group(1)]=m

# Fresh cohorts per person: never-seen items (ping) + seen items due for a reminder (no ping).
cohort={}; carry={}; pings=set(); included={}
for m in sorted(items,key=lambda x: float(x["ts"])):
    if checked(m): continue
    rec=seen.get(m["ts"])
    if rec is None: is_new=True
    else: is_new=False
    uid=person(m)
    due=is_new or now-int(rec["last"])>=remind_secs
    if not due and uid not in ALWAYS_LIST: continue
    p=api("chat.getPermalink",{"channel":ch,"message_ts":m["ts"]})
    if not p.get("ok"): continue
    bucket=cohort
    if not due: bucket=carry
    bucket.setdefault(uid,[]).append("• <"+p["permalink"]+"|"+summarize(m.get("text",""))+">")
    included.setdefault(uid,[]).append(m["ts"])
    if is_new: pings.add(uid)
# ALWAYS_LIST: a post that goes out on the normal cadence carries every pending item, so none drop off.
for uid in list(cohort):
    cohort[uid]+=carry.get(uid,[])

# --- UPDATE existing parents: trim by ✅ ---
for uid,parent in parents.items():
    reps=api("conversations.replies",{"channel":ch,"ts":parent["ts"],"limit":50}).get("messages",[])
    reply=next((r for r in reps if r.get("user")==bot and r["ts"]!=parent["ts"]),None)
    if reply is None: print(f"{uid}: no list reply, skipping"); continue
    lines=[l for l in reply.get("text","").split("\n") if l.strip().startswith("•")]
    mm=re.search(r"(\d+)\s*/\s*(\d+)",parent.get("text",""))
    if mm: total=int(mm.group(2))
    else: total=len(lines)
    kept=[]
    for l in lines:
        m2=re.search(r"/p(\d+)",l)
        if not m2: kept.append(l); continue
        d=m2.group(1); ts=d[:-6]+"."+d[-6:]
        if ts not in checked_ts: kept.append(l)
    new_reply="\n".join(kept) if kept else f"✅ All signed off — nothing left."
    if dry: print(f"{uid}: would update {len(kept)}/{total}\n{new_reply}\n"); continue
    api("chat.update",{"channel":ch,"ts":parent["ts"],"text":parent_text(uid,len(kept),total,"<@" in parent.get("text",""))},post=True)
    api("chat.update",{"channel":ch,"ts":reply["ts"],"text":new_reply,"unfurl_links":"false","unfurl_media":"false"},post=True)
    print(f"{uid}: updated {len(kept)}/{total}")

# --- FRESH parents for people with pending items and no parent today ---
for uid,bullets in cohort.items():
    if uid in parents: continue
    total=len(bullets); report="\n".join(bullets); ping=uid in pings
    if dry: print(f"{uid}: would post {total} (ping={ping})\n{parent_text(uid,total,total,ping)}\n{report}\n"); continue
    pt=api("chat.postMessage",{"channel":ch,"text":parent_text(uid,total,total,ping)},post=True)["ts"]
    api("chat.postMessage",{"channel":ch,"thread_ts":pt,"text":report,"unfurl_links":"false","unfurl_media":"false"},post=True)
    for ts in included[uid]:
        seen.setdefault(ts,{"first":now})["last"]=now
    save_seen()
    print(f"{uid}: posted {total} (ping={ping})")
if not cohort and not parents: print("nothing pending for anyone")
PY
