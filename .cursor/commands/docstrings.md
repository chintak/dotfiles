Add Google style documentation for Python classes and functions, follow these steps:

1. **Function and Method Docstrings**
   - Place the docstring directly below the function definition.
   - Start with a concise summary of what the function does.
   - List all parameters in a `Args:` section, providing type annotations and descriptions.
   - Describe the return value in a `Returns:` section, specifying the type and meaning.
   - Include a `Raises:` section if the function can raise exceptions.
   - Optionally, add usage examples in an `Example:` section.

   **Example:**
   ```python
   def add_numbers(a: int, b: int) -> int:
       """Add two integers.

       Args:
           a (int): The first integer to add.
           b (int): The second integer to add.

       Returns:
           int: The sum of `a` and `b`.

       Example:
           >>> add_numbers(2, 3)
           5
       """
       return a + b
   ```

2. **Class Docstrings**
   - Place the docstring directly below the class definition.
   - Summarize the class's purpose and functionality.
   - Document the constructor's parameters in an `Args:` section if the `__init__` method is public.
   - Optionally, describe class attributes in an `Attributes:` section.
   - Include usage examples in an `Example:` section if helpful.

   **Example:**
   ```python
   class ExampleCounter:
       """Counts occurrences of integers in a stream.

       Args:
           start (int): The initial count value.

       Attributes:
           count (int): Current count.

       Example:
           >>> counter = ExampleCounter(start=0)
           >>> counter.increment()
           >>> counter.count
           1
       """

       def __init__(self, start: int = 0) -> None:
           self.count = start

       def increment(self) -> None:
           """Increment the count by one."""
           self.count += 1
   ```

3. **Best Practices**
   - Keep docstrings up to date when changing function signatures or class attributes.
   - Be concise but clear—describe what the code does, not how it works internally.
   - Document all public methods, class attributes, and modules for comprehensive coverage.
