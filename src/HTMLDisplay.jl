import Base: show
using IOCapture

function _escape_html_text(x)
    s = String(x)
    s = replace(s, "&" => "&amp;")
    s = replace(s, "<" => "&lt;")
    s = replace(s, ">" => "&gt;")
    s = replace(s, "\"" => "&quot;")
    return replace(s, "'" => "&#39;")
end

_escape_html_attr(x) = _escape_html_text(x)

function _sanitize_html_tag(env)
    tag = lowercase(strip(String(env)))
    occursin(r"^[a-z][a-z0-9-]*$", tag) || return "strong"
    return tag
end

function _sanitize_text_align(justify)
    value = lowercase(strip(String(justify)))
    value in ("left", "right", "center", "justify", "start", "end") && return value
    return "left"
end

"""
    HTMLOut(html::String)

Lightweight wrapper for HTML content that displays in HTML-capable frontends.
"""
struct HTMLOut
    html::String
end

"""
    show(io::IO, ::MIME"text/html", x::HTMLOut)

Render stored HTML when an HTML display is available.
"""
function show(io::IO, ::MIME"text/html", x::HTMLOut)
    print(io, x.html)
end

"""
    to_html(txt; sz=20, color="darkred", justify="left", height=15, width=100, env="strong") -> String

Wrap a string in a styled HTML container.
"""
function to_html(txt; sz=20, color="darkred", justify="left",
                 height=15, width=100, env="strong")
    env_tag = _sanitize_html_tag(env)
    txt_html = _escape_html_text(txt)
    return """
    <div style="font-size: $(sz)px; color: $(_escape_html_attr(color)); text-align: $(_sanitize_text_align(justify)); height: $(height)px; width: $(width)%;">
      <$(env_tag)>$(txt_html)</$(env_tag)>
    </div>
    """
end

"""
    to_html(txt1, txt2; sz1=20, sz2=20, color="darkred", justify="left", height=15, width=100, env="strong") -> String

Wrap two strings in a styled HTML container with separate font sizes.
"""
function to_html(txt1, txt2; sz1=20, sz2=20, color="darkred",
                 justify="left", height=15, width=100, env="strong")
    env_tag = _sanitize_html_tag(env)
    txt1_html = _escape_html_text(txt1)
    txt2_html = _escape_html_text(txt2)
    return """
    <div style="color: $(_escape_html_attr(color)); text-align: $(_sanitize_text_align(justify)); min-height: $(height)px; width: $(width)%;">
      <div style="font-size: $(sz1)px;"><$(env_tag)>$(txt1_html)</$(env_tag)></div>
      <div style="font-size: $(sz2)px;"><$(env_tag)>$(txt2_html)</$(env_tag)></div>
    </div>
    """
end

"""
    show_html(txt; sz=20, color="darkred", justify="left", height=15, width=100, env="strong") -> HTMLOut

Return HTML output for a single string with styling.
"""
function show_html(txt; sz=20, color="darkred", justify="left",
                   height=15, width=100, env="strong")
    HTMLOut(to_html(txt; sz=sz, color=color, justify=justify,
                    height=height, width=width, env=env))
end

"""
    show_html(txt1, txt2; sz1=20, sz2=20, color="darkred", justify="left", height=15, width=100, env="strong") -> HTMLOut

Return HTML output for two strings with styling.
"""
function show_html(txt1, txt2; sz1=20, sz2=20, color="darkred",
                   justify="left", width=100, height=15, env="strong")
    HTMLOut(to_html(txt1, txt2; sz1=sz1, sz2=sz2, color=color,
                    justify=justify, height=height, width=width, env=env))
end

"""
    pr(txt; sz=15, color="black", justify="left", height=15, width=100, env="p") -> HTMLOut

Convenience wrapper for paragraph-style HTML output.
"""
function pr(txt; sz=15, color="black", justify="left",
            height=15, width=100, env="p")
    show_html(txt; sz=sz, color=color, justify=justify,
              height=height, width=width, env=env)
end

"""
    capture_output(f, args...) -> String

Run `f(args...)` and return the captured stdout as a string.
"""
function capture_output(f, args...)
    captured = IOCapture.capture() do
        f(args...)
    end
    return captured.output
end

"""
    show_side_by_side_html(captured_outputs, titles=nothing) -> String

Create HTML that displays captured text outputs side by side.
"""
function show_side_by_side_html(captured_outputs, titles=nothing)
    html = """
    <div style="display: flex; justify-content: space-between;">
    """

    if isnothing(titles)
        for output in captured_outputs
            html *= """
            <div style="flex: 1; align-content:flex-start; margin-right: 10px;">
            <pre>$(_escape_html_text(output))</pre>
            </div>
            """
        end
    else
        for (i, output) in enumerate(captured_outputs)
            title = titles[i]
            html *= """
            <div style="flex: 1; align-content:flex-start; margin-right: 10px;">
            <h4>$(_escape_html_text(title))</h4>
            <pre>$(_escape_html_text(output))</pre>
            </div>
            """
        end
    end

    html *= "</div>"
    return html
end

"""
    SideBySideHTML(html::String)

Wrapper for side-by-side HTML output.
"""
struct SideBySideHTML
    html::String
end

"""
    show(io::IO, ::MIME"text/html", x::SideBySideHTML)

Render side-by-side HTML when an HTML display is available.
"""
function show(io::IO, ::MIME"text/html", x::SideBySideHTML)
    print(io, x.html)
end

"""
    show_side_by_side(args...; kwargs...) -> SideBySideHTML

Build a side-by-side HTML view from captured outputs and optional titles.
"""
show_side_by_side(args...; kwargs...) =
    SideBySideHTML(show_side_by_side_html(args...; kwargs...))
