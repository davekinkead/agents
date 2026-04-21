---
description: Compute Australian income tax and 2% Medicare levy for an even split among people
---

Run the script to compute income tax and Medicare levy by running `ruby ~/.agents/opencode/tools/tax_au.rb income:<AUD_total_gross_including_super> people:<int>`.

Example:

`ruby ~/.agents/opencode/tools/tax_au.rb income:200000 people:2`

This will split 200,000 AUD evenly between 2 people. The income argument is the gross total including employer superannuation (by default assumed to be 12% of salary). The script computes resident income tax (simplified brackets) and a 2% Medicare levy per person, and prints a per-person and aggregate summary.

Super handling
- By default the provided income is assumed to be the gross total INCLUDING employer superannuation at the standard rate of 12% (i.e. gross total = salary + 12% super).
- To use a fixed "max" super of AUD 30,000 per person instead, pass the `max` (or `max_super`) flag.

Example with max super:

`ruby ~/.agents/opencode/tools/tax_au.rb income:200000 people:2 max`

Output includes: gross income, gross salary (taxable), income tax, Medicare (2%), employer super, super tax (15%), net salary, net super, and aggregate totals.
