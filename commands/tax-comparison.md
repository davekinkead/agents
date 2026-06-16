---
description: Compute Australian income tax and 2% Medicare levy for an even split among people
---

Run the Australian tax script with:

`ruby ~/.agents/tools/tax_au.rb income:<AUD_total_gross_including_super> people:<int> [max]`

Example:

`ruby ~/.agents/tools/tax_au.rb income:200000 people:2`

Notes:
- The income value is the gross total including employer superannuation (default super rate = 12%).
- Pass the optional `max` flag to use a fixed employer super of AUD 30,000 per person.
- Output: gross income, per-person gross salary (taxable), income tax (ATO rates), 2% Medicare levy, employer super, super tax (15%), net salary, net super, and totals.

French EURL (IR regime)

Run the script to compute an estimated French EURL (IR regime) breakdown with:

`ruby ~/.agents/tools/tax_eurl_fr.rb income:<EUR_total_gross> parts:<quotas>`

Example:

`ruby ~/.agents/tools/tax_eurl_fr.rb income:200000 parts:2.5`

This prints a concise summary: Gross income, Quotas (parts), Cotisations sociales, Income tax (IR), and Net income.

Notes:
- Cotisations are estimated with a piecewise model (≈31.556% up to €90,333.52, then ≈24.366% above).
- The script applies a 10% professional expenses abatement (frais professionnels) before computing IR; the abatement cap is set to reproduce reference outputs. If you want the official legal cap for a specific tax year (for example 2026), replace the cap value in the script accordingly.

Cyprus (company -> salary + dividend model)

Run the script with the minimal CLI:

`ruby ~/.agents/tools/tax_cyprus.rb income:<EUR_total_gross> people:<int>`

Example:

`ruby ~/.agents/tools/tax_cyprus.rb income:100000 people:2`

Notes (short):
- Salary per person is fixed to the tax‑free band (€19,500). The remainder is paid as dividends evenly.
- Script assumes non‑dom company owners (no SDC on dividends). Employee GHS (2.65%) is applied to salary+dividends and capped/prorated; employer GHS (2.9%) and employer social charges are included.
- Corporate tax (CIT) at 15% is applied to profit after salaries and deductible employer charges; CIT is subtracted before computing the dividend pool.
- Output is a P&L-style breakdown: Revenue → Salaries → Employer charges → Profit before tax → CIT → Dividends pool → Per-owner gross/net → Total net to owners and Total costs (Gross − Net).

Currency / Australia note

- The Australian script outputs AUD. When comparing to EUR results, convert AUD → EUR using your chosen rate. In recent examples we used 1 EUR = 1.64 AUD (so EUR = AUD / 1.64).
