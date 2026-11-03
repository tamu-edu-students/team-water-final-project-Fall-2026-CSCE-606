# 0005: Shopping list pop-up driven by the URL

**Status:** Accepted

## Context

The shopping list opens as a pop-up from the inventory page (US-06). A typical
pop-up is opened by JavaScript, which conflicts with ADR 0001, and it would close
after every form submission because the page reloads.

## Decision

In the context of the shopping list, facing the no-JavaScript requirement, we
decided to open the pop-up from a `cart=open` URL parameter: the server renders
an open `<dialog>` when the parameter is present, and every shopping action
redirects back to that URL.

## Consequences

- The pop-up works without JavaScript and stays open after adding, buying, or
  removing items.
- Validation errors render inside the pop-up with a 422 response.
- The Escape key does not close the pop-up; the close button and backdrop link
  are used instead.
