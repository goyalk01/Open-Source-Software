# 📝 Report Outline — Apache HTTPD Open Source Audit

> Structural guide for a 12–16 page report. Key points and talking ideas for each section — write everything in YOUR OWN WORDS.

---

## Page 1: Title Page

- **Project Title:** Open Source Software Audit — Apache HTTP Server
- Your Name, Roll Number, Department
- University Name, Date, Supervisor Name

---

## Pages 2–3: Introduction & Background (2 pages)

### Cover:
- What is open-source software? (YOUR understanding, not a textbook definition)
- Why does open source matter today?
- What is a software audit and why do one?
- Why you chose Apache HTTPD

### Key points:
- Open source = source code publicly available — view, modify, distribute
- Not just "free" — about transparency, collaboration, security through visibility
- Apache was chosen because it's foundational to the internet (~30% of websites), rich history, deep Linux integration
- An audit examines how a project is built, licensed, maintained, and deployed

### ❌ Avoid: Generic dictionary definitions. Wikipedia-style paragraphs.

---

## Pages 3–4: History & Origin Story (1.5–2 pages)

### Cover:
- NCSA HTTPd problem (1995, Rob McCool left)
- "A patchy server" — how patches became Apache
- ASF formation (1999), meritocratic governance
- How Apache changed the web (60%+ market share by 2000)

### Your angle:
- What if the web relied only on proprietary servers?
- What does it mean that unpaid volunteers built the internet's backbone?

---

## Pages 5–6: License Analysis (2 pages)

### Cover:
- Apache License 2.0 explained
- The 4 Freedoms (Stallman): run, study, redistribute, modify
- Comparison: Apache 2.0 vs GPL vs MIT
- Patent grant clause (unique to Apache)
- Commercial usage rules

### Key comparison:

| Feature | Apache 2.0 | GPL v2 | MIT |
|---------|-----------|--------|-----|
| Must share modified source | No | Yes | No |
| Patent grant | Yes | No | No |
| Attribution required | Yes | Yes | Yes |
| Commercial use | Yes | Yes | Yes |

### 📌 What scores full marks: Explaining WHY the license choice matters, not just WHAT the license says.

---

## Pages 6–7: Linux Installation & System Integration (1.5–2 pages)

### Cover:
- Installation commands (apt install apache2)
- Key directories and their purpose
- Commands used: systemctl, which, whereis, ps

### Key locations:

| Path | Purpose |
|------|---------|
| `/usr/sbin/apache2` | Apache binary |
| `/etc/apache2/` | Configuration directory |
| `/etc/apache2/apache2.conf` | Primary config file |
| `/etc/apache2/sites-available/` | Virtual host configs |
| `/var/www/html/` | Default document root |
| `/var/log/apache2/` | Log files |

### 📌 What scores full marks: Explaining WHY each location matters, not just listing paths.

---

## Pages 8–10: Shell Script Development (3 pages)

### For EACH of the 5 required scripts, explain:
1. **Purpose** — What problem does it solve?
2. **Logic** — How does it work? (high-level flow)
3. **Key bash concepts** — What constructs does it demonstrate?
4. **Sample output** — What does it produce?

### Required scripts summary:

| Script | Purpose | Key Concepts |
|--------|---------|-------------|
| 01 System Identity | Gathers system/Apache info | Variables, `uname`, `echo`, command substitution |
| 02 Package Inspector | Inspects Apache package | `if-else`, `case`, `dpkg`/`rpm` |
| 03 Disk & Permission Audit | Audits Apache directories | `for` loop, `du`, `ls`, `stat` |
| 04 Log Analyzer | Counts log patterns line-by-line | `while read`, `grep`, counter variables |
| 05 Manifest Generator | Creates a project manifest | `read` input, file write (`>`, `>>`) |

### Also mention: 5 advanced scripts as bonus work (briefly, 1 paragraph).

### 📌 What scores full marks: Explaining the logic and concepts, not pasting code. Show WHY you chose each approach.

### ❌ Common mistakes:
- Pasting entire scripts into the report (waste of pages)
- Not explaining what variables/loops/conditions do
- Scripts that are too trivial (just `echo "hello"`)

---

## Pages 10–11: Ecosystem & Dependencies (1.5 pages)

### Cover:
- LAMP Stack: Linux + Apache + MySQL + PHP
- Module system (mod_ssl, mod_rewrite, mod_php)
- Apache as reverse proxy
- Real-world usage: Apple, PayPal, governments, universities

### 📌 What scores full marks: Connecting Apache to the broader ecosystem, not just listing dependencies.

---

## Pages 11–12: Open Source vs Proprietary (1.5 pages)

### Compare Apache HTTPD vs Microsoft IIS — be balanced, not biased.

| Dimension | Apache HTTPD | Microsoft IIS |
|-----------|-------------|---------------|
| Cost | Free | Windows Server license |
| Platform | Cross-platform | Windows only |
| Source access | Open | Closed |
| Configuration | Text files | GUI + registry |
| Community | Global open-source | Microsoft support |
| Market share | ~30% | ~7% |
| Vendor lock-in | None | Windows ecosystem |

### 📌 What scores full marks: Balanced analysis. Acknowledge IIS is better for Windows/.NET. Apache is better for Linux/cross-platform. "Better" depends on context.

---

## Pages 13–14: Challenges & Learnings (1–1.5 pages)

### Ideas:
- Config file hierarchy was confusing at first (sites-available vs sites-enabled)
- Writing shell scripts deepened Linux understanding beyond GUI
- License differences have real business implications
- The web depends on volunteer-maintained software — surprising

---

## Pages 14–15: Conclusion (1 page)

### Key closing points:
- Apache demonstrates open-source can be enterprise-grade
- Apache License 2.0 created a model for business-friendly open source
- 30 years of community development shows sustainability
- Open source is a philosophy about how technology should serve everyone

---

## Page 16: References

- httpd.apache.org
- apache.org/licenses/LICENSE-2.0
- gnu.org/philosophy/free-sw.html
- w3techs.com/technologies/details/ws-apache
- Ubuntu documentation for Apache2
- Course textbook references
