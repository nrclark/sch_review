#!/usr/bin/env python

"""
Pandoc filter to convert all regular text to uppercase.
Code, link URLs, etc. are not affected.
"""
import sys
from pandocfilters import toJSONFilter, Table, Plain, RawInline

def stdout_to_stderr(func):
    """Connects STDOUT to STDERR for the duration of a
    function, and then reconnects STDOUT to its original
    source."""
    def inner(*args, **kwargs):
        old_stdout = sys.stdout
        sys.stdout = sys.stderr
        result = func(*args, **kwargs)
        sys.stdout = old_stdout
        return result
    return inner

@stdout_to_stderr
def minipage_tables(key, value, format, meta):
    if key == 'Table':
        output=[]
        output.append(Plain([RawInline('tex', '\\begin{minipage}{\\textwidth}')]))
        output.append(Table(*value))        
        output.append(Plain([RawInline('tex', '\\end{minipage}')]))
        return output

if __name__ == "__main__":
    toJSONFilter(minipage_tables)
