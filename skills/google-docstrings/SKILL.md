---
name: google-docstrings
description: >-
  Add or update Google-style docstrings for Python modules, classes, and
  functions. Use when the user asks to "add docstrings", "document this
  function/class", or requests Google-style Python documentation.
---

# Google-Style Python Docstrings

## Summary line

- One line, imperative mood, ends with a period: `"""Return the user's display name."""`.
- Don't restate the function name as the summary — `"""Fetch user."""` for `fetch_user` is empty.
- One-line docstrings are sufficient for self-evident methods. Use a blank line + paragraph for additional detail.
- Public APIs always get a docstring. Skip trivial private helpers and obvious dunder methods.

## Functions and methods

Use these sections, in order, only when applicable:

- `Args:` — one entry per parameter. Skip `self`/`cls`. **Do not repeat types** when the signature is already annotated; the type belongs in the signature, the description in the docstring.
- `Returns:` — what is returned. Omit when the function returns `None`.
- `Yields:` — for generators, in place of `Returns:`.
- `Raises:` — exception type and the condition that triggers it. Only document exceptions the caller is expected to handle.
- `Example:` — only when correct usage isn't obvious from the signature.

```python
def fetch_user(user_id: int, *, include_archived: bool = False) -> User | None:
    """Fetch a user by primary key.

    Args:
        user_id: The user's primary key.
        include_archived: If True, also return soft-deleted users.

    Returns:
        The matching user, or None if no user exists with that ID.

    Raises:
        DatabaseError: If the connection to the user store fails.
    """
```

One-liners for trivial methods:

```python
def increment(self) -> None:
    """Increment the count by one."""
```

## Classes

- Summarize the class's purpose on the first line.
- Document constructor parameters under `Args:` in the **class** docstring. Do not also write an `__init__` docstring — pick one place.
- Use `Attributes:` for public attributes that aren't obvious from the constructor signature.

```python
class RateLimiter:
    """Token-bucket rate limiter.

    Args:
        capacity: Maximum tokens the bucket holds.
        refill_per_second: Tokens added per second, up to `capacity`.

    Attributes:
        tokens: Currently available tokens.
    """

    def __init__(self, capacity: int, refill_per_second: float) -> None:
        self.tokens = capacity
        ...
```

## Modules

Place a docstring as the first statement in the file, above imports.

```python
"""Rate limiting primitives for the API gateway."""
```

Extend with a paragraph and an optional `Typical usage example:` block when the module's role isn't obvious from its name.

## Maintenance

- Update the docstring in the same edit that changes the signature, attributes, or raised exceptions. A stale docstring is worse than no docstring.
- Describe *what* and *why*, not *how* — implementation details belong in the code.
- Don't add a docstring just to satisfy a linter. Empty restatements ("Get the value." on `get_value()`) are noise.
