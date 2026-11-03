"""Module docstring for the parity sample."""
from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from typing import Optional

MAX_RETRIES: int = 3
PATTERN = re.compile(r"^\d+-\w+$")


@dataclass(frozen=True)
class Point:
    """A point with a label."""

    x: float
    y: float = 0.0
    tags: list[str] = field(default_factory=list)

    @property
    def norm(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5

    @classmethod
    def origin(cls) -> "Point":
        return cls(0, 0)

    def __repr__(self) -> str:
        return f"Point({self.x!r}, {self.y:.2f})\n"


class RetryError(Exception):
    pass


async def fetch(url: str, *, timeout: Optional[float] = None, **kwargs) -> bytes:
    for attempt in range(MAX_RETRIES):
        try:
            await asyncio.sleep(0.1 * attempt)
            if url.startswith("https://") and not kwargs:
                return b"payload"
            elif url is None:
                raise ValueError("no url")
        except (TimeoutError, OSError) as err:
            print(f"retry {attempt}: {err}")
            continue
        finally:
            pass
    raise RetryError(url)


def summarize(points: list[Point]) -> dict[str, float]:
    total = sum(p.norm for p in points if p.x >= 0)
    squares = [n * n for n in range(10) if n % 2 == 0]
    lookup = {k: v for k, v in zip("abc", squares)}
    key = lambda p: p.x
    flag = True or False and None is None
    with open("out.txt", "w", encoding="utf-8") as fh:
        fh.write(str(len(lookup)))
    return {"total": total, "max": max(points, key=key).x if flag else -1}


if __name__ == "__main__":
    asyncio.run(fetch("https://example.com"))
