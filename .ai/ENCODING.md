# ENGRAM COMPACT ENCODING SPEC v1.0
# For AI sessions. Not human-readable by design.
# Tokens are the currency. Every character must earn its place.

# ---- CONVENTIONS ----
# | = field separator
# : = key-value separator  
# ; = list separator
# > = sequence/flow
# + = added/created
# - = removed/retired
# ! = severity (!c=critical !h=high !m=medium !l=low)
# @ = section marker in buffer
# ~ = approximate/estimate
# * = note/caveat
# LNN = learning ID
# WNN = workflow ID
# ANN = archive ID
# Lines starting with # are comments (0 cost at read time, skip them)

# ---- CATEGORIES (2-char codes) ----
# si = session-integrity
# to = tooling
# or = orientation
# gt = git
# bd = build
# pj = project
# nw = network
# ed = engram-design
# hc = human-ai-collaboration

# ---- CONFIDENCE CODES ----
# c = confirmed
# cf = confirmed-by-failure
# cl = confirmed-by-loss
# p = proposed
# e = experiential
# pm = pattern-confirmed-across-models

# ---- OUTCOME CODES ----
# OK = success
# PT = partial
# FL = failed
# PH = phantom
# ST = stalled
# FN = failed-no-handoff

# ---- BOOT PROTOCOL CODES ----
# a = auto
# m = manual
# n = none
# n>m = none then manual

# ---- LEARNING FORMAT ----
# ID:category:!severity:origin
# title line
# detail line(s)

# ---- REGISTRY FORMAT ----
# sessionId|date|model|interface|machine|boot:X|handoff:y/n|OUTCOME
# focus:description
# +learnings,+workflows
# note:text

# ---- BUFFER FORMAT ----
# @section value
# sections: now,why,left,next,urg,blk,tkn,net

# ---- ARCHIVE FORMAT ----
# ANN|retiredBy|date|originalSession
# topic:tag;tag;tag
# project:name
# facts as lines

# ---- WORKFLOW COMPACT FORMAT ----
# WNN:title
# steps as > separated sequence
# *antipattern or note
