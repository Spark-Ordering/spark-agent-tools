#!/bin/bash
# needs-signoff.sh prs|designs [--dry-run]
# Run hourly via launchd. First tick at/after 9am Pacific: for each PERSON who has
# un-✅'d bot posts in the channel (PRs in #prs, designs in #claudedesigns), post a
# "🧵 <@person> NEEDS SIGNOFF: N/N …" parent in that same channel + a threaded list
# of their items. Every later tick that day: re-check, drop the ✅'d ones, edit the
# list, burn the count down. People with nothing pending get no post. State is the
# thread itself (permalinks in the reply), so it's self-contained.
set -euo pipefail

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

TOKEN="$TOKEN" CH="$CH" DAYS="$DAYS" LABEL="$LABEL" KIND="$KIND" CLAUDE_BOT="$CLAUDE_BOT" \
CARLOS="$CARLOS" MARKER="$MARKER" DAY_START="$day_start" NOW="$now" DRY="$DRY" python3 <<'PY'
import os,re,json,urllib.request,urllib.parse
tok=os.environ["TOKEN"]; ch=os.environ["CH"]; days=int(os.environ["DAYS"]); label=os.environ["LABEL"]
kind=os.environ["KIND"]; bot=os.environ["CLAUDE_BOT"]; carlos=os.environ["CARLOS"]; marker=os.environ["MARKER"]
day_start=int(os.environ["DAY_START"]); now=int(os.environ["NOW"]); dry=os.environ["DRY"]=="1"

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

def person(m):
    # designs: the parent tags the approver; prs: the bot's first "👤 <@id>" thread reply.
    t=m.get("text","")
    mm=re.search(r"<@(U[A-Z0-9]+)>",t)
    if kind=="prs":
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

def parent_text(uid,remaining,total):
    return f"🧵 <@{uid}> {marker} {remaining}/{total} {label} from the last {days} days still need your ✅ — see thread"

hist=api("conversations.history",{"channel":ch,"oldest":now-days*86400,"limit":200}).get("messages",[])
items=[m for m in hist if is_item(m)]
checked_ts={m["ts"] for m in hist if checked(m)}

# Today's per-person parents (bot posts carrying the marker since 9am).
parents={}
for m in hist:
    if m.get("user")==bot and marker in m.get("text","") and float(m["ts"])>=day_start:
        mm=re.search(r"<@(U[A-Z0-9]+)>",m.get("text",""))
        if mm and mm.group(1) not in parents: parents[mm.group(1)]=m

# Fresh cohorts per person from un-✅'d items.
cohort={}
for m in sorted(items,key=lambda x: float(x["ts"])):
    if checked(m): continue
    p=api("chat.getPermalink",{"channel":ch,"message_ts":m["ts"]})
    if not p.get("ok"): continue
    cohort.setdefault(person(m),[]).append("• <"+p["permalink"]+"|"+summarize(m.get("text",""))+">")

# --- UPDATE existing parents: trim by ✅ ---
for uid,parent in parents.items():
    reps=api("conversations.replies",{"channel":ch,"ts":parent["ts"],"limit":50}).get("messages",[])
    reply=next((r for r in reps if r.get("user")==bot and r["ts"]!=parent["ts"]),None)
    if reply is None: print(f"{uid}: no list reply, skipping"); continue
    lines=[l for l in reply.get("text","").split("\n") if l.strip().startswith("•")]
    mm=re.search(r"(\d+)\s*/\s*(\d+)",parent.get("text","")); total=int(mm.group(2)) if mm else len(lines)
    kept=[]
    for l in lines:
        m2=re.search(r"/p(\d+)",l)
        if not m2: kept.append(l); continue
        d=m2.group(1); ts=d[:-6]+"."+d[-6:]
        if ts not in checked_ts: kept.append(l)
    new_reply="\n".join(kept) if kept else f"✅ All signed off — nothing left."
    if dry: print(f"{uid}: would update {len(kept)}/{total}\n{new_reply}\n"); continue
    api("chat.update",{"channel":ch,"ts":parent["ts"],"text":parent_text(uid,len(kept),total)},post=True)
    api("chat.update",{"channel":ch,"ts":reply["ts"],"text":new_reply,"unfurl_links":"false","unfurl_media":"false"},post=True)
    print(f"{uid}: updated {len(kept)}/{total}")

# --- FRESH parents for people with pending items and no parent today ---
for uid,bullets in cohort.items():
    if uid in parents: continue
    total=len(bullets); report="\n".join(bullets)
    if dry: print(f"{uid}: would post {total}\n{parent_text(uid,total,total)}\n{report}\n"); continue
    pt=api("chat.postMessage",{"channel":ch,"text":parent_text(uid,total,total)},post=True)["ts"]
    api("chat.postMessage",{"channel":ch,"thread_ts":pt,"text":report,"unfurl_links":"false","unfurl_media":"false"},post=True)
    print(f"{uid}: posted {total}")
if not cohort and not parents: print("nothing pending for anyone")
PY
