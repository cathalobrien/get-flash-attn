#!/usr/bin/awk -f

# Skip lines not ending with .whl
!/whl$/ { next }

{
    f = $0

    # Extract flash version
    match(f, /flash_attn-([0-9.]+(\.post[0-9]+)?)/, m1)
    flash = m1[1]

    # Extract torch version
    match(f, /torch([0-9.]+)/, m2)
    torch = m2[1]

    # Extract python version
    match(f, /cp([0-9]{3})-cp[0-9]{3}/, m3)
    py = substr(m3[1],1,1)"."substr(m3[1],2,1)
    # Extract python version
    match(f, /cp([0-9]{2,3})-cp[0-9]{2,3}/, m3)
    pynum = m3[1]
    if (length(pynum) == 2) {
      py = substr(pynum,1,1)"."substr(pynum,2,1)   # cp39 -> 3.9
    } else if (length(pynum) == 3) {
      py = substr(pynum,1,1)"."substr(pynum,2,2)   # cp311 -> 3.11
    } else {
      py = pynum
    }

    # Extract ISA/platform
    match(f, /-(linux_[a-z0-9_]+)\.whl$/, m4)
    isa = m4[1]

    # Store availability
    table[py,isa,flash,torch] = 1

    # Keep track of unique values
    flashes[flash]; torches[torch]; pythons[py]; isas[isa]
}

END {
    # Sort unique values
    n = asorti(flashes, flash_list)
    m = asorti(torches, torch_list)
    o = asorti(pythons, py_list)
    p = asorti(isas, isa_list)

    for (pi=1; pi<=o; pi++) {
        py = py_list[pi]
        for (ii=1; ii<=p; ii++) {
            isa = isa_list[ii]
            print "Python " py " - " isa ":"
            printf "Flash\\Torch     "
            for (tj=1; tj<=m; tj++) printf "%6s", torch_list[tj]
            print "\n-----------------------------------"
            for (fj=1; fj<=n; fj++) {
                flash = flash_list[fj]
                printf "%-15s", flash
                for (tj=1; tj<=m; tj++) {
                    torch = torch_list[tj]
                    printf "%6d", ((py,isa,flash,torch) in table ? 1 : 0)
                }
                print ""
            }
            print ""
        }
    }
}

