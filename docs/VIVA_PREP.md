# 🎓 Viva Preparation Guide — Apache HTTPD Audit

> Keywords and pointers for each question — practice explaining in YOUR OWN WORDS.

---

## ⭐ Top 15 Must-Know Questions

### Q1: What is your project about?
**Keywords:** Open-source audit of Apache HTTP Server — analyzed its origin, license, Linux integration, and wrote shell scripts for server administration.

### Q2: Why did you choose Apache?
**Keywords:** Powers ~30% of websites, started 1995, deep Linux integration (runs as a service, has configs/logs), rich history, good for scripting.

### Q3: What is open-source software?
**Keywords:** Source code is publicly available — anyone can view, modify, redistribute. About transparency and collaboration, not just free cost.

### Q4: What are the 4 Freedoms?
- **Freedom 0:** Run for any purpose
- **Freedom 1:** Study how it works (source access)
- **Freedom 2:** Redistribute copies
- **Freedom 3:** Modify and distribute modified versions
- **Credit:** Richard Stallman, FSF

### Q5: What license does Apache use? How is it different from GPL?
**Keywords:** Apache License 2.0 — permissive (not copyleft). GPL requires sharing modified source, Apache doesn't. Apache has explicit patent grant, GPL doesn't. Both allow commercial use.

### Q6: Tell me the origin story of Apache.
**Keywords:** 1995 — NCSA HTTPd abandoned (Rob McCool left). Webmasters combined patches → "a patchy server" = Apache. ASF formed 1999. 60%+ market share by 2000.

### Q7: Explain your System Identity script.
**Keywords:** Uses variables to store system info (`uname`, `whoami`, `hostname`). Uses command substitution `$()`. Checks if Apache is installed with `which`. Prints formatted report with `echo`.

### Q8: Explain your Package Inspector script.
**Keywords:** `if-else` detects if system uses `dpkg` (Debian) or `rpm` (RHEL). `case` statement creates a menu (1-5). Queries package status, version, files, dependencies.

### Q9: Explain your Disk Audit script.
**Keywords:** Array of Apache directories. `for` loop iterates over each. `du -sh` measures size. `stat -c "%a"` gets permissions. Checks for world-writable dirs (security risk).

### Q10: Explain your Log Analyzer script.
**Keywords:** `while IFS= read -r line` reads log file line by line. `grep -qi` pattern-matches each line. Counter variables track errors, warnings, notices. Reports totals at the end.

### Q11: Explain your Manifest Generator script.
**Keywords:** `read -r -p` asks user for input (name, roll number, etc.). Writes to file using `>` (create) and `>>` (append). Auto-detects system info. Lists all project scripts.

### Q12: What is systemctl?
**Keywords:** Command to manage systemd services. `start`, `stop`, `status`, `enable`, `restart`. Standard way Linux manages daemons like Apache.

### Q13: Where are Apache's config/log files?
**Keywords:** Config: `/etc/apache2/`. Logs: `/var/log/apache2/`. Binary: `/usr/sbin/apache2`. Web files: `/var/www/html/`.

### Q14: Compare Apache with IIS.
**Keywords:** Apache = open source, cross-platform, text config, community-driven. IIS = closed source, Windows only, GUI-based. Apache ~30% market share, IIS ~7%. "Better" depends on context.

### Q15: What did you learn?
**Keywords:** Shell scripting deepened Linux understanding. License choice has real business impact. The internet depends on volunteer-maintained software. Open source is a philosophy, not just a development model.

---

## 🔧 Script-Specific Questions

### Q16: What is command substitution?
**Keywords:** `$(command)` runs a command and captures its output in a variable. Example: `KERNEL=$(uname -r)` stores kernel version.

### Q17: Difference between `>` and `>>`?
**Keywords:** `>` creates/overwrites a file. `>>` appends to a file without deleting existing content.

### Q18: What is `while read` loop?
**Keywords:** Reads a file line by line. `while IFS= read -r line; do ... done < file.txt`. IFS= prevents word splitting, -r prevents backslash interpretation.

### Q19: Difference between `which` and `whereis`?
**Keywords:** `which` finds executable in PATH (one result). `whereis` finds binary, source, and man pages (broader).

### Q20: What is a `case` statement?
**Keywords:** Like switch/case in other languages. Matches a variable against multiple patterns. Used for menus. Cleaner than nested if-else.

### Q21: What is `grep`?
**Keywords:** Searches text for patterns. `-i` = case insensitive. `-c` = count matches. `-q` = quiet (for conditionals). `-r` = recursive.

### Q22: What does `du -sh` do?
**Keywords:** `du` = disk usage. `-s` = summary (total only). `-h` = human-readable (KB, MB, GB).

### Q23: What does `stat -c "%a"` do?
**Keywords:** Shows file permissions in octal format (e.g., 755, 644). `stat` gives detailed file/directory metadata.

---

## 🌐 Broader Questions

### Q24: What is the LAMP stack?
**Keywords:** Linux + Apache + MySQL + PHP. Classic open-source web stack. Powers millions of websites.

### Q25: What is copyleft?
**Keywords:** Licensing mechanism where derivative works must use the same license. GPL is copyleft. Apache License is NOT. Ensures code stays open.

### Q26: Can a company take Apache code and sell it?
**Keywords:** Yes — Apache 2.0 allows this. Must include copyright notice. Can even close the source. This is why companies prefer Apache License.

### Q27: What is Apache's module system?
**Keywords:** Extends functionality without changing core: mod_ssl, mod_rewrite, mod_php. `a2enmod` enables, `a2dismod` disables.

### Q28: What improvements would you make?
**Keywords:** Email alerts, cron scheduling, monitoring integration (Prometheus), CentOS/RHEL support, unit testing.

---

## 💡 Viva Tips

1. **Speak naturally.** Don't recite memorized text.
2. **Use keywords as anchors** — then explain in your own words.
3. **When unsure:** "From what I understand..." rather than guessing.
4. **Walk through script logic** — don't recite line numbers.
5. **Know your numbers:** Apache ~30% market share, started 1995, ASF 1999.
6. **Practice the top 15 questions** until you can answer each in 30 seconds.

---

## 🛡️ Anti-AI Detection Tips

1. **Use personal language:** "I found that...", "What surprised me was...", "I struggled with..."
2. **Avoid perfect grammar.** Real students use simpler sentences with occasional errors.
3. **Add personal experiences:** "When I ran the command, I noticed..." 
4. **Use specific examples:** Instead of "Apache is widely used", say "I read that Apple and PayPal run Apache"
5. **Vary sentence length.** AI tends to write uniform-length sentences. Mix short and long.
6. **Include failures:** "My first version of the script didn't work because I forgot to..."
7. **Use informal connectors:** "So basically...", "The thing is...", "What I mean is..."
8. **Reference your process:** "I looked at the config file and noticed...", "After testing on WSL..."
