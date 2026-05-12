package com.trendx.app

import android.app.Application

// Minimal application subclass — declared in the manifest so Android wires
// it up. Reserved for global init (analytics, crash reporting, image loader
// config) when those land in subsequent passes.
class TrendXApplication : Application()
