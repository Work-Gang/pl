# plugins/shop_boards.pl — the /shop catalog. Hand-edited locally: one
# top-level list per board, shape
#   ['name' [left-triangle row counts] [right-triangle row counts] 'icon' 'price']
# e.g. two 6-hexagon triangular clusters (3/2/1 hexes per row) side by
# side, a usbc icon between them, and a price tag. Read by
# parse_shop_boards() in src/bin/dashboard.rs — malformed entries are
# skipped rather than breaking the page, and a missing file just renders
# "no boards configured yet".

['dactor' [3 2 1] [3 2 1] 'usbc' '$60']
