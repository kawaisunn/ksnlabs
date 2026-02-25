# ENGRAM COMPACT ENCODING SPEC v1.1
# For AI sessions. Not human-readable by design.
# Tokens are the currency. Every character must earn its place.
# v1.1: added concurrency codes for multi-session support.

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
# cc = concurrency

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
# AV = active (session still running)

# ---- BOOT PROTOCOL CODES ----
# a = auto
# m = manual
# n = none
# n>m = none then manual

# ---- CONCURRENCY CODES (v1.0) ----
# @owner = sessionId that last wrote this project buffer
# @dep = dependency on another project (format: projectName:detail)
# @shared = learnings/workflows contributed to shared pool this session
# Lock status: alive, stale(>4h no checkpoint), dead(confirmed by successor)
# Project claim: exclusive write per project. Check .ai/active/ before claiming.
# Session ID format: {model}_{interface}_{project}_{seq}
# See .ai/CONCURRENCY.md for full multi-session protocol.

# ---- LEARNING FORMAT ----
# ID:category:!severity:origin
# title line
# detail line(s)

# ---- REGISTRY FORMAT ----
# sessionId|date|model|interface|machine|boot:X|handoff:y/n|OUTCOME
# focus:description
# +learnings,+workflows
# note:text

# ---- BUFFER FORMAT (global legacy) ----
# @section value
# sections: now,why,left,next,urg,blk,tkn,net

# ---- PROJECT BUFFER FORMAT (concurrent) ----
# @section value
# required: @now @left @next @blk @owner
# optional: @dep @shared @tkn
# session log: %id|date|OUTCOME (scoped to project)

# ---- LOCK FORMAT (.ai/active/{sessionId}.lock) ----
# id:{sessionId}
# model:{model}
# interface:{interface}
# machine:{machine}
# project:{project}
# signed_in:{ISO8601}
# last_checkpoint:{ISO8601}
# status:alive
# focus:{one-line current work}

# ---- ARCHIVE FORMAT ----
# ANN|retiredBy|date|originalSession
# topic:tag;tag;tag
# project:name
# facts as lines

# ---- WORKFLOW COMPACT FORMAT ----
# WNN:title
# steps as > separated sequence
# *antipattern or note
