# Fallback: running without Docker

**Only use this if Docker genuinely will not work on your machine** — for
example if Homebrew or Colima is blocked by policy. Tell an organiser first;
they may be able to fix the main route in a couple of minutes.

Everything in the hackathon works identically either way. The only difference
is where PostgreSQL is running.

---

## Step 1 — Install Postgres.app

1. Download from **[postgresapp.com](https://postgresapp.com)**
2. Drag it to your Applications folder
3. Open it and click **Initialize**
4. A green dot means the database is running

No admin rights, no Terminal, about two minutes.

---

## Step 2 — Add `psql` to your Terminal

```bash
sudo mkdir -p /etc/paths.d && echo /Applications/Postgres.app/Contents/Versions/latest/bin | sudo tee /etc/paths.d/postgresapp
```

**Close Terminal and open it again**, then check:

```bash
psql --version
```

---

## Step 3 — Build the database

From inside the hackathon folder:

```bash
./scripts/setup-without-docker.sh 3      # your team number
```

This creates the `pension` database, runs the same setup files the container
would, and loads your team's data.

---

## Step 4 — Connect your SQL client

Same as everybody else, **except the port is 5432, not 55432**:

| Field | Value |
|---|---|
| Host | `localhost` |
| Port | **`5432`** |
| Database | `pension` |
| User | your Mac username |
| Password | *(leave blank)* |

---

## Day-to-day commands

| Instead of | Use |
|---|---|
| `./start.sh 3` | `./scripts/setup-without-docker.sh 3` |
| `./check.sh 1` | `./scripts/check-without-docker.sh 1` |
| `./reset.sh` | `./scripts/setup-without-docker.sh 3` again |

`./explore.sh` will not work. Use TablePlus, or `psql pension` directly.

---

## Differences worth knowing

- Your PostgreSQL version is whatever Postgres.app installed, rather than the
  16 everyone else has. Nothing in this hackathon depends on the version.
- The database lives in your home folder, not in a container, so removing it
  means dropping the database rather than deleting a volume:
  ```bash
  dropdb pension
  ```
- Everything else — the tasks, the tests, the scoring — is identical.

---

## Last resort: a cloud database

If your laptop defeats both routes, an organiser can give you a hosted
PostgreSQL database and a connection string. You will be working in five
minutes and you will not be at any disadvantage.

**Just ask.** Losing half the session to an install is much worse than
putting your hand up.
