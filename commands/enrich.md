---
description: Enrich CRM data
---

Enrich a local CRM with new data. You will need to use judgement to extract information from unstructured text/html and align it with CRM fields.

Task: Enrich $@

1. Get the current CRM state for the query - use a minimal substring filter like `http://localhost:3000/api/organisations?name=$1`
2. Identify missing information
3. Search local scrapes & the web for the missing info
4. Update the CRM as required

### Resources

`~/Downloads/crm-scrapes` contains various website site content from Linkedin and job sites. Grep the dir for your key word - this should be the first place to check for info.

Use web fetch / search for anything that hasn't been scraped.  3-4 searches max.

The CRM can be accessed via cURL at `http://localhost:3000/api/` and is self documenting
