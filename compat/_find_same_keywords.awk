# Input variables:
#   simple   : print only keywords that have total 2+ occurrences (one per line)

BEGIN {
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

    # prefix order for consistent printing
    pref_order[1] = ""
    pref_order[2] = "$"
    pref_order[3] = "#"
    pref_order[4] = "%"
    pref_count = 4

    label[""] = "Plain references"
    label["$"] = "$ references"
    label["#"] = "# references"
    label["%"] = "% references"
}

{
    # store original line for context printing (strip CR)
    gsub(/\r/, "", $0)
    lines[NR] = $0

    # tokenize: pad so delimiters at ends are handled
    line = " " $0 " "
    L = length(line)
    pos = 1

    while (pos <= L) {
        # skip delimiters
        while (pos <= L && substr(line, pos, 1) ~ R) pos++
        if (pos > L) break

        # optional prefix
        prefix = ""
        c = substr(line, pos, 1)
        if (c == "$" || c == "#" || c == "%") {
            prefix = c
            pos++
        }

        kw_start = pos
        while (pos <= L && !(substr(line, pos, 1) ~ R)) pos++
        if (pos > kw_start) {
            kw = substr(line, kw_start, pos - kw_start)
            if (kw != "") {
                base = tolower(kw)

                # per-line + per-prefix dedupe
                key = prefix SUBSEP base SUBSEP NR
                if (!(key in seen_line)) {
                    seen_line[key] = 1
                    count[prefix, base]++
                    n = count[prefix, base]
                    list[prefix, base, n] = NR
                }

                # track bases for final scanning (preserve insertion order)
                if (!(base in seen_base)) {
                    seen_base[base] = 1
                    base_index_count++
                    base_index[base_index_count] = base
                }
            }
        }
    }
}

END {
    if (base_index_count == 0) {
        # default behavior: informative message; simple mode: no output
        if (!simple) printf "No keywords found in any variant (plain, $, #, %%) in file: %s\n", FILENAME
        exit
    }

    if (base_index_count > 1) asort(base_index)

    found_count = 0
    for (bi = 1; bi <= base_index_count; bi++) {
        b = base_index[bi]

        # determine which prefixes have occurrences for this base
        present = 0
        delete present_pref
        for (pi = 1; pi <= pref_count; pi++) {
            p = pref_order[pi]
            pn = (count[p, b] + 0)
            if (pn > 0) {
                present++
                present_pref[p] = pn
            }
        }

        # only print bases that appear in at least two different variants
        if (present >= 2) {
            found_count++

            if (simple) {
                print b
            } else {
                # Build list of which variants are present
                variant_list = ""
                for (pi = 1; pi <= pref_count; pi++) {
                    p = pref_order[pi]
                    if (p in present_pref) {
                        if (variant_list != "") variant_list = variant_list ", "
                        if (p == "") variant_list = variant_list "plain"
                        else variant_list = variant_list p
                    }
                }

                printf "Found keyword '%s' in %d variants (%s):\n\n", b, present, variant_list

                for (pi = 1; pi <= pref_count; pi++) {
                    p = pref_order[pi]
                    pn = (present_pref[p] + 0)
                    if (pn > 0) {
                        printf "%s:\n", label[p]

                        # collect & sort line numbers for this prefix/base, dedup done earlier
                        delete tmp
                        for (i = 1; i <= pn; i++) tmp[i] = list[p, b, i] + 0
                        if (pn > 1) asort(tmp)
                        for (i = 1; i <= pn; i++) {
                            ln = tmp[i]
                            start = ln - 2; if (start < 1) start = 1
                            end   = ln + 2; if (end > NR) end = NR
                            for (j = start; j <= end; j++) {
                                if (j == ln)
                                    printf "%4d:> %s\n", j, lines[j]
                                else
                                    printf "%4d:  %s\n", j, lines[j]
                            }
                            print ""
                        }
                    }
                }

                print ""
            }
        }
    }

    if (!simple) {
        if (found_count == 0) {
            printf "No keywords found in 2+ variants (plain, $, #, %%) in file: %s\n", FILENAME
        } else {
            printf "Found %d keywords in 2+ variants in file: %s\n", found_count, FILENAME
        }
    }
}
