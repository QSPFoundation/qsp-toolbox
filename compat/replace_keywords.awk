BEGIN {
    # Define renaming template (default: _@@)
    if (template == "") template = "_{}"

    # load exclusions first (if provided)
    if (exfile != "") {
        while ((getline ex < exfile) > 0) {
            if (ex != "") exclude[tolower(ex)] = 1
        }
        close(exfile)
    }
    # load keywords, skipping any that are in the exclusion list
    while ((getline k < kwfile) > 0) {
        k_lower = tolower(k)
        if (k != "" && !(k_lower in exclude)) {
            kw[k_lower] = 1
        }
    }
    close(kwfile)

    # delimiter characters
    delim = " \t&'\"()[]=!<>+-/*:,{}\r\n"
    # build safe regex class R
    R = "["
    for (i = 1; i <= length(delim); i++) {
        c = substr(delim,i,1)
        # escape regex metacharacters
        if (c ~ /[\[\](){}.^$*+?|\\-]/) R = R "\\" c
        else R = R c
    }
    R = R "]"
}

function apply_template(tok) {
    result = template
    gsub(/\{\}/, tok, result)
    return result
}

{
    out = ""; token = ""
    for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c ~ R) {
            out = out ((tolower(token) in kw) ? apply_template(token) : token) c
            token = ""
        } else {
            token = token c
        }
    }
    out = out ((tolower(token) in kw) ? apply_template(token) : token)
    print out
}
