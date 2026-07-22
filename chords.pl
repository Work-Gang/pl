# plugins/chords.pl — the chord/macro panel. Discovered by module.pl's
# loader exactly like build.pl (find plugins -maxdepth 1 -name '*.pl' |
# sort), which is why this file lives under plugins/ and NOT under
# corpus/pl/: it never enters the suite-VM sweep (suite_vm.sh's file list
# is corpus/pl-driven) and it must not — chord vocabularies are a host
# customization, not board firmware source of truth.
#
# Chords are RELATIONS, not a data table. A chord is a timing relation
# over a SET of key-notes, styled directly on corpus/pl/mode2_surge.pl's
# hold_ms precedent (hold_ms < 800 vs hold_ms >= 800 tells short press
# from hard hold on ONE key) generalized to a set:
#
#   [chord: <symbol>, notes=[<note>, <note>, ...],
#           window_ms=<simultaneity tolerance>,
#           release_ms=<tail after last release>,
#           encoding=<word|phoneme|tone_resonance|other>]
#     : ["<description>"]
#
#   - window_ms: every member note's press must land within window_ms of
#     the EARLIEST member press for the set to count as simultaneous
#     (default 40ms — pl/src/chord.rs's DEFAULT_WINDOW_MS.).
#   - release_ms: once the LAST held member releases, the chord stays
#     "active" (its dispatch still counted as in effect — e.g. a sustained
#     macro/tone) for release_ms more before closing (default 250ms —
#     DEFAULT_RELEASE_MS), the same "tail" framing hold_ms gives a single
#     hard-hold key.
#
# A chord's symbol is ALSO its tablet.pl lookup key — see pl/tablet.pl for
# the binding-file format spec. This file's relations describe WHAT was
# pressed (which notes, how tight the timing); a tablet.pl describes WHAT
# HAPPENS (which procedure, what light) — the same chord vocabulary can be
# bound differently by different tablet.pl files (see
# our_board_build/build/tablet_samples/{words,phonemes,tones}/tablet.pl,
# generated from the OG firmware preset colors).
#
# Per-key visuals are NEVER swallowed by chord recognition: pl/src/
# chord.rs's ChordMatcher::ingest() computes a per_key light outcome for
# EVERY physical key event first, chord member or not, and reports it
# alongside (never instead of) any chord dispatch on the same event — see
# MatchEvent's two independent fields.
#
# LEXER CARE: no bare `dir/` + `*.ext` glob written adjacent in this
# file's own (proc {code}) block below, and no escaped double quotes
# anywhere in it — the same two lexer traps every other plugins/*.pl file
# in this repo already dodges.

[module: chords, panel='chords'] : [
    "Declares the chords panel: self-checks this file and pl/tablet.pl
     with pl_parse --check, counts this file's own [chord: ...] relations
     by encoding, and reports the Sharkoon per-key lighting honest-degrade
     state (SEMITEK 1ea7:0907 if#1 vendor protocol uncaptured — see
     docs/SHARKOON_LIGHTING_CAPTURE.md)."
]

[module: chords, case=chords_are_relations_not_a_table] : [
    "A chord is a [chord: symbol, notes=[...], window_ms=, release_ms=,
     encoding=] : [\"...\"] relation, parsed by the exact same
     crate::lexer::Lexer / crate::parser::Parser this repo already uses
     for every other .pl file (pl/src/chord.rs's parse_chords(), mirroring
     embed.rs's strict_ok() pattern) — never a bespoke data table or a
     second file format. Multiple chords.pl-style files may coexist; this
     plugin is the one module.pl's own composer discovers by default."
]

[module: chords, case=per_key_light_always_fires] : [
    "Every physical keypress produces its own per-key light outcome
     (pl/src/chord.rs's apply_per_key_light(), called unconditionally at
     the top of ChordMatcher::ingest()) independent of whether that press
     also happens to complete a chord match. A chord being recognized on
     the SAME event never replaces or cancels the per-key visual that
     event already earned on its own — MatchEvent carries both fields, and
     chord.rs's own test
     every_press_fires_its_own_per_key_light_even_when_chord_matches
     asserts exactly this."
]

[module: chords, case=tone_resonance_derives_bounded_overtones] : [
    "encoding=tone_resonance is the 'complex self-interacting instrument'
     embedding: pressing two physical notes together derives NEW synthetic
     notes neither key alone produces — pl/src/chord.rs's
     derive_overtones() computes each pair's summation tone (a+b) and
     difference tone (|a-b|), recursively re-paired against the ORIGINAL
     physical notes only (never against other derived tones, which is
     what keeps this from combinatorial blowup) up to MAX_OVERTONE_DEPTH=3
     hops and MAX_DERIVED_NOTES=16 total, deterministic and deduplicated.
     Other encodings (word, phoneme, other) never trigger this — the
     matcher stays encoding-agnostic except for this one branch."
]

[module: chords, case=plugin_not_corpus] : [
    "This file is discovered by module.pl's pl_module_discover() exactly
     like plugins/build.pl — find plugins -maxdepth 1 -name '*.pl' | sort
     — and is therefore never a member of corpus/pl/, never counted in
     corpus.fp, and never swept by switch/pl/suite_vm.pl. Chord vocabulary
     is host/operator customization, the same reasoning that already keeps
     every other plugins/*.pl file out of corpus/."
]

# ── Demo chords: one per selectable encoding ────────────────────────────────
# Notes are Sharkoon key-scan-index-shaped small integers for word/phoneme/
# other (arbitrary board-local key ids), and MIDI-note-shaped integers for
# tone_resonance (so derive_overtones' summation/difference math lands in
# NOTE_RANGE 0..=127 the way a real instrument mapping would).

[chord: word_hello, notes=[10, 11], window_ms=40, release_ms=250, encoding=word] : [
    "Demo word encoding: keys 10+11 pressed within 40ms spell the macro
     'hello' — see our_board_build/build/tablet_samples/words/tablet.pl
     for a preset-color-derived proc binding of this same symbol."
]

[chord: phon_th, notes=[20, 21], window_ms=30, release_ms=150, encoding=phoneme] : [
    "Demo phoneme encoding: keys 20+21 pressed within 30ms spell the /th/
     phoneme for a speech-synthesis-style dispatch — see
     our_board_build/build/tablet_samples/phonemes/tablet.pl."
]

[chord: tone_fifth, notes=[60, 67], window_ms=25, release_ms=100, encoding=tone_resonance] : [
    "Demo tone_resonance encoding: MIDI notes 60 (middle C) and 67 (G, a
     perfect fifth above) pressed within 25ms derive synthetic overtones
     (summation tone 127, difference tone 7) neither key alone produces —
     see our_board_build/build/tablet_samples/tones/tablet.pl."
]

[chord: layer_shift, notes=[30, 31, 32], window_ms=50, release_ms=50, encoding=other] : [
    "Demo other encoding: a three-key chord for a use tablet.pl's
     encoding= field names as something other than word/phoneme/
     tone_resonance — e.g. a modifier-layer shift with no speech or
     musical meaning at all, proving encoding= is an open vocabulary, not
     a closed enum at the .pl level (pl/src/chord.rs's
     Encoding::Other(String) is the Rust side of that same openness)."
]

(proc {
panel_chords() {
    ENGINE_DIR_LOCAL="${ENGINE_DIR:-$(pwd)}"
    PL="${PL:-${ENGINE_DIR_LOCAL}/target/release/pl_parse}"
    THIS_FILE="${ENGINE_DIR_LOCAL}/plugins/chords.pl"
    TABLET_SPEC="${ENGINE_DIR_LOCAL}/tablet.pl"

    if [ ! -x "${PL}" ]; then
        echo "  pl_parse binary not built (cargo build --release --bin pl_parse) — no self-check attempted"
        echo "[panel chords] status=pass"
        return 0
    fi
    echo "  pl_parse: ${PL}"

    PANEL_FAILED=0
    FAIL_REASON=""
    note_fail() {
        PANEL_FAILED=1
        if [ -z "${FAIL_REASON}" ]; then
            FAIL_REASON="$1"
        fi
    }

    if [ -f "${THIS_FILE}" ]; then
        if "${PL}" --file "${THIS_FILE}" --check >/dev/null 2>&1; then
            echo "  chords.pl: pl_parse --check clean"
        else
            echo "  chords.pl: pl_parse --check FAILED"
            note_fail "chords_pl_check_failed"
        fi
        CHORD_COUNT="$(grep -c '^\[chord:' "${THIS_FILE}" 2>/dev/null || echo 0)"
        echo "  chords.pl: ${CHORD_COUNT} [chord: ...] relation(s) declared"
    else
        echo "  ${THIS_FILE} not found"
        note_fail "chords_pl_missing"
    fi

    if [ -f "${TABLET_SPEC}" ]; then
        if "${PL}" --file "${TABLET_SPEC}" --check >/dev/null 2>&1; then
            echo "  tablet.pl: pl_parse --check clean"
        else
            echo "  tablet.pl: pl_parse --check FAILED"
            note_fail "tablet_pl_check_failed"
        fi
    else
        echo "  ${TABLET_SPEC} not found"
        note_fail "tablet_pl_missing"
    fi

    # Honest degrade: SEMITEK 1ea7:0907 if#1's vendor lighting OUT
    # endpoint (Ad=04(O), MaxPacketSize=64) has never been captured — see
    # pl/switch/pl/sharkoon_keyboard.pl and docs/SHARKOON_LIGHTING_
    # CAPTURE.md's checklist to lift this. This is an environment fact,
    # not this panel's own failure — status=pass still follows, the same
    # discipline plugins/camera.pl's case=binary_not_built_is_an_honest_
    # degrade already applies.
    echo "  per-key lighting: unavailable (semitek_vendor_protocol_uncaptured) — see docs/SHARKOON_LIGHTING_CAPTURE.md"

    if [ "${PANEL_FAILED}" = "1" ]; then
        echo "[panel chords] status=fail reason=${FAIL_REASON}"
        return 1
    fi

    echo "[panel chords] status=pass"
    return 0
}
} [] 'define_chords_panel') : [
    "The one proc this file carries: locate pl_parse (honest degrade if
     unbuilt), self-check both chords.pl and tablet.pl with pl_parse
     --check, count this file's own [chord: ...] relations, and report the
     Sharkoon per-key lighting honest-degrade line — a missing binary or a
     missing tablet.pl is a real failure (note_fail), an uncaptured vendor
     lighting protocol is not."
]
