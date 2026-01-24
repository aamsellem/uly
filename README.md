# MARVIN - Your AI Chief of Staff

MARVIN is an AI assistant that remembers your conversations, tracks your goals, and helps you stay organized. Like having a personal chief of staff who never forgets anything.

---

## Getting Started

### 1. Download MARVIN

Click the green "Code" button above, then "Download ZIP". Unzip it somewhere on your computer (like your Downloads folder).

Or if you use git:
```
git clone https://github.com/SterlingChin/marvin-template.git marvin-template
```

### 2. Open in Claude Code

Open Claude Code and navigate to the folder you downloaded:
```
cd marvin-template
claude
```

### 3. Ask MARVIN to Help You Set Up

Just say:
> "Help me set up MARVIN"

MARVIN will walk you through everything step by step:
- Your name and role
- Your goals (work and personal)
- How you want MARVIN to communicate
- Where to create your personal workspace (default: ~/marvin)
- Optional: Connect to Google Calendar, Gmail, Jira, etc.

That's it! MARVIN handles the rest.

---

## How It Works

MARVIN creates a **personal workspace** separate from this template:

```
~/marvin/                    <- Your workspace (your data lives here)
├── CLAUDE.md               # Your profile and preferences
├── state/                  # Your goals and priorities
├── sessions/               # Your daily session logs
└── ...

~/Downloads/marvin-template/ <- Template (keep this for updates!)
├── .marvin/                # Setup scripts and integrations
└── ...
```

**Your workspace** is where all your personal data lives. It's yours to customize.

**The template** is where you get updates from. When new features are added, run `/sync` to pull them in.

---

## Daily Usage

Once set up, navigate to your workspace and start MARVIN:
```
cd ~/marvin
claude
```

Or if you set up the shortcut during onboarding, just type:
```
marvin
```

### Start Your Day
```
/marvin
```
MARVIN gives you a briefing: your priorities, deadlines, and progress.

### Throughout the Day
Just talk naturally:
- "Add a task: finish the report by Friday"
- "What should I focus on today?"
- "I finished the presentation"
- "What did we talk about yesterday?"

### Save Your Progress
```
/update
```
Quick save without ending the session.

### End Your Day
```
/end
```
MARVIN saves everything for next time.

---

## Commands

| Command | What It Does |
|---------|--------------|
| `/marvin` | Start your day with a briefing |
| `/end` | End session and save everything |
| `/update` | Quick checkpoint (save progress) |
| `/report` | Generate a weekly summary |
| `/commit` | Review and commit git changes |
| `/code` | Open in your IDE |
| `/sync` | Get updates from the template |
| `/help` | Show all commands and integrations |

---

## Getting Updates

When new features are added to MARVIN:

1. Update your template folder (git pull or re-download)
2. Open your workspace in Claude Code
3. Run `/sync`

Your personal data is never overwritten. Only new commands and skills are added.

---

## What Can MARVIN Do?

- **Remember everything** - Pick up where you left off, even days later
- **Track your goals** - Monitor progress on work and personal goals
- **Manage tasks** - Keep a running to-do list that persists
- **Give briefings** - Start each day knowing what matters
- **Push back** - MARVIN is a thought partner, not a yes-man
- **Connect to your tools** - Google Calendar, Gmail, Jira, and more (optional)

---

## Need Help?

Just ask MARVIN! Say things like:
- "How do I add Google Calendar?"
- "How do I create a new skill?"
- "What commands are available?"

Or type `/help` for a quick reference.

---

## About

MARVIN is named after the Paranoid Android from The Hitchhiker's Guide to the Galaxy.

Created by [Sterling Chin](https://sterlingchin.com). Because everyone deserves a chief of staff.
