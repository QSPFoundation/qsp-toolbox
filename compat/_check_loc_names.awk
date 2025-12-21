NR==FNR {
    # Reading keywords file - store each keyword in lowercase
    keywords[tolower($0)] = 1
    next
}

/^#/ {
    # Extract text after the # symbol
    line = substr($0, 2)

    # Trim leading and trailing whitespace
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

    # Check if trimmed line exists in keywords (case-insensitive)
    if (tolower(line) in keywords) {
        print line
    }
}
