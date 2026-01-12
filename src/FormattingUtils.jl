using LaTeXStrings: LaTeXString

"""
    strip_math_delims(s::AbstractString) -> String

Strip outer dollar delimiters and surrounding whitespace from a LaTeX fragment.
"""
function strip_math_delims(s::AbstractString)
    return strip(String(s), ['$', '\n', ' '])
end

"""
    looks_like_math(s::AbstractString) -> Bool

Return true when a plain string should be treated as math output.
"""
function looks_like_math(s::AbstractString)
    stripped = strip(String(s))
    isempty(stripped) && return false
    startswith(stripped, "\\") && return true
    return all(c -> isdigit(c) || c in (' ', '=', '+', '-', '*', '/', '(', ')', '^', '.', ','), stripped)
end

"""
    sanitize_text(s::AbstractString) -> String

Escape text content for `\\text{...}` LaTeX output.
"""
function sanitize_text(s::AbstractString)
    return replace(String(s), "_" => "\\_", "\$" => "\\\$")
end

"""
    normalize_symbolics_latex(s::AbstractString) -> String

Clean Symbolics-generated LaTeX for consistent math rendering.
"""
function normalize_symbolics_latex(s::AbstractString)
    cleaned = strip(String(s))
    cleaned = replace(cleaned, r"^\\begin\{equation\}\s*" => "", r"\s*\\end\{equation\}\s*$" => "")
    cleaned = replace(cleaned, r"\\mathtt\{([^}]*)\}" => s"\1")
    cleaned = replace(cleaned, "\\_" => "_")
    return strip_math_delims(cleaned)
end

"""
    normalize_separator(separator) -> String

Return a LaTeX-safe separator string, removing outer math delimiters when needed.
"""
function normalize_separator(separator)
    if separator isa LaTeXString
        return to_latex(separator)
    end
    return strip_math_delims(string(separator))
end
