# Setting up your MacBook

**Do this in the setup session, not on the morning of the hackathon.**

Total time: about 20 minutes, most of it waiting for downloads.

You do **not** need to install PostgreSQL. The database runs inside a
container, which means it cannot interfere with anything else on your Mac and
you can delete the whole thing afterwards with one command.

---

## Step 1 — Open Terminal

Press `Cmd + Space`, type `Terminal`, press Enter.

A window appears with a `$` prompt. This is where you type commands. When
these instructions show a line starting with `$`, type the part **after** the
`$` and press Enter.

---

## Step 2 — Install Homebrew

Homebrew installs software from the Terminal. Check whether you already have it:

```bash
brew --version
```

If you see a version number, skip to Step 3.

If you see `command not found`, install it by pasting the command from
**[brew.sh](https://brew.sh)** and following the prompts. It will ask for
your Mac password — this is normal, and the characters will not appear as
you type.

> **If Homebrew is blocked** on your machine, stop here and tell an
> organiser today. There is another way in
> [99-fallback-postgres-app.md](99-fallback-postgres-app.md), but we would
> rather sort it out in advance.

---

## Step 3 — Install the Docker tools

```bash
brew install colima docker docker-compose
```

This takes a few minutes.

### What are these, and why three of them?

A **container** is a tiny, sealed Linux computer running inside your Mac. The
database runs in one. That is why you do not have to install PostgreSQL, and
why nothing can conflict with your own setup.

- **`docker`** — the command you type to control containers.
- **`colima`** — macOS cannot actually run Linux containers on its own, so
  Colima runs a very small Linux machine in the background for them to live in.
- **`docker-compose`** — reads the settings file in this project so you do
  not have to remember any of them.

*(You may have heard of Docker Desktop, which bundles all three. It needs a
paid licence for organisations our size, so we use Colima instead. It is free
and open source, and it does the same job.)*

---

## Step 4 — Start Colima

```bash
colima start
```

The first run takes a minute or two while it builds the small Linux machine.
After that it is quick.

You only need to do this once. It keeps running in the background, and
`./start.sh` will start it for you if it has stopped.

---

## Step 5 — Get the hackathon files

```bash
cd ~/Documents
git clone https://github.com/shikhars019/data-engineering-hackathon.git
cd data-engineering-hackathon
```

`cd` means "go into this folder". You need to be in this folder for every
command from here on. If you close Terminal and come back, run
`cd ~/Documents/data-engineering-hackathon` again.

---

## Step 6 — Install a SQL client

You will spend the day *looking* at data, and a grid is far easier to read
than terminal output. This is optional but strongly recommended.

```bash
brew install --cask tableplus
```

The free version is more than enough for today.

Prefer something with no limits at all? `brew install --cask dbeaver-community`
works just as well, though it is a heavier download.

---

## Step 7 — Check everything works

```bash
./preflight.sh
```

This checks each tool, downloads the database image (about 150 MB — doing it
now means you are not waiting on the wifi on the day), builds a real database
as a dry run, and then throws it away.

You are looking for:

```
  All 9 checks passed. You are ready for the hackathon.
```

**If anything fails**, the script tells you what to run. If you are still
stuck, send an organiser a screenshot of the whole output — today, please,
not on the morning of the hackathon.

---

## On the day

```bash
cd ~/Documents/data-engineering-hackathon
./start.sh 3          # your team number
```

You will see a banner with your connection details. In TablePlus, create a
new PostgreSQL connection with:

| Field | Value |
|---|---|
| Host | `localhost` |
| Port | **`55432`** |
| User | `hackathon` |
| Password | `hackathon` |
| Database | `pension` |

> **Why 55432 and not 5432?** 5432 is PostgreSQL's usual port. If anybody has
> a copy already installed, the two would fight over it and you would get a
> confusing error. Moving ours out of the way avoids the problem entirely.

---

## Commands you will use

| Command | What it does |
|---|---|
| `./start.sh 3` | Start the database and load team 3's data |
| `./check.sh 1` | Run your Challenge 1 SQL and score it |
| `./check.sh 2` | Run your Challenge 2 SQL and score it |
| `./explore.sh` | Look at your data from the Terminal |
| `./reset.sh` | Wipe everything and start again |
| `./stop.sh` | Shut the database down — your work is kept |

---

## Troubleshooting

**`Cannot connect to the Docker daemon`**
Colima is not running. `colima start`.

**`docker: 'compose' is not a docker command`**
Homebrew did not link the plugin. Either use `docker-compose` with a hyphen,
or run:
```bash
mkdir -p ~/.docker/cli-plugins
ln -sfn "$(brew --prefix)/opt/docker-compose/bin/docker-compose" ~/.docker/cli-plugins/docker-compose
```
Our scripts cope with both, so this only matters if you are typing Docker
commands yourself.

**`port is already allocated`**
Something else is on 55432. Find it with
`lsof -nP -iTCP:55432 -sTCP:LISTEN`.

**`permission denied: ./start.sh`**
```bash
chmod +x *.sh
```

**Anything else**
Run `./reset.sh`. It fixes the large majority of problems, and it is not
cheating.

---

## Afterwards

To remove everything and reclaim the disk space:

```bash
./stop.sh
docker compose down -v
colima stop
```

And delete the folder. Nothing was installed outside it.
